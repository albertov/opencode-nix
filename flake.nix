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

        wrapOpenCode = _args:
          builtins.throw "wrapOpenCode: not yet implemented";
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
        });
    };
}
