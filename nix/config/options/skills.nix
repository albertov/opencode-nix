{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.skills = mkOption {
    type = types.nullOr (types.submodule {
      options = {
        paths = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "Local skill directory paths";
          example = [ "./my-skills" ];
        };
        urls = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "URLs to fetch skill packs from";
          example = [ "https://skills.example.com/pack.json" ];
        };
      };
    });
    default = null;
    description = "Skill loading configuration";
  };
}
