# opencode-nix

Nix module system for generating [opencode](https://github.com/sst/opencode) config files (`opencode.json`).

## Quick Start

```nix
# flake.nix
{
  inputs = {
    ocnix.url = "github:your-org/ocnix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opencode.url = "github:anomalyco/opencode";
  };

  outputs = { self, nixpkgs, ocnix, opencode, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux.extend ocnix.overlays.default;
    in {
      packages.x86_64-linux.my-opencode = pkgs.lib.opencode.wrapOpenCode {
        name = "my-opencode";
        modules = [
          {
            opencode.theme = "catppuccin";
            opencode.model = "anthropic/claude-sonnet-4-5";
          }
        ];
        opencode = opencode.packages.x86_64-linux.default;
      };
    };
}
```

## Overlay Usage

The flake exposes `overlays.default` which extends `pkgs.lib` with opencode helpers:

```nix
# flake.nix (consumer)
{
  inputs.ocnix.url = "github:your-org/ocnix";
  outputs = { self, nixpkgs, ocnix, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux.extend ocnix.overlays.default;
    in {
      packages.x86_64-linux.my-opencode = pkgs.lib.opencode.wrapOpenCode {
        name = "my-opencode";
        modules = [ { theme = "dark"; } ];
        opencode = <your-opencode-package>;
      };
    };
}
```

Functions available via `pkgs.lib.opencode`:

| Function | Description |
|----------|-------------|
| `mkOpenCodeConfig modules` | Generate opencode.json derivation from NixOS-style modules |
| `wrapOpenCode { name, modules, opencode }` | Wrap opencode binary with generated config |

## NixOS Integration

Import the module into your NixOS host configuration:

```nix
# flake.nix
{
  inputs = {
    ocnix.url = "github:your-org/ocnix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opencode.url = "github:sst/opencode";
  };

  outputs = { self, nixpkgs, ocnix, opencode, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Apply the overlay so pkgs.opencode resolves inside the module
        { nixpkgs.overlays = [ ocnix.overlays.default ]; }
        # Import the NixOS module
        ocnix.nixosModules.opencode
        # Your host config
        ./hosts/my-host.nix
      ];
      specialArgs = { inherit opencode; };
    };
  };
}
```

Then in your host config:

```nix
# hosts/my-host.nix
{ pkgs, opencode, ... }:
{
  services.opencode = {
    enable = true;
    instances = {
      my-project = {
        directory = "/srv/my-project";
        listen.port = 8787;
        package = opencode.packages.${pkgs.system}.default;
      };
    };
  };
}
```

> **Note:** `nixosModules.default` is an alias for `nixosModules.opencode` - both import the same module.

## NixOS Multi-Instance Service

See [`nix/nixos/README.md`](nix/nixos/README.md) for the full NixOS module reference.

## Running Tests

### Unit / eval tests (all platforms)

```bash
nix flake check
```

Runs on every `nix flake check`:
- `empty-config` — empty module produces `{}`
- `wrap-opencode-type` — theme field present in output
- `field-output-check` — multi-field output correct
- `config-zod-tests` — generated configs pass upstream Zod schema
- `overlay-mkOpenCodeConfig` — overlay API resolves correctly
- `overlay-wrapOpenCode` — overlay wrapOpenCode resolves correctly
- `nixos-module-eval` — NixOS module option types and unit rendering

### NixOS VM integration tests (Linux + KVM only)

Build and run individual VM tests:

```bash
# Multi-instance lifecycle
nix build .#nixosTests.multi-instance

# Filesystem sandbox and cross-instance isolation
nix build .#nixosTests.sandbox-isolation

# Setup service idempotence + lifecycle hooks
nix build .#nixosTests.setup-idempotence

# Environment variables, environmentFile, config symlink
nix build .#nixosTests.env-and-config

# Outbound network policy and blocked-attempt logging
nix build .#nixosTests.network-policy

# Unix socket allowlist with PostgreSQL (demonstrates sandbox.unixSockets.allow)
nix build .#nixosTests.postgres-socket
```

These tests use QEMU VMs and require KVM. On a NixOS host:

```bash
# Run a single test with verbose output
nix build .#nixosTests.multi-instance -L

# Run all VM tests in parallel with verbose output
nix build \
  .#nixosTests.multi-instance \
  .#nixosTests.network-policy \
  .#nixosTests.sandbox-isolation \
  .#nixosTests.setup-idempotence \
  .#nixosTests.env-and-config \
  .#nixosTests.postgres-socket \
  -L
```

```bash
# Or use the flake app (x86_64-linux only)
nix run .#run-nixos-tests
```

VM tests are included in `nix flake check` on x86_64-linux (requires KVM).

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
myConfig = pkgs.lib.opencode.mkOpenCodeConfig [
  ./team-base.nix
  ./mcp-servers.nix
  ./personal.nix
];
```

## Options Reference

All `opencode.json` fields are available as typed Nix options with descriptions,
examples, and type checking. The module provides **complete schema coverage**, including:

- **Provider registry metadata** — `npm`, `name`, and per-model `models` registry (capabilities, token limits, modalities)
- **Hierarchical permission maps** — `external_directory` path-glob rules and `skill` sub-permissions
- **Agent compatibility fields** — `primary` flag with automatic `mode` normalization

See the option files for full documentation:

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
