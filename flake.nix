{
  description = "Nix module system for generating opencode.json config files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opencode.url = "github:anomalyco/opencode";
    opencode.inputs.nixpkgs.follows = "nixpkgs";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, opencode, systems }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      forAllSystems = f: eachSystem (system: f nixpkgs.legacyPackages.${system});

      mkLib = pkgs: import ./nix/config/lib.nix { inherit pkgs; lib = pkgs.lib; };
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
      };

      checks = forAllSystems (pkgs:
        let
          lib = mkLib pkgs;
          overlayPkgs = pkgs.extend self.overlays.default;
        in
        {
          empty-config = pkgs.runCommand "empty-config-test" {} ''
            config=${lib.mkOpenCodeConfig []}
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

          wrap-opencode-type = pkgs.runCommand "wrap-opencode-type-test" {} ''
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

          field-output-check = pkgs.runCommand "field-output-test" {} ''
            config=${lib.mkOpenCodeConfig [
              { opencode.theme = "catppuccin"; opencode.logLevel = "DEBUG"; }
            ]}
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
            inherit (pkgs) lib;
            mkOpenCodeConfig = lib.mkOpenCodeConfig;
          };

          overlay-mkOpenCodeConfig = overlayPkgs.lib.opencode.mkOpenCodeConfig [];

          overlay-wrapOpenCode = overlayPkgs.lib.opencode.wrapOpenCode {
            modules = [];
            opencode = opencode.packages.${pkgs.system}.default;
          };

          nixos-module-eval = import ./nix/nixos/tests/eval-tests.nix { inherit pkgs; };
        });

      nixosTests = import ./nix/nixos/tests { pkgs = nixpkgs.legacyPackages.x86_64-linux; };

      apps.x86_64-linux.run-nixos-tests =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          type = "app";
          program = "${pkgs.writeShellApplication {
            name = "run-nixos-tests";
            runtimeInputs = [ pkgs.nix ];
            text = ''
              exec nix build \
                .#nixosTests.multi-instance \
                .#nixosTests.network-policy \
                .#nixosTests.sandbox-isolation \
                .#nixosTests.setup-idempotence \
                .#nixosTests.env-and-config \
                .#nixosTests.postgres-socket \
                .#nixosTests.simple-coding-assistant \
                --no-warn-dirty \
                -L \
                "$@"
            '';
          }}/bin/run-nixos-tests";
        };

      # Reusable example modules that can be imported into your own config.
      examples = {
        chief-coding-assistant =
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux.extend self.overlays.default;
          in
          import ./examples/chief-coding-assistant {
            inherit pkgs;
            opencode = opencode.packages.x86_64-linux.default;
            inherit (pkgs.lib.opencode) mkOpenCodeConfig wrapOpenCode;
          };

        simple-coding-assistant = import ./examples/simple-coding-assistant;
      };
    };
}
