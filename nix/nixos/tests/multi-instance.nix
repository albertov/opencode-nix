{ pkgs, ... }:
let
  healthcheckScript = pkgs.writeText "healthcheck-multi-instance.py" ''
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
  name = "opencode-multi-instance";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ (import ../module.nix) ];

      system.stateVersion = "24.11";

      environment.systemPackages = [ pkgs.python3 ];

      services.opencode = {
        enable = true;
        defaults.directory = "/var/lib/opencode/default-directory";
        instances = {
          project-a = {
            directory = "/srv/project-a";
            listen.address = "127.0.0.1";
            listen.port = 8787;
            environment.INSTANCE_ID = "project-a";
          };

          project-b = {
            directory = "/srv/project-b";
            listen.address = "127.0.0.1";
            listen.port = 9090;
            environment.INSTANCE_ID = "project-b";
          };
        };
      };

      system.activationScripts.testDirs = ''
        mkdir -p /srv/project-a /srv/project-b
      '';
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    machine.wait_for_unit("opencode-project-a-setup.service")
    machine.wait_for_unit("opencode-project-b-setup.service")
    machine.wait_for_unit("opencode-project-a.service")
    machine.wait_for_unit("opencode-project-b.service")
    machine.wait_for_open_port(8787)
    machine.wait_for_open_port(9090)
    machine.succeed("python3 ${healthcheckScript}")

    machine.succeed("test -d /var/lib/opencode/instance-state/project-a/.config/opencode")
    machine.succeed("test -d /var/lib/opencode/instance-state/project-b/.config/opencode")

    machine.succeed("systemctl cat opencode-project-a.service")
    machine.succeed("systemctl cat opencode-project-b.service")

    machine.succeed("id opencode-project-a")
    machine.succeed("id opencode-project-b")

    print("multi-instance: PASS")
  '';
}
