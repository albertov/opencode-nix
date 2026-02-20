{ lib, ... }:

let
  inherit (lib) mkOption types;

  formatterSubmodule = types.submodule {
    options = {
      command = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Command to run the formatter";
        example = [ "nixfmt" ];
      };
      extensions = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "File extensions this formatter handles";
        example = [ ".nix" ];
      };
      disabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Disable this specific formatter";
      };
      environment = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        description = "Environment variables for the formatter process";
      };
    };
  };
in
{
  options.opencode.formatter = mkOption {
    type = types.nullOr (types.either (types.enum [ false ]) (types.attrsOf formatterSubmodule));
    default = null;
    description = "Formatter configurations. Set to false to disable all formatters.";
  };
}
