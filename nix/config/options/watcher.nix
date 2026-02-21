{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.watcher = mkOption {
    type = types.nullOr (
      types.submodule {
        options = {
          ignore = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
            description = "Glob patterns for files and directories to exclude from the file watcher. Useful for noisy build artifacts or large directories.";
            example = [
              "*.log"
              "tmp/"
              "node_modules/"
            ];
          };
        };
      }
    );
    default = null;
    description = "File watcher settings. The file watcher tracks project changes to provide context to agents.";
  };
}
