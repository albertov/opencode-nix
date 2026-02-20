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
          description = "When true (the default), automatically compact conversation history when the context window fills up.";
        };
        prune = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "When true (the default), prune old tool call outputs during compaction to reclaim more context space.";
        };
        reserved = mkOption {
          type = types.nullOr (types.ints.between 0 2147483647);
          default = null;
          description = "Number of tokens reserved in the context window for compaction summary output. Higher values give the compaction model more room.";
        };
      };
    });
    default = null;
    description = "Context compaction settings. Controls how opencode manages long conversations that exceed the model's context window.";
  };
}
