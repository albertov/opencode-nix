{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode = {
    "$schema" = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "JSON schema URL for editor completion and validation of opencode.json files.";
      example = "https://opencode.ai/config.json";
    };
    theme = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "UI color theme for the TUI. Built-in themes include 'catppuccin', 'dark', and 'light'.";
      example = "catppuccin";
    };
    logLevel = mkOption {
      type = types.nullOr (
        types.enum [
          "DEBUG"
          "INFO"
          "WARN"
          "ERROR"
        ]
      );
      default = null;
      description = "Logging verbosity level. Must be uppercase: DEBUG, INFO, WARN, or ERROR.";
    };
    model = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Default model for all agents. Format: 'provider/model-id'.
        Supports '{env:VAR}' syntax to read the value from an environment variable at runtime.
      '';
      example = "anthropic/claude-sonnet-4-20250514";
    };
    small_model = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Model used for lightweight tasks (e.g. compaction summaries). Format: 'provider/model-id'.
      '';
      example = "anthropic/claude-haiku-4-5";
    };
    username = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Display name shown in the TUI header and session metadata.";
    };
    snapshot = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "When true, opencode creates a snapshot of files before editing them, enabling revert.";
    };
    share = mkOption {
      type = types.nullOr (
        types.enum [
          "manual"
          "auto"
          "disabled"
        ]
      );
      default = null;
      description = ''
        Controls conversation session sharing. 'manual' lets users share on demand,
        'auto' shares automatically, and 'disabled' turns sharing off entirely.
      '';
    };
    autoupdate = mkOption {
      type = types.nullOr (types.either types.bool (types.enum [ "notify" ]));
      default = null;
      description = ''
        Auto-update behavior. true: update silently; false: never update;
        'notify': prompt the user when an update is available.
      '';
    };
    default_agent = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of the default primary agent to use when starting a new session.";
    };
    instructions = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        File glob patterns for additional instruction files loaded at session start.
        Paths are relative to the project root.
      '';
      example = [
        "./CLAUDE.md"
        "./.opencode/*.md"
      ];
    };
    plugin = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "Plugin npm package names or local paths. Plugins extend opencode with custom tools and commands.";
      example = [ "@my-org/opencode-plugin-lint" ];
    };
    disabled_providers = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "List of provider IDs to disable. Disabled providers are hidden from model selection.";
      example = [
        "openai"
        "google"
      ];
    };
    enabled_providers = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        Allowlist of provider IDs. When set, only these providers are available;
        all others are implicitly disabled.
      '';
      example = [ "anthropic" ];
    };
  };
}
