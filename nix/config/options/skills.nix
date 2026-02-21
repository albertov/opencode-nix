{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.skills = mkOption {
    type = types.nullOr (
      types.submodule {
        options = {
          paths = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
            description = "Local directory paths containing skill definitions. Paths are relative to the project root.";
            example = [ "./my-skills" ];
          };
          urls = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
            description = "URLs to fetch remote skill packs from. Each URL should point to a skill pack JSON manifest.";
            example = [ "https://skills.example.com/pack.json" ];
          };
        };
      }
    );
    default = null;
    description = "Skill loading configuration for extending agent capabilities with domain-specific knowledge.";
  };
}
