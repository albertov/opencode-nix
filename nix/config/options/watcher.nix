{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.watcher = mkOption {
    type = types.nullOr (types.submodule {
      options = {
        ignore = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "Glob patterns for files to ignore in the file watcher";
          example = [ "*.log" "tmp/" ];
        };
      };
    });
    default = null;
    description = "File watcher settings";
  };
}
