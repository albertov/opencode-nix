{ lib, ... }:

let
  inherit (lib) mkOption types;

  oauthSubmodule = types.submodule {
    options = {
      clientId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "OAuth client ID. If omitted, dynamic client registration (RFC 7591) is attempted.";
      };
      clientSecret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "OAuth client secret, if required by the authorization server.";
      };
      scope = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "OAuth scopes to request during authorization.";
      };
    };
  };

  mcpSubmodule = types.submodule {
    options = {
      type = mkOption {
        type = types.nullOr (
          types.enum [
            "local"
            "remote"
          ]
        );
        default = null;
        description = ''
          MCP server type. 'local' runs a command as a child process communicating via stdio;
          'remote' connects to an HTTP endpoint via SSE/streamable-HTTP transport.
        '';
      };
      # Local MCP fields
      command = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Command and arguments to launch a local MCP server process (only for type = 'local').";
        example = [
          "npx"
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/tmp"
        ];
      };
      environment = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        description = ''
          Environment variables passed to the local MCP server process.
          Values support '{env:VAR}' syntax for runtime substitution.
        '';
        example = {
          GITHUB_TOKEN = "{env:GITHUB_TOKEN}";
        };
      };
      # Remote MCP fields
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "URL endpoint for a remote MCP server (only for type = 'remote').";
        example = "https://api.githubcopilot.com/mcp/";
      };
      headers = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        description = ''
          HTTP headers sent with every request to a remote MCP server.
          Values support '{env:VAR}' syntax for runtime secret injection.
        '';
        example = {
          Authorization = "Bearer {env:MCP_TOKEN}";
        };
      };
      oauth = mkOption {
        type = types.nullOr (types.either (types.enum [ false ]) oauthSubmodule);
        default = null;
        description = ''
          OAuth authentication for remote MCP servers. Set to an attrset with
          clientId/clientSecret/scope fields, or to false to disable OAuth auto-detection.
        '';
      };
      # Shared fields
      enabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Explicitly enable or disable this MCP server. Defaults to true when the server is defined.";
      };
      timeout = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Per-server request timeout in milliseconds. Overrides the global experimental.mcp_timeout.";
      };
    };
  };
in
{
  options.opencode.mcp = mkOption {
    type = types.nullOr (types.attrsOf mcpSubmodule);
    default = null;
    description = ''
      MCP (Model Context Protocol) server configurations keyed by server name.
      MCP servers provide tools that agents can call during their execution.
    '';
  };
}
