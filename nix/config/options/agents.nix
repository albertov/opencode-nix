{ lib, ... }:

let
  inherit (lib) mkOption types;

  permissionType = types.attrsOf (types.enum [ "allow" "ask" "deny" ]);

  agentSubmodule = types.submodule {
    options = {
      model = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Model for this agent. Format: 'provider/model-id'.";
        example = "anthropic/claude-sonnet-4-20250514";
      };
      variant = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Model variant identifier, used to select a specific version or configuration of the model.";
      };
      prompt = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          System prompt text for this agent. Supports runtime template syntax:
          - '{env:VAR}' — substituted with the value of environment variable VAR at runtime
          - '{file:path}' — substituted with the contents of the file at path at runtime

          When using Nix, you can embed store paths for build-time resolution:
          the file will be copied to the Nix store and the literal path is baked in.
        '';
        example = lib.literalExpression ''
          # Literal env/file reference (passed to opencode at runtime)
          "{env:SYSTEM_PROMPT}"

          # Nix store path (evaluated at build time, literal path at runtime)
          "{file:''${./prompts/plan.md}}"
        '';
      };
      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Human-readable description shown next to the agent name in the TUI agent picker.";
      };
      temperature = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sampling temperature (0.0 = deterministic, 1.0 = maximum randomness). Controls response creativity.";
      };
      top_p = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Top-p (nucleus) sampling parameter. Only tokens within the top cumulative probability p are considered.";
      };
      steps = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Maximum number of tool-call steps the agent may take in a single turn before stopping.";
      };
      mode = mkOption {
        type = types.nullOr (types.enum [ "subagent" "primary" "all" ]);
        default = null;
        description = ''
          Agent availability mode. 'primary' — available as a top-level agent;
          'subagent' — only callable by other agents; 'all' — available in both contexts.
        '';
      };
      hidden = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "When true, hides this agent from the TUI agent picker while still allowing programmatic use.";
      };
      disable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "When true, completely disables this agent. It will not be loaded or available.";
      };
      color = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Display color for this agent in the TUI. Accepts hex colors (e.g. '#FF5500') or named colors.";
        example = "#FF5500";
      };
      permission = mkOption {
        type = types.nullOr permissionType;
        default = null;
        description = "Per-agent permission overrides. Maps tool names to 'allow', 'ask', or 'deny'.";
        example = { bash = "ask"; edit = "allow"; };
      };
      options = mkOption {
        type = types.nullOr (types.attrsOf types.anything);
        default = null;
        description = "Arbitrary provider-specific options passed through to the model API (e.g. reasoning effort, stop sequences).";
      };
    };
  };
in
{
  options.opencode.agent = mkOption {
    type = types.nullOr (types.attrsOf agentSubmodule);
    default = null;
    description = ''
      Agent configurations keyed by agent name. Built-in agents include 'plan' and 'build';
      custom agent names create new agents. Each agent can override model, prompt, and behavior.
    '';
  };
}
