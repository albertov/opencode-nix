{ pkgs, ... }:
pkgs.testers.nixosTest {
  name = "opencode-env-and-config";

  nodes.machine = { ... }: {
    imports = [ ../module.nix ];

    environment.etc."test-opencode.env".text = "SECRET_VAR=supersecret\n";

    services.opencode = {
      enable = true;
      defaults.directory = "/var/lib/opencode/default-directory";
      defaults.package = pkgs.writeShellScriptBin "opencode" "exec sleep infinity";
      instances.env-test = {
        directory = "/srv/env-test";
        environment.MY_VAR = "hello";
        environmentFile = "/etc/test-opencode.env";
        opencodeCfg = [ { opencode.theme = "dark"; } ];
      };
    };

    system.activationScripts.testDirs = "mkdir -p /srv/env-test";
  };

  testScript = ''
    machine.wait_for_unit("opencode-env-test-setup.service")
    state_dir = "/var/lib/opencode/instance-state/env-test"
    machine.succeed(f"test -L {state_dir}/.config/opencode/opencode.json")
    machine.succeed(f"${pkgs.jq}/bin/jq . {state_dir}/.config/opencode/opencode.json")
    print("env-and-config: PASS")
  '';
}
