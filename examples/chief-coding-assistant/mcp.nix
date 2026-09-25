# MCP server configuration: Tilth code navigation
#
# This module configures the tilth MCP server for smart code navigation.
# Tilth is automatically provided via the Nix flake's overlay (pkgs.tilth).
#
# For NixOS services, add pkgs.tilth to services.opencode.instances.<name>.path if needed.
# For standalone use without the overlay, ensure tilth is installed via cargo/npm/nix profile.
{ pkgs, lib, ... }:

{
  opencode.mcp = {
    tilth = {
      type = "local";
      # Use lib.getExe to get the executable path from the tilth package
      command = [
        (lib.getExe pkgs.tilth)
        "--mcp"
      ];
      enabled = true;
      timeout = 30000;
    };
  };
}
