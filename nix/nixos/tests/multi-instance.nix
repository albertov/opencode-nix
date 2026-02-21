{ pkgs, ... }:
pkgs.nixosTest {
  name = "opencode-multi-instance";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ (import ../module.nix) ];

    services.opencode = {
      enable = true;
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

    machine.succeed("test -d /var/lib/opencode/instance-state/project-a/.config/opencode")
    machine.succeed("test -d /var/lib/opencode/instance-state/project-b/.config/opencode")

    machine.succeed("systemctl cat opencode-project-a.service")
    machine.succeed("systemctl cat opencode-project-b.service")

    machine.succeed("id opencode-project-a")
    machine.succeed("id opencode-project-b")

    print("multi-instance: PASS")
  '';
}
