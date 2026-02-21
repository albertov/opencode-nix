{ pkgs, ... }:
pkgs.testers.nixosTest {
  name = "opencode-setup-idempotence";

  nodes.machine = { ... }: {
    imports = [ ../module.nix ];

    services.opencode = {
      enable = true;
      defaults.directory = "/var/lib/opencode/default-directory";
      defaults.package = pkgs.writeShellScriptBin "opencode" "exec sleep infinity";
      instances.my-project = {
        directory = "/srv/my-project";
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
    machine.succeed("test -d /var/lib/opencode/instance-state/my-project/.config/opencode")
    machine.succeed("test -z \"$(ls /srv/my-project)\"")
    machine.succeed("systemctl restart opencode-my-project-setup.service")
    machine.wait_for_unit("opencode-my-project-setup.service")
    print("setup-idempotence: PASS")
  '';
}
