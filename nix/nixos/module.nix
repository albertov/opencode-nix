{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.opencode;

  # Per-instance submodule
  instanceOpts =
    { name, ... }:
    {
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
          default = "";
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

        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Supplementary groups for this instance's system user.";
          example = [
            "docker"
            "media"
          ];
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
          default = { };
          description = "Environment variables for this instance.";
          example = {
            OPENCODE_FOO = "bar";
          };
        };

        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Path to environment file (e.g. /run/secrets/opencode-my-project.env) for secret variables.";
          example = "/run/secrets/opencode-my-project.env";
        };

        path = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Additional packages to add to PATH for this instance.";
          example = lib.literalExpression "[ pkgs.jq pkgs.git ]";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra arguments to pass to the opencode CLI.";
          example = [
            "--log-level"
            "debug"
          ];
        };

        # NOTE: Rejecting interactive-mode flags in extraArgs is intentionally not
        # enforced statically here; robust CLI flag validation at Nix eval time is brittle.

        # Runtime options
        logLevel = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "debug"
              "info"
              "warn"
              "error"
            ]
          );
          default = null;
          description = "Log level for the opencode instance.";
        };

        model = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Model identifier to use (e.g. 'claude-opus-4-5').";
        };

        provider = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Provider to use (e.g. 'anthropic', 'openai').";
        };

        config = lib.mkOption {
          type = lib.types.submoduleWith {
            modules = [ ../config/submodule.nix ];
          };
          default = { };
          description = "Typed opencode configuration. Same options as nix/config/default.nix without the opencode. prefix.";
        };

        configFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Explicit path to opencode.json config file.
            When set, bypasses JSON generation from the config submodule.
            When null (default), JSON is generated from the config option values.
          '';
        };

        sandbox = {
          readWritePaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Additional read-write paths to allow in the sandbox.";
          };
          readOnlyPaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Additional read-only paths to allow in the sandbox.";
          };
          unixSockets = {
            allow = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
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
            default = [ ];
            description = "CIDR ranges to allow for outbound connections.";
            example = [
              "10.10.0.0/16"
              "192.168.1.0/24"
            ];
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

  mergedInstances = lib.mapAttrs (
    _: instance: lib.recursiveUpdate cfg.defaults instance
  ) cfg.instances;

  enabledInstances = lib.filterAttrs (_: instance: instance.enable) mergedInstances;
  isolatedInstances = lib.filterAttrs (
    _: instance: instance.enable && instance.networkIsolation.enable
  ) mergedInstances;

  # Recursively strip null values from an attrset.
  # Used to prevent instance null defaults from shadowing non-null shared defaults.
  stripNulls =
    attrs:
    lib.mapAttrs (_: v: if builtins.isAttrs v then stripNulls v else v) (
      lib.filterAttrs (_: v: v != null) attrs
    );

  # Resolve the opencode.json config file path for an instance.
  # Precedence: explicit configFile > generated from config submodule.
  resolveConfigFile =
    name: _mergedInstance:
    let
      rawInstance = cfg.instances.${name};
    in
    if rawInstance.configFile != null then
      rawInstance.configFile
    else
      let
        ocLib =
          if pkgs ? lib && pkgs.lib ? opencode then
            pkgs.lib.opencode
          else
            import ../config/lib.nix {
              inherit pkgs;
              inherit (pkgs) lib;
            };
        # Strip nulls before merge: instance unset values (null) must not shadow
        # explicitly-set defaults. After stripping, recursiveUpdate gives instance precedence.
        defaultsCfg = stripNulls cfg.defaults.config;
        instanceCfg = stripNulls rawInstance.config;
        mergedCfg = lib.recursiveUpdate defaultsCfg instanceCfg;
      in
      ocLib.mkOpenCodeConfigFromAttrs mergedCfg;

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
      default = { };
      description = "Default values merged into each instance (instance values take precedence).";
    };

    instances = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule instanceOpts);
      default = { };
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
    assertions = lib.flatten (
      lib.mapAttrsToList (name: instance: [
        {
          assertion = instance.directory != "";
          message = "services.opencode.instances.${name}.directory must not be empty";
        }
        {
          assertion = instance.listen.port >= 1 && instance.listen.port <= 65535;
          message = "services.opencode.instances.${name}.listen.port must be between 1 and 65535 (got ${toString instance.listen.port})";
        }
        {
          assertion = instance.stateDir != instance.directory;
          message = "services.opencode.instances.${name}.stateDir must differ from directory to avoid mixing runtime state with project files";
        }
        {
          assertion = !instance.networkIsolation.enable || config.networking.nftables.enable;
          message = "opencode: networkIsolation requires networking.nftables.enable = true";
        }
      ]) (lib.filterAttrs (_: i: i.enable) mergedInstances)
    );

    systemd.services = lib.mkMerge [
      (lib.mapAttrs' (
        name: instance:
        lib.nameValuePair "opencode-${name}" {
          description = "opencode instance ${name}";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "opencode-${name}-setup.service"
          ];
          requires = [ "opencode-${name}-setup.service" ];

          inherit (instance) path;

          environment = {
            HOME = instance.stateDir;
          }
          // instance.environment;

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
                [
                  "${instance.package}/bin/opencode"
                  "serve"
                  "--print-logs"
                ]
                ++ [
                  "--port"
                  (toString instance.listen.port)
                ]
                ++ [
                  "--hostname"
                  instance.listen.address
                ]
                ++ lib.optionals (instance.logLevel != null) [
                  "--log-level"
                  instance.logLevel
                ]
                ++ lib.optionals (instance.model != null) [
                  "--model"
                  instance.model
                ]
                ++ lib.optionals (instance.provider != null) [
                  "--provider"
                  instance.provider
                ]
                ++ instance.extraArgs
              );

              Restart = "on-failure";
              RestartSec = "5s";

              # Filesystem isolation
              PrivateTmp = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              ReadWritePaths = [
                instance.directory
                instance.stateDir
              ]
              ++ instance.sandbox.readWritePaths;
              ReadOnlyPaths = [ "/nix/store" ] ++ instance.sandbox.readOnlyPaths;
              BindReadOnlyPaths = instance.sandbox.unixSockets.allow;

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

      (lib.mapAttrs' (
        name: instance:
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

            ExecStart =
              let
                configPath = resolveConfigFile name instance;
              in
              pkgs.writeShellScript "opencode-${name}-setup" ''
                set -euo pipefail
                ${lib.optionalString (instance.preInitScript != null) instance.preInitScript}

                # Initialize state directory structure (idempotent)
                mkdir -p "${instance.stateDir}/.local/share/opencode"
                mkdir -p "${instance.stateDir}/.config/opencode"

                # Symlink config (generated from config submodule or explicit configFile)
                ln -sf "${configPath}" "${instance.stateDir}/.config/opencode/opencode.json"

                ${lib.optionalString (instance.postInitScript != null) instance.postInitScript}
              '';
          };
        }
      ) enabledInstances)
    ];

    networking.firewall.allowedTCPPorts = lib.flatten (
      lib.mapAttrsToList (
        _: instance: lib.optional instance.openFirewall instance.listen.port
      ) enabledInstances
    );

    networking.nftables = lib.mkIf (isolatedInstances != { }) {
      enable = true;
      tables.opencode-egress = {
        family = "inet";
        content =
          let
            instanceRules = lib.mapAttrsToList (
              name: instance:
              let
                skuid =
                  let
                    uid = config.users.users.${instance.user}.uid or null;
                  in
                  if uid == null then ''"${instance.user}"'' else toString uid;
                allowRules = lib.concatMapStringsSep "\n" (
                  cidr:
                  if lib.hasInfix ":" cidr then
                    ''
                      meta skuid ${skuid} ip6 daddr ${cidr} accept
                    ''
                  else
                    ''
                      meta skuid ${skuid} ip daddr ${cidr} accept
                    ''
                ) instance.networkIsolation.outboundAllowCidrs;
              in
              ''
                # Instance: ${name} (user: ${instance.user})
                # Outbound allow-list for ${name} enforced by UID match
                ${allowRules}
                # Log and drop other outbound from this user (rate limited)
                meta skuid ${skuid} limit rate 5/minute log prefix "opencode-${name}-blocked: " drop
                meta skuid ${skuid} drop
              ''
            ) isolatedInstances;
          in
          ''
            chain output {
              type filter hook output priority 0; policy accept;
              # Allow loopback
              oif lo accept
              # Allow established/related connections
              ct state established,related accept
              ${lib.concatStringsSep "\n" instanceRules}
            }
          '';
      };
    };

    users.users = lib.mapAttrs' (
      _: instance:
      lib.nameValuePair instance.user {
        isSystemUser = true;
        inherit (instance) group;
        inherit (instance) extraGroups;
        home = instance.stateDir;
        createHome = true;
      }
    ) enabledInstances;

    users.groups = lib.genAttrs groupNames (_: { });
  };
}
