{ lib, ... }:

let
  inherit (lib) mkOption types;

  formatterSubmodule = types.submodule {
    options = {
      command = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Command and arguments to run the formatter. The formatter receives file content via stdin and writes to stdout.";
        example = [ "nixfmt" ];
      };
      extensions = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "File extensions this formatter applies to. Used to match files automatically.";
        example = [ ".nix" ];
      };
      disabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "When true, disables this specific formatter without removing its configuration.";
      };
      environment = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        description = "Environment variables passed to the formatter process.";
      };
    };
  };
in
{
  options.opencode.formatter = mkOption {
    type = types.nullOr (types.either (types.enum [ false ]) (types.attrsOf formatterSubmodule));
    default = null;
    description = ''
      Formatter configurations keyed by formatter name.
      Set to false to disable all formatters entirely.
    '';
  };
}
