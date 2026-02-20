{ lib, ... }:

let
  inherit (lib) mkOption types;

  commandSubmodule = types.submodule {
    options = {
      template = mkOption {
        type = types.str;
        description = "Command template text sent to the agent";
      };
      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Human-readable description shown in TUI";
      };
      agent = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Agent to use for this command";
      };
      model = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Model override for this command";
      };
      subtask = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Run as a subtask of the current session";
      };
    };
  };
in
{
  options.opencode.command = mkOption {
    type = types.nullOr (types.attrsOf commandSubmodule);
    default = null;
    description = "Custom slash commands keyed by command name";
  };
}
