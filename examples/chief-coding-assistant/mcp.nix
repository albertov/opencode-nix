# MCP server configuration: Tilth code navigation
{ ... }:

{
  opencode.mcp = {
    tilth = {
      type = "local";
      command = [ "tilth" "--mcp" ];
      enabled = true;
      timeout = 30000;
    };
  };
}
