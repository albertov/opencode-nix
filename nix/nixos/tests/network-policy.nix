{ pkgs, ... }:
let
  healthcheckScript = pkgs.writeText "healthcheck-network-policy.py" ''
    import json
    import urllib.request

    def fetch(url):
        with urllib.request.urlopen(url) as response:
            return json.loads(response.read().decode())

    health = fetch("http://127.0.0.1:8787/global/health")
    assert health.get("healthy") is True, "health failed: {}".format(health)
    print("[PASS] healthy version={}".format(health.get("version", "?")))
  '';
in
pkgs.testers.nixosTest {
  name = "opencode-network-policy";
  nodes = {
    machine =
      { pkgs, ... }:
      {
        imports = [ (import ../module.nix) ];

        system.stateVersion = "24.11";

        environment.systemPackages = [
          pkgs.curl
          pkgs.python3
        ];

        # nftables required for networkIsolation
        networking.nftables.enable = true;
        networking.firewall.enable = false;
        users.users.opencode-isolated.uid = 975;

        services.opencode = {
          enable = true;
          defaults.directory = "/var/lib/opencode/default-directory";
          instances.isolated = {
            directory = "/srv/isolated";
            listen.port = 8787;
            networkIsolation = {
              enable = true;
              outboundAllowCidrs = [ "10.0.0.0/8" ]; # internal only
            };
          };
        };
        system.activationScripts.testDirs = "mkdir -p /srv/isolated";
      };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("nftables.service")

    # nftables table is active
    machine.succeed("nft list table inet opencode-egress")

    # Allowed range: 10.0.0.1 should be reachable (ping may fail if no route, but connection attempt is not blocked by nftables)
    # We test the rule exists and has correct structure
    output = machine.succeed("nft list table inet opencode-egress")
    assert "opencode-isolated-blocked" in output, f"Expected log prefix in nftables output: {output}"
    assert "10.0.0.0/8" in output, f"Expected CIDR in nftables output: {output}"

    # Setup service completed (fail-safe check passed = nftables was active)
    machine.wait_for_unit("opencode-isolated-setup.service")
    machine.wait_for_unit("opencode-isolated.service")
    machine.wait_for_open_port(8787)
    machine.succeed("python3 ${healthcheckScript}")

    # == Behavioral traffic probes ==

    # Start a local HTTP listener so we have a concrete target
    machine.execute("python3 -m http.server 19999 &>/tmp/httpd.log &")
    machine.sleep(1)

    # ALLOWED: connection from the service user to an IP inside 10.0.0.0/8
    # 10.0.2.15 is this QEMU VM's own IP - inside the allowed CIDR.
    # curl exits: 0 (200 OK), 22 (non-2xx), or 7 (connection refused) all mean
    # the packet got through nftables. Exit 28 (timeout) would mean it was dropped.
    machine.succeed("sudo -u opencode-isolated curl --max-time 5 --silent http://10.0.2.15:19999/; code=$?; [ $code -ne 28 ]")

    # BLOCKED: connection to external IP (outside 10.0.0.0/8) - must be dropped
    # nftables DROP -> curl times out -> exits non-zero -> machine.fail assertion holds
    machine.fail("sudo -u opencode-isolated curl --max-time 3 --silent http://1.1.1.1:19999/")

    # OBSERVABILITY: after the blocked probe, kernel log must contain the log prefix
    machine.wait_until_succeeds(
      "journalctl -k | grep -q 'opencode-isolated-blocked'",
      timeout=10
    )
    print("network-policy: behavioral probes PASS")
  '';
}
