{ config, lib, pkgs, ... }:
let
  cfg = config.services.opencode;

  # Per-instance submodule
  instanceOpts = { name, ... }: {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable this opencode instance.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.opencode or (throw "pkgs.opencode not found; apply the opencode overlay");
        defaultText = lib.literalExpression "pkgs.opencode";
        description = "The opencode package to use.";
      };

      directory = lib.mkOption {
        type = lib.types.str;
        description = "Working directory for this opencode instance (operator-managed project root).";
        example = "/srv/projects/my-project";
      };

      stateDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/opencode/instance-state/${name}";
        description = "Persistent state directory for this instance (separate from directory).";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "opencode-${name}";
        description = "User account for this instance.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "opencode";
        description = "Group for this instance.";
      };

      listen = {
        address = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Listen address for this instance.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 8080;
          description = "Listen port for this instance.";
        };
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to open the firewall for this instance's listen port.";
      };

      environment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Environment variables for this instance.";
        example = { OPENCODE_FOO = "bar"; };
      };

      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to environment file (e.g. /run/secrets/opencode-my-project.env) for secret variables.";
        example = "/run/secrets/opencode-my-project.env";
      };

      path = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Additional packages to add to PATH for this instance.";
        example = lib.literalExpression "[ pkgs.jq pkgs.git ]";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra arguments to pass to the opencode CLI.";
        example = [ "--log-level" "debug" ];
      };

      sandbox = {
        readWritePaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Additional read-write paths to allow in the sandbox.";
        };
        readOnlyPaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Additional read-only paths to allow in the sandbox.";
        };
        unixSockets = {
          allow = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Unix socket paths to allow access to.";
            example = [ "/run/postgresql/.s.PGSQL.5432" ];
          };
        };
      };

      networkIsolation = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable outbound network isolation.";
        };
        outboundAllowCidrs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "CIDR ranges to allow for outbound connections.";
          example = [ "10.10.0.0/16" "192.168.1.0/24" ];
        };
      };

      preInitScript = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Script to run before module-managed setup steps.";
      };

      postInitScript = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Script to run after module-managed setup steps.";
      };
    };
  };

  mergedInstances = lib.mapAttrs (_: instance:
    lib.recursiveUpdate cfg.defaults instance
  ) cfg.instances;

  enabledInstances = lib.filterAttrs (_: instance: instance.enable) mergedInstances;

  groupNames = lib.unique (lib.mapAttrsToList (_: instance: instance.group) enabledInstances);
in
{
  options.services.opencode = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable the opencode multi-instance service.";
    };

    defaults = lib.mkOption {
      type = lib.types.submodule instanceOpts;
      default = {};
      description = "Default values merged into each instance (instance values take precedence).";
    };

    instances = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule instanceOpts);
      default = {};
      description = "Opencode instance definitions.";
      example = lib.literalExpression ''
        {
          my-project = {
            directory = "/srv/projects/my-project";
            listen.port = 8787;
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = lib.mkMerge [
      (lib.mapAttrs' (name: instance:
        lib.nameValuePair "opencode-${name}" {
          description = "opencode instance ${name}";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" "opencode-${name}-setup.service" ];
          requires = [ "opencode-${name}-setup.service" ];

          path = instance.path;

          environment = {
            HOME = instance.stateDir;
          } // instance.environment;

          serviceConfig =
            lib.optionalAttrs (instance.environmentFile != null) {
              EnvironmentFile = instance.environmentFile;
            }
            // {
              Type = "simple";
              User = instance.user;
              Group = instance.group;
              WorkingDirectory = instance.directory;

              ExecStart = lib.escapeShellArgs (
                [ "${instance.package}/bin/opencode" "--listen" "${instance.listen.address}:${toString instance.listen.port}" ]
                ++ instance.extraArgs
              );

              Restart = "on-failure";
              RestartSec = "5s";

              # Filesystem isolation
              PrivateTmp = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              ReadWritePaths = [ instance.directory instance.stateDir ] ++ instance.sandbox.readWritePaths;
              ReadOnlyPaths = [ "/nix/store" ] ++ instance.sandbox.readOnlyPaths;

              # Process isolation
              PrivateMounts = true;
              ProtectProc = "noaccess";
              ProcSubset = "pid";

              # Kernel hardening
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectControlGroups = true;
              ProtectKernelLogs = true;
              ProtectClock = true;

              # Additional hardening
              NoNewPrivileges = true;
              LockPersonality = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              MemoryDenyWriteExecute = false; # opencode may need JIT
              RemoveIPC = true;

              # Network (allow all by default; networkIsolation adds policy separately)
              PrivateNetwork = false;
            };
        }
      ) enabledInstances)

      (lib.mapAttrs' (name: instance:
        lib.nameValuePair "opencode-${name}-setup" {
          description = "opencode instance ${name} setup";
          wantedBy = [ "opencode-${name}.service" ];
          before = [ "opencode-${name}.service" ];

          environment.HOME = instance.stateDir;

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = instance.user;
            Group = instance.group;

            ExecStart = pkgs.writeShellScript "opencode-${name}-setup" ''
              set -euo pipefail
              ${lib.optionalString (instance.preInitScript != null) instance.preInitScript}

              # Initialize state directory structure (idempotent)
              mkdir -p "${instance.stateDir}/.local/share/opencode"
              mkdir -p "${instance.stateDir}/.config/opencode"

              ${lib.optionalString (instance.postInitScript != null) instance.postInitScript}
            '';
          };
        }
      ) enabledInstances)
    ];

    networking.firewall.allowedTCPPorts = lib.flatten (
      lib.mapAttrsToList (_: instance:
        lib.optional instance.openFirewall instance.listen.port
      ) enabledInstances
    );

    users.users = lib.mapAttrs' (_: instance:
      lib.nameValuePair instance.user {
        isSystemUser = true;
        group = instance.group;
        home = instance.stateDir;
        createHome = false;
      }
    ) enabledInstances;

    users.groups = lib.genAttrs groupNames (_: {});
  };
}
