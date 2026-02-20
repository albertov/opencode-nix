{ lib, ... }:

let
  inherit (lib) mkOption types;

  permissionType = types.attrsOf (types.enum [ "allow" "ask" "deny" ]);

  agentSubmodule = types.submodule {
    options = {
      model = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Model for this agent. Format: 'provider/model-id'";
      };
      variant = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Model variant identifier";
      };
      prompt = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "System prompt. Can use '{file:path}' or '{env:VAR}' syntax";
      };
      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Agent description shown in TUI";
      };
      temperature = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sampling temperature (0.0 - 1.0)";
      };
      top_p = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Top-p nucleus sampling";
      };
      steps = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Maximum tool call steps per turn";
      };
      mode = mkOption {
        type = types.nullOr (types.enum [ "subagent" "primary" "all" ]);
        default = null;
        description = "Agent availability mode";
      };
      hidden = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Hide agent from TUI agent list";
      };
      disable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Disable this agent entirely";
      };
      color = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Agent color (hex '#FF5500' or named color)";
      };
      permission = mkOption {
        type = types.nullOr permissionType;
        default = null;
        description = "Per-agent permission overrides";
      };
      options = mkOption {
        type = types.nullOr (types.attrsOf types.anything);
        default = null;
        description = "Arbitrary provider-specific agent options";
      };
    };
  };
in
{
  options.opencode.agent = mkOption {
    type = types.nullOr (types.attrsOf agentSubmodule);
    default = null;
    description = "Agent configurations keyed by agent name (e.g. 'plan', 'build', custom names)";
  };
}
