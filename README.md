# opencode-nix

Nix module system for generating [opencode](https://github.com/sst/opencode) config files (`opencode.json`).

## Quick Start

```nix
# flake.nix
{
  inputs = {
    opencode-nix.url = "github:your-org/opencode-nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, opencode-nix }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      myConfig = opencode-nix.lib.mkOpenCodeConfig [
        {
          opencode.theme = "catppuccin";
          opencode.model = "anthropic/claude-sonnet-4-5";
        }
      ];
    in {
      packages.default = myConfig;
    };
}
```

## Functions

### `lib.mkOpenCodeConfig modules`

Takes a list of Nix modules and produces a derivation containing `opencode.json`.
Modules are merged using the NixOS module system — later modules override earlier ones,
and list options (like `instructions`) are concatenated.

### `lib.wrapOpenCode { name, modules, opencode }`

Produces a wrapped opencode binary with the config pre-baked via `OPENCODE_CONFIG`.

## Template Syntax: `{env:VAR}` and `{file:path}`

opencode supports runtime template substitution in string values:

- **`{env:VAR}`** — replaced at runtime with the value of environment variable `VAR`.
  Use this for secrets like API keys to avoid embedding them in config files.
- **`{file:path}`** — replaced at runtime with the contents of the file at `path`.
  Use this for long prompts or dynamic content.

These are **opencode runtime substitutions**, not Nix expressions. They are passed
through literally in the generated JSON and resolved when opencode starts.

```nix
# API key from environment (runtime)
opencode.provider.anthropic.options.apiKey = "{env:ANTHROPIC_API_KEY}";

# System prompt from a file (runtime)
opencode.agent.plan.prompt = "{file:./prompts/plan.md}";

# Nix store path + runtime file: reference (build-time path, runtime read)
opencode.agent.plan.prompt = "{file:${./prompts/plan.md}}";
```

## Module Composition for Team Configs

Modules compose naturally. Split your config into reusable layers:

```nix
# team-base.nix — shared across the team
{
  opencode.model = "anthropic/claude-sonnet-4-5";
  opencode.share = "manual";
  opencode.provider.anthropic.options.apiKey = "{env:ANTHROPIC_API_KEY}";
  opencode.permission = { bash = "allow"; edit = "allow"; };
}
```

```nix
# mcp-servers.nix — MCP tooling layer
{
  opencode.mcp.filesystem = {
    type = "local";
    command = [ "npx" "-y" "@modelcontextprotocol/server-filesystem" "/tmp" ];
  };
  opencode.mcp.github = {
    type = "remote";
    url = "https://api.githubcopilot.com/mcp/";
    headers.Authorization = "Bearer {env:GITHUB_TOKEN}";
  };
}
```

```nix
# personal.nix — individual overrides
{
  opencode.theme = "catppuccin";
  opencode.keybinds.session_new = "ctrl+n";
  opencode.agent.plan.steps = 80;
}
```

```nix
# Compose them:
myConfig = opencode-nix.lib.mkOpenCodeConfig [
  ./team-base.nix
  ./mcp-servers.nix
  ./personal.nix
];
```

## Options Reference

All `opencode.json` fields are available as typed Nix options with descriptions,
examples, and type checking. See the option files for full documentation:

| Section | File |
|---------|------|
| Top-level (theme, model, etc.) | `nix/config/options/top-level.nix` |
| Agents | `nix/config/options/agents.nix` |
| Providers | `nix/config/options/providers.nix` |
| MCP servers | `nix/config/options/mcp.nix` |
| Permissions | `nix/config/options/permissions.nix` |
| Commands | `nix/config/options/commands.nix` |
| TUI | `nix/config/options/tui.nix` |
| Server | `nix/config/options/server.nix` |
| LSP | `nix/config/options/lsp.nix` |
| Formatter | `nix/config/options/formatter.nix` |
| Skills | `nix/config/options/skills.nix` |
| Compaction | `nix/config/options/compaction.nix` |
| Watcher | `nix/config/options/watcher.nix` |
| Experimental | `nix/config/options/experimental.nix` |
| Enterprise | `nix/config/options/enterprise.nix` |
| Keybinds | `nix/config/options/keybinds.nix` |

## CI

[![Check](https://github.com/your-org/opencode-nix/actions/workflows/check.yml/badge.svg)](https://github.com/your-org/opencode-nix/actions/workflows/check.yml)
