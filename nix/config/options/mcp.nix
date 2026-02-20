{ lib, ... }:

let
  inherit (lib) mkOption types;

  mcpSubmodule = types.submodule {
    options = {
      type = mkOption {
        type = types.nullOr (types.enum [ "local" "remote" ]);
        default = null;
        description = "MCP server type: local (command) or remote (URL)";
      };
      # Local MCP fields
      command = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Command to launch local MCP server (type = 'local')";
        example = [ "npx" "my-mcp-tool" ];
      };
      environment = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        description = "Environment variables for the MCP process";
      };
      # Remote MCP fields
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "URL for remote MCP server (type = 'remote')";
      };
      headers = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        description = "HTTP headers for remote MCP requests";
      };
      # Shared fields
      enabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable or disable this MCP server";
      };
      timeout = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "MCP request timeout in milliseconds";
      };
    };
  };
in
{
  options.opencode.mcp = mkOption {
    type = types.nullOr (types.attrsOf mcpSubmodule);
    default = null;
    description = "MCP server configurations keyed by server name";
  };
}
