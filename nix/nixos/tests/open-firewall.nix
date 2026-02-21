{ pkgs, ... }:
let
  healthcheckScript = pkgs.writeText "healthcheck-open-firewall.py" ''
    import json
    import urllib.request
    import sys

    def fetch(url):
        with urllib.request.urlopen(url, timeout=10) as response:
            return json.loads(response.read().decode())

    health = fetch(sys.argv[1])
    assert health.get("healthy") is True, "health failed: {}".format(health)
    print("[PASS] healthy version={}".format(health.get("version", "?")))
  '';
in
pkgs.testers.nixosTest {
  name = "opencode-open-firewall";
  nodes = {
    server =
      { pkgs, ... }:
      {
        imports = [ (import ../module.nix) ];
        system.stateVersion = "24.11";
        environment.systemPackages = [ pkgs.python3 ];

        # Firewall enabled (the default on NixOS, but be explicit)
        networking.firewall.enable = true;

        users.users.opencode-exposed.uid = 974;

        services.opencode = {
          enable = true;
          defaults.directory = "/var/lib/opencode/default-directory";
          instances.exposed = {
            directory = "/srv/exposed";
            listen = {
              address = "0.0.0.0";
              port = 8787;
            };
            openFirewall = true;
          };
        };
        system.activationScripts.testDirs = "mkdir -p /srv/exposed";
      };

    client =
      { pkgs, ... }:
      {
        system.stateVersion = "24.11";
        environment.systemPackages = [
          pkgs.curl
          pkgs.python3
        ];
      };
  };

  testScript = ''
    start_all()
    server.wait_for_unit("multi-user.target")
    server.wait_for_unit("opencode-exposed-setup.service")
    server.wait_for_unit("opencode-exposed.service")
    server.wait_for_open_port(8787)

    # Verify locally first
    server.succeed("python3 ${healthcheckScript} http://127.0.0.1:8787/global/health")

    # Cross-node behavioral probe: client reaches server through the firewall
    client.wait_for_unit("multi-user.target")
    client.succeed("curl --max-time 10 --silent http://server:8787/global/health | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d[\"healthy\"] is True'")

    print("open-firewall: all probes PASS")
  '';
}
