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

## Network Isolation

### Basic setup example

Enable outbound network restrictions for an opencode instance:

```nix
services.opencode.instances.my-project = {
  directory = "/srv/my-project";
  listen.port = 8787;
  networkIsolation = {
    enable = true;
    outboundAllowCidrs = [
      "10.0.0.0/8"        # internal network
      "192.168.0.0/16"    # VPN range
    ];
  };
};
```

### How it works

- Uses nftables OUTPUT chain rules keyed to the service user's UID
- Traffic to allowed CIDRs passes through; all other outbound is DROPped
- Blocked attempts are logged to the kernel log with prefix `opencode-<name>-blocked`
- Does NOT affect inbound traffic (only outbound from the service process)

### Troubleshooting

**Connection timeouts from the service**

Symptom: service can't reach external APIs (e.g., Anthropic API)

Diagnosis: Check kernel logs for blocked attempts
```bash
journalctl -k | grep opencode-my-project-blocked
```

Fix: Add the required CIDR(s) to `outboundAllowCidrs`

**Checking which rules are active**

```bash
# List current nftables ruleset
sudo nft list table inet opencode-my-project

# Check if your service user's UID is correct
id opencode-my-project
```

**Verifying a CIDR is allowed**

```bash
# Test outbound connectivity as the service user (exit code 7 = refused but reached, 28 = timed out/blocked)
sudo -u opencode-my-project curl --max-time 5 -s http://<target-ip>/
```

**Blocked-attempt log observability**

```bash
# Tail kernel log for blocked attempts in real time
journalctl -k -f | grep opencode-my-project-blocked

# Or check recent blocked attempts
dmesg | grep opencode-my-project-blocked
```

**Common CIDR ranges to allow**

| Service | CIDR |
|---------|------|
| Anthropic API | `0.0.0.0/0` (allow all, disable isolation for cloud APIs) |
| Internal GitLab | your internal IP range |
| Corporate proxy | proxy server IP |

Note: For cloud APIs that use dynamic IPs, consider disabling `networkIsolation` and using filesystem sandboxing (`sandbox.*`) for isolation instead.

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
nix build .#checks.x86_64-linux.multi-instance

# Filesystem sandbox and cross-instance isolation
nix build .#checks.x86_64-linux.sandbox-isolation

# Setup service idempotence + lifecycle hooks
nix build .#checks.x86_64-linux.setup-idempotence

# Environment variables, environmentFile, config symlink
nix build .#checks.x86_64-linux.env-and-config

# Outbound network policy and blocked-attempt logging
nix build .#checks.x86_64-linux.network-policy

# Unix socket allowlist with PostgreSQL (demonstrates sandbox.unixSockets.allow)
nix build .#checks.x86_64-linux.postgres-socket
```

These tests use QEMU VMs and require KVM. On a NixOS host:

```bash
# Run a single test with verbose output
nix build .#checks.x86_64-linux.multi-instance -L

# Run a test interactively via the NixOS test driver
nix run .#checks.x86_64-linux.postgres-socket.driver

# Run all VM tests in parallel with verbose output
nix build \
  .#checks.x86_64-linux.multi-instance \
  .#checks.x86_64-linux.network-policy \
  .#checks.x86_64-linux.sandbox-isolation \
  .#checks.x86_64-linux.setup-idempotence \
  .#checks.x86_64-linux.env-and-config \
  .#checks.x86_64-linux.postgres-socket \
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
