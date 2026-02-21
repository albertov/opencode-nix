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

        environment.systemPackages = [ pkgs.python3 ];

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

    print("network-policy: PASS")
  '';
}
