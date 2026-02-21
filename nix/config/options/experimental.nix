{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.experimental = mkOption {
    type = types.nullOr (
      types.submodule {
        options = {
          disable_paste_summary = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "When true, disables automatic summarization of pasted content in the TUI input.";
          };
          batch_tool = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "When true, enables the batch tool which allows agents to execute multiple tool calls in parallel.";
          };
          openTelemetry = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "When true, enables OpenTelemetry tracing spans for performance monitoring and debugging.";
          };
          primary_tools = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
            description = "List of tool names restricted to primary agents only. Subagents will not have access to these tools.";
          };
          continue_loop_on_deny = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "When true, the agent loop continues after a tool call is denied instead of stopping.";
          };
          mcp_timeout = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
            description = "Global default timeout in milliseconds for all MCP server requests. Can be overridden per-server.";
          };
        };
      }
    );
    default = null;
    description = "Experimental feature flags. These features may change or be removed in future versions.";
  };
}
