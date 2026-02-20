{
  description = "Nix module system for generating opencode.json config files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opencode-src = {
      url = "github:sst/opencode";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, opencode-src }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkLib = pkgs: import ./nix/config/lib.nix { inherit pkgs; lib = pkgs.lib; };
    in
    {
      lib = {
        mkOpenCodeConfig = modules:
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
          in
          (mkLib pkgs).mkOpenCodeConfig modules;

        wrapOpenCode = { name ? "opencode", modules, opencode }:
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
          in
          (mkLib pkgs).wrapOpenCode { inherit name modules opencode; };
      };

      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = mkLib pkgs;
        in
        {
          empty-config = pkgs.runCommandNoCC "empty-config-test" {} ''
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
            inherit pkgs opencode-src;
            inherit (pkgs) lib;
            mkOpenCodeConfig = lib.mkOpenCodeConfig;
          };
        });
    };
}
