{ pkgs, ... }:
pkgs.testers.nixosTest {
  name = "opencode-hook-ordering";

  nodes.machine =
    { ... }:
    {
      imports = [ (import ../module.nix) ];

      system.stateVersion = "24.11";

      services.opencode = {
        enable = true;
        defaults.directory = "/var/lib/opencode/default-directory";
        instances.hook-test = {
          directory = "/srv/hook-test";
          listen.port = 9191;
          opencodeCfg = [ { opencode.theme = "dark"; } ];
          preInitScript = ''
            date +%s%N > /tmp/pre-stamp
          '';
          postInitScript = ''
            date +%s%N > /tmp/post-stamp
          '';
        };
      };

      system.activationScripts.testDirs = ''
        mkdir -p /srv/hook-test
      '';
    };

  testScript = ''
    machine.wait_for_unit("opencode-hook-test-setup.service")
    machine.wait_for_unit("opencode-hook-test.service")

    machine.succeed("test -f /tmp/pre-stamp")
    machine.succeed("test -f /tmp/post-stamp")
    state_dir = "/var/lib/opencode/instance-state/hook-test"
    machine.succeed(f"test -L {state_dir}/.config/opencode/opencode.json")
    machine.succeed("[ $(cat /tmp/pre-stamp) -le $(cat /tmp/post-stamp) ]")

    print("hook-ordering: PASS")
  '';
}
