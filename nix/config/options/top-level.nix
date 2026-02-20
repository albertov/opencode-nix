{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode = {
    "$schema" = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "JSON schema URL for editor completion. Usually 'https://opencode.ai/config.json'";
      example = "https://opencode.ai/config.json";
    };
    theme = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "UI theme name (e.g. 'catppuccin', 'dark', 'light')";
      example = "catppuccin";
    };
    logLevel = mkOption {
      type = types.nullOr (types.enum [ "debug" "info" "warn" "error" "fatal" "trace" ]);
      default = null;
      description = "Log verbosity level";
    };
    model = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default model for all agents. Format: 'provider/model-id'";
      example = "anthropic/claude-sonnet-4-20250514";
    };
    small_model = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Model for lightweight tasks. Format: 'provider/model-id'";
    };
    username = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Display name shown in the TUI";
    };
    snapshot = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Enable file snapshotting before edits";
    };
    share = mkOption {
      type = types.nullOr (types.enum [ "manual" "auto" "disabled" ]);
      default = null;
      description = "Share conversation sessions: manual, auto, or disabled";
    };
    autoupdate = mkOption {
      type = types.nullOr (types.either types.bool (types.enum [ "notify" ]));
      default = null;
      description = "Auto-update behavior: true (update), false (skip), 'notify' (prompt)";
    };
    default_agent = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default primary agent name";
    };
    instructions = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "File glob patterns for additional instruction files";
      example = [ "./prompts/*.md" ];
    };
    plugin = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "Plugin npm package names or paths";
    };
    disabled_providers = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "Provider IDs to disable";
    };
    enabled_providers = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "Provider IDs to enable (if set, others are disabled)";
    };
  };
}
