{ pkgs, ... }:
pkgs.nixosTest {
  name = "opencode-postgres-socket";

  nodes.machine = { ... }: {
    imports = [ ../module.nix ];

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "testdb" ];
      ensureUsers = [
        {
          name = "opencode-pg-project";
          ensureDBOwnership = false;
        }
      ];
    };

    services.opencode = {
      enable = true;
      defaults.directory = "/var/lib/opencode/default-directory";
      defaults.package = pkgs.writeShellScriptBin "opencode" "exec sleep infinity";
      instances.pg-project = {
        directory = "/srv/pg-project";
        sandbox.unixSockets.allow = [ "/run/postgresql" ];
        preInitScript = ''
          ${pkgs.postgresql}/bin/psql -h /run/postgresql -U opencode-pg-project -c '\\l' testdb
        '';
      };
    };

    system.activationScripts.testDirs = "mkdir -p /srv/pg-project";
  };

  testScript = ''
    machine.wait_for_unit("postgresql.service")
    machine.wait_for_unit("opencode-pg-project-setup.service")
    print("postgres-socket: PASS")
  '';
}
