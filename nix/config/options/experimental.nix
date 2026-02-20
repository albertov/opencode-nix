{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.experimental = mkOption {
    type = types.nullOr (types.submodule {
      options = {
        disable_paste_summary = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Disable paste summary generation";
        };
        batch_tool = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Enable the batch tool";
        };
        openTelemetry = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Enable OpenTelemetry tracing spans";
        };
        primary_tools = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "Restrict these tools to primary agents only";
        };
        continue_loop_on_deny = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Continue agent loop when a tool call is denied";
        };
        mcp_timeout = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = "Global MCP request timeout in milliseconds";
        };
      };
    });
    default = null;
    description = "Experimental feature flags";
  };
}
