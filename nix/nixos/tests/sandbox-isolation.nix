{ pkgs, ... }:
pkgs.nixosTest {
  name = "opencode-sandbox-isolation";

  nodes.machine = { ... }: {
    imports = [ ../module.nix ];

    services.opencode = {
      enable = true;
      defaults.directory = "/var/lib/opencode/default-directory";
      defaults.package = pkgs.writeShellScriptBin "opencode" "exec sleep infinity";
      instances = {
        instance-a = {
          directory = "/srv/project-a";
          stateDir = "/var/lib/opencode/state/a";
        };
        instance-b = {
          directory = "/srv/project-b";
          stateDir = "/var/lib/opencode/state/b";
        };
      };
    };

    system.activationScripts.testDirs = ''
      mkdir -p /srv/project-a /srv/project-b
    '';
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.fail("su -s /bin/sh -c 'echo x > /tmp/escaped' opencode-instance-a")
    machine.fail("su -s /bin/sh -c 'ls /var/lib/opencode/state/b' opencode-instance-a")
    machine.succeed("su -s /bin/sh -c 'ls /nix/store' opencode-instance-a")
    machine.succeed("su -s /bin/sh -c 'touch /var/lib/opencode/state/a/.test' opencode-instance-a")
    print("sandbox-isolation: PASS")
  '';
}
