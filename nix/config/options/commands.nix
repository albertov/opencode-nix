{ lib, ... }:

let
  inherit (lib) mkOption types;

  commandSubmodule = types.submodule {
    options = {
      template = mkOption {
        type = types.str;
        description = "Prompt template text sent to the agent when this slash command is invoked.";
      };
      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Human-readable description shown in the TUI command list and help.";
      };
      agent = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Agent name to handle this command. If unset, uses the current session agent.";
      };
      model = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Model override for this command. Format: 'provider/model-id'.";
      };
      subtask = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "When true, runs the command as a subtask within the current session rather than replacing it.";
      };
    };
  };
in
{
  options.opencode.command = mkOption {
    type = types.nullOr (types.attrsOf commandSubmodule);
    default = null;
    description = ''
      Custom slash commands keyed by command name (e.g. 'review', 'test').
      Users invoke them as /command-name in the TUI.
    '';
  };
}
