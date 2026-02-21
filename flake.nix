{
  description = "Nix module system for generating opencode.json config files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opencode.url = "github:anomalyco/opencode";
    opencode.inputs.nixpkgs.follows = "nixpkgs";
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      opencode,
      systems,
      treefmt-nix,
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      forAllSystems = f: eachSystem (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = forAllSystems (pkgs: treefmt-nix.lib.evalModule pkgs ./nix/treefmt.nix);

      mkLib =
        pkgs:
        import ./nix/config/lib.nix {
          inherit pkgs;
          inherit (pkgs) lib;
        };
    in
    {
      overlays.default = final: prev: {
        lib = prev.lib // {
          opencode = mkLib final;
        };
        opencode = opencode.packages.${final.system}.default;
      };

      nixosModules = {
        opencode = import ./nix/nixos/module.nix;
        default = import ./nix/nixos/module.nix;
        example-chief-coding-assistant = import ./examples/chief-coding-assistant;
        example-simple-coding-assistant = import ./examples/simple-coding-assistant;
      };

      checks = forAllSystems (
        pkgs:
        let
          lib = mkLib pkgs;
          inherit (pkgs.stdenv.hostPlatform) system;
          overlayPkgs = pkgs.extend self.overlays.default;
          baseChecks = {
            empty-config = pkgs.runCommand "empty-config-test" { } ''
              config=${lib.mkOpenCodeConfig [ ]}
              content=$(cat "$config")
              echo "Generated config: $content"
              if [ "$content" = "{}" ]; then
                echo "PASS: empty config produces {}"
              else
                echo "FAIL: expected '{}' but got '$content'"
                exit 1
              fi
              touch $out
            '';

            wrap-opencode-type = pkgs.runCommand "wrap-opencode-type-test" { } ''
              config=${lib.mkOpenCodeConfig [ { opencode.theme = "dark"; } ]}
              content=$(cat "$config")
              echo "Config: $content"
              if echo "$content" | grep -q '"theme"'; then
                echo "PASS: theme option present in output"
                touch $out
              else
                echo "FAIL: theme option missing from output"
                exit 1
              fi
            '';

            field-output-check = pkgs.runCommand "field-output-test" { } ''
              config=${
                lib.mkOpenCodeConfig [
                  {
                    opencode.theme = "catppuccin";
                    opencode.logLevel = "DEBUG";
                  }
                ]
              }
              content=$(cat "$config")
              echo "Config: $content"
              if echo "$content" | grep -q '"theme"' && echo "$content" | grep -q '"logLevel"'; then
                echo "PASS"
                touch $out
              else
                echo "FAIL: expected both theme and logLevel in output"
                cat "$config"
                exit 1
              fi
            '';

            # Zod schema validation: validates generated configs against the
            # upstream Config.Info Zod schema from the opencode source.
            # Requires node_modules (fetched as a fixed-output derivation).
            config-zod-tests = import ./nix/tests {
              inherit pkgs opencode;
              inherit (lib) mkOpenCodeConfig;
            };

            overlay-mkOpenCodeConfig = overlayPkgs.lib.opencode.mkOpenCodeConfig [ ];

            overlay-wrapOpenCode = overlayPkgs.lib.opencode.wrapOpenCode {
              modules = [ ];
              opencode = opencode.packages.${system}.default;
            };

            nixos-module-eval = import ./nix/nixos/tests/eval-tests.nix { inherit pkgs; };
          };
        in
        baseChecks
        // {
          treefmt = treefmtEval.${system}.config.build.check self;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") (import ./nix/nixos/tests { inherit pkgs; })
      );

      formatter = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
        in
        treefmtEval.${system}.config.build.wrapper
      );

      apps.x86_64-linux.run-nixos-tests =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          type = "app";
          meta.description = "Build all NixOS VM tests for ocnix";
          program = "${
            pkgs.writeShellApplication {
              name = "run-nixos-tests";
              runtimeInputs = [ pkgs.nix ];
              text = ''
                exec nix build \
                  .#checks.x86_64-linux.multi-instance \
                  .#checks.x86_64-linux.network-policy \
                  .#checks.x86_64-linux.sandbox-isolation \
                  .#checks.x86_64-linux.setup-idempotence \
                  .#checks.x86_64-linux.env-and-config \
                  .#checks.x86_64-linux.postgres-socket \
                  .#checks.x86_64-linux.simple-coding-assistant \
                  .#checks.x86_64-linux.hook-ordering \
                  .#checks.x86_64-linux.hook-failure \
                    --no-warn-dirty \
                    -L \
                    "$@"
              '';
            }
          }/bin/run-nixos-tests";
        };
    };
}
