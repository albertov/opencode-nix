{ pkgs, ... }:
pkgs.testers.nixosTest {
  name = "opencode-hook-failure";

  nodes.machine =
    { ... }:
    {
      imports = [ (import ../module.nix) ];

      system.stateVersion = "24.11";

      services.opencode = {
        enable = true;
        defaults.directory = "/var/lib/opencode/default-directory";
        instances.fail-test = {
          directory = "/srv/fail-test";
          listen.port = 9292;
          preInitScript = "exit 1";
        };
      };

      system.activationScripts.testDirs = ''
        mkdir -p /srv/fail-test
      '';
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.wait_until_succeeds("systemctl is-failed opencode-fail-test-setup.service")
    machine.fail("systemctl is-active opencode-fail-test-setup.service")
    machine.fail("systemctl is-active opencode-fail-test.service")

    print("hook-failure: PASS")
  '';
}
