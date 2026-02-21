{ pkgs, ... }:
let
  healthcheckScript = pkgs.writeText "healthcheck-setup-idempotence.py" ''
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
  name = "opencode-setup-idempotence";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../module.nix ];

      system.stateVersion = "24.11";

      environment.systemPackages = [ pkgs.python3 ];

      services.opencode = {
        enable = true;
        defaults.directory = "/var/lib/opencode/default-directory";
        instances.my-project = {
          directory = "/srv/my-project";
          listen.port = 8787;
          preInitScript = "echo 'pre-init ran'";
          postInitScript = "echo 'post-init ran'";
        };
      };

      system.activationScripts.testDirs = ''
        mkdir -p /srv/my-project
      '';
    };

  testScript = ''
    machine.wait_for_unit("opencode-my-project-setup.service")
    machine.wait_for_unit("opencode-my-project.service")
    machine.wait_for_open_port(8787)
    machine.succeed("python3 ${healthcheckScript}")
    machine.succeed("test -d /var/lib/opencode/instance-state/my-project/.config/opencode")
    machine.succeed("test -z \"$(ls /srv/my-project)\"")
    machine.succeed("systemctl restart opencode-my-project-setup.service")
    machine.wait_for_unit("opencode-my-project-setup.service")
    print("setup-idempotence: PASS")
  '';
}
