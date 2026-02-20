{ lib, ... }:

{
  imports = [
    ./options/top-level.nix
    ./options/agents.nix
    ./options/providers.nix
    ./options/mcp.nix
    ./options/permissions.nix
    ./options/commands.nix
    ./options/tui.nix
    ./options/server.nix
    ./options/lsp.nix
    ./options/formatter.nix
    ./options/skills.nix
    ./options/compaction.nix
    ./options/watcher.nix
    ./options/experimental.nix
    ./options/enterprise.nix
    ./options/keybinds.nix
  ];
}
