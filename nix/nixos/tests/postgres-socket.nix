{ pkgs, ... }:
let
  healthcheckScript = pkgs.writeText "healthcheck-postgres-socket.py" ''
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
  name = "opencode-postgres-socket";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../module.nix ];

      system.stateVersion = "24.11";

      environment.systemPackages = [ pkgs.python3 ];

      services.postgresql = {
        enable = true;
        ensureDatabases = [ "testdb" ];
        ensureUsers = [
          {
            name = "opencode-pg-project";
            ensureDBOwnership = false;
          }
        ];
      };

      services.opencode = {
        enable = true;
        defaults.directory = "/var/lib/opencode/default-directory";
        instances.pg-project = {
          directory = "/srv/pg-project";
          listen.port = 8787;
          sandbox.unixSockets.allow = [ "/run/postgresql" ];
        };
      };

      system.activationScripts.testDirs = "mkdir -p /srv/pg-project";
    };

  testScript = ''
    machine.wait_for_unit("postgresql.service")
    machine.wait_for_unit("opencode-pg-project-setup.service")
    machine.wait_for_unit("opencode-pg-project.service")
    machine.wait_for_open_port(8787)
    machine.succeed("python3 ${healthcheckScript}")
    machine.succeed("sudo -u opencode-pg-project psql -h /run/postgresql -d testdb -c 'SELECT 1'")

    print("postgres-socket: PASS")
  '';
}
