{ pkgs }:
let
  inherit (pkgs) lib;

  evalNixos =
    modules:
    (import "${pkgs.path}/nixos/lib/eval-config.nix" {
      inherit pkgs;
      inherit (pkgs.stdenv.hostPlatform) system;
      modules = [
        ../module.nix
        {
          system.stateVersion = "24.11";
          services.opencode.defaults.directory = "/var/lib/opencode/default-directory";
          services.opencode.defaults.package = pkgs.hello;
        }
      ]
      ++ modules;
    }).config;

  twoInstanceConfig = evalNixos [
    {
      services.opencode = {
        enable = true;
        instances = {
          project-a = {
            directory = "/srv/project-a";
            listen.port = 8787;
          };
          project-b = {
            directory = "/srv/project-b";
            listen.port = 9090;
            environment.MY_VAR = "hello";
          };
        };
      };
    }
  ];

  test-two-services =
    assert
      twoInstanceConfig.systemd.services ? "opencode-project-a"
      && twoInstanceConfig.systemd.services ? "opencode-project-b";
    "PASS: two instances produce independent service units";

  test-listen-ports =
    let
      execA = twoInstanceConfig.systemd.services."opencode-project-a".serviceConfig.ExecStart;
      execB = twoInstanceConfig.systemd.services."opencode-project-b".serviceConfig.ExecStart;
    in
    assert (builtins.match ".*8787.*" execA != null) && (builtins.match ".*9090.*" execB != null);
    "PASS: listen ports reflected in ExecStart";

  test-home-env =
    let
      env = twoInstanceConfig.systemd.services."opencode-project-a".environment;
    in
    assert env.HOME == "/var/lib/opencode/instance-state/project-a";
    "PASS: HOME = stateDir in service environment";

  test-firewall-default =
    let
      ports = twoInstanceConfig.networking.firewall.allowedTCPPorts;
    in
    assert ports == [ ];
    "PASS: openFirewall defaults to closed";

  test-hardening =
    let
      sc = twoInstanceConfig.systemd.services."opencode-project-a".serviceConfig;
    in
    assert
      sc.ProtectKernelTunables
      && sc.ProtectKernelModules
      && sc.ProtectControlGroups
      && sc.NoNewPrivileges;
    "PASS: hardening flags enabled by default";

  test-unix-socket =
    let
      cfg = evalNixos [
        {
          services.opencode = {
            enable = true;
            instances.db-project = {
              directory = "/srv/db-project";
              sandbox.unixSockets.allow = [ "/run/postgresql/.s.PGSQL.5432" ];
            };
          };
        }
      ];
    in
    assert builtins.elem "/run/postgresql/.s.PGSQL.5432"
      cfg.systemd.services."opencode-db-project".serviceConfig.BindReadOnlyPaths;
    "PASS: unix socket paths appear in BindReadOnlyPaths";

  test-env-file =
    let
      cfg = evalNixos [
        {
          services.opencode = {
            enable = true;
            instances.secret-project = {
              directory = "/srv/secret";
              environmentFile = "/run/secrets/opencode.env";
            };
          };
        }
      ];
    in
    assert
      cfg.systemd.services."opencode-secret-project".serviceConfig.EnvironmentFile
      == "/run/secrets/opencode.env";
    "PASS: environmentFile wired to EnvironmentFile=";

  test-defaults-merge =
    let
      cfg = evalNixos [
        {
          services.opencode = {
            enable = true;
            defaults.listen.port = 8080;
            instances.my-project = {
              directory = "/srv/my-project";
              listen.port = 9090;
            };
          };
        }
      ];
      execStart = cfg.systemd.services."opencode-my-project".serviceConfig.ExecStart;
    in
    assert builtins.match ".*9090.*" execStart != null;
    "PASS: instance listen.port overrides defaults";

  test-firewall-open =
    let
      cfg = evalNixos [
        {
          services.opencode = {
            enable = true;
            instances.exposed = {
              directory = "/srv/exposed";
              openFirewall = true;
              listen.port = 8787;
            };
          };
        }
      ];
    in
    assert builtins.elem 8787 cfg.networking.firewall.allowedTCPPorts;
    "PASS: openFirewall=true adds listen.port to allowedTCPPorts";

  test-firewall-and-isolation-coexist =
    let
      cfg = evalNixos [
        {
          networking.nftables.enable = true;
          services.opencode = {
            enable = true;
            instances = {
              exposed = {
                directory = "/srv/exposed";
                openFirewall = true;
                listen.port = 8787;
              };
              isolated = {
                directory = "/srv/isolated";
                listen.port = 9090;
                networkIsolation.enable = true;
              };
            };
          };
        }
      ];
    in
    assert
      builtins.elem 8787 cfg.networking.firewall.allowedTCPPorts
      && cfg.networking.nftables.tables ? "opencode-egress";
    "PASS: openFirewall and networkIsolation evaluate together with nftables table";
in
pkgs.runCommand "opencode-module-eval-tests" { } ''
  echo "Running opencode NixOS module evaluation tests..."
  echo ${lib.escapeShellArg test-two-services}
  echo ${lib.escapeShellArg test-listen-ports}
  echo ${lib.escapeShellArg test-home-env}
  echo ${lib.escapeShellArg test-firewall-default}
  echo ${lib.escapeShellArg test-hardening}
  echo ${lib.escapeShellArg test-unix-socket}
  echo ${lib.escapeShellArg test-env-file}
  echo ${lib.escapeShellArg test-defaults-merge}
  echo ${lib.escapeShellArg test-firewall-open}
  echo ${lib.escapeShellArg test-firewall-and-isolation-coexist}
  echo "All eval tests passed."
  touch "$out"
''
