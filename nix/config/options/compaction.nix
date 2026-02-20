{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.compaction = mkOption {
    type = types.nullOr (types.submodule {
      options = {
        auto = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Auto-compact when context window is full (default: true)";
        };
        prune = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Prune old tool outputs during compaction (default: true)";
        };
        reserved = mkOption {
          type = types.nullOr (types.ints.between 0 2147483647);
          default = null;
          description = "Token count reserved for compaction output";
        };
      };
    });
    default = null;
    description = "Context compaction settings";
  };
}
