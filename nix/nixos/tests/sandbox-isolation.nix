{ pkgs, ... }:
let
  healthcheckScript = pkgs.writeText "healthcheck-sandbox-isolation.py" ''
    import json
    import urllib.request

    def fetch(url):
        with urllib.request.urlopen(url) as response:
            return json.loads(response.read().decode())

    for port in (8787, 9090):
        health = fetch(f"http://127.0.0.1:{port}/global/health")
        assert health.get("healthy") is True, "health failed on {}: {}".format(port, health)
        print("[PASS] port {} healthy version={}".format(port, health.get("version", "?")))
  '';
in
pkgs.testers.nixosTest {
  name = "opencode-sandbox-isolation";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../module.nix ];

      system.stateVersion = "24.11";

      environment.systemPackages = [ pkgs.python3 ];

      services.opencode = {
        enable = true;
        defaults.directory = "/var/lib/opencode/default-directory";
        instances = {
          instance-a = {
            directory = "/srv/project-a";
            stateDir = "/var/lib/opencode/state/a";
            listen.port = 8787;
          };
          instance-b = {
            directory = "/srv/project-b";
            stateDir = "/var/lib/opencode/state/b";
            listen.port = 9090;
          };
        };
      };

      system.activationScripts.testDirs = ''
        mkdir -p /srv/project-a /srv/project-b
      '';
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("opencode-instance-a-setup.service")
    machine.wait_for_unit("opencode-instance-b-setup.service")
    machine.wait_for_unit("opencode-instance-a.service")
    machine.wait_for_unit("opencode-instance-b.service")
    machine.wait_for_open_port(8787)
    machine.wait_for_open_port(9090)
    machine.succeed("python3 ${healthcheckScript}")

    machine.fail("su -s /bin/sh -c 'ls /var/lib/opencode/state/b' opencode-instance-a")
    machine.succeed("su -s /bin/sh -c 'ls /nix/store' opencode-instance-a")
    machine.succeed("su -s /bin/sh -c 'touch /var/lib/opencode/state/a/.test' opencode-instance-a")
    print("sandbox-isolation: PASS")
  '';
}
