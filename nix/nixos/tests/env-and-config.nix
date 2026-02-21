{ pkgs, ... }:
let
  healthcheckScript = pkgs.writeText "healthcheck-env-and-config.py" ''
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
  name = "opencode-env-and-config";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../module.nix ];

      system.stateVersion = "24.11";

      environment.systemPackages = [ pkgs.python3 ];

      environment.etc."test-opencode.env".text = ''
        SECRET_VAR=supersecret
        OVERRIDE_ME=from-envfile
      '';

      services.opencode = {
        enable = true;
        defaults.directory = "/var/lib/opencode/default-directory";
        instances.env-test = {
          directory = "/srv/env-test";
          listen.port = 8787;
          environment.MY_VAR = "hello";
          environment.OVERRIDE_ME = "from-env";
          environmentFile = "/etc/test-opencode.env";
          config.theme = "dark";
        };
      };

      system.activationScripts.testDirs = "mkdir -p /srv/env-test";
    };

  testScript = ''
    machine.wait_for_unit("opencode-env-test-setup.service")
    machine.wait_for_unit("opencode-env-test.service")
    machine.wait_for_open_port(8787)
    machine.succeed("python3 ${healthcheckScript}")
    machine.succeed("systemctl show opencode-env-test.service --property=Environment | grep -q MY_VAR=hello")
    machine.succeed("tr '\\0' '\\n' < /proc/$(systemctl show opencode-env-test.service -p MainPID --value)/environ | grep -x 'OVERRIDE_ME=from-envfile'")

    state_dir = "/var/lib/opencode/instance-state/env-test"
    machine.succeed(f"test -L {state_dir}/.config/opencode/opencode.json")
    machine.succeed(f"${pkgs.jq}/bin/jq . {state_dir}/.config/opencode/opencode.json")
    print("env-and-config: PASS")
  '';
}
