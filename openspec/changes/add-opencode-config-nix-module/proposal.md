## Why

Opencode's `opencode.json` config file has 50+ root-level fields, nested sub-structures (agents, providers, MCP servers, keybinds, permissions, LSP servers, formatters, etc.), and strict Zod validation that rejects unknown fields. Hand-editing JSON is error-prone: typos silently break things, there's no completion, no documentation inline, no composability, and no way to share partial configs across projects.

The Nix module system solves all of these: typed options with documentation, defaults, merging of multiple config fragments, and compile-time validation. A `lib.mkOpenCodeConfig` function lets teams compose configs from reusable modules and produces a derivation containing a guaranteed-valid `opencode.json`.

## What Changes

- Add a Nix module that declares every `opencode.json` option as a typed NixOS-style option with documentation and defaults
- Add a `lib.mkOpenCodeConfig` function exposed from the flake that takes a list of modules, evaluates them, and produces a derivation writing `opencode.json`
- Add automated tests (Nix-based) that validate generated JSON against the opencode Zod schema
- Document every option in the module with `description` attributes

## Capabilities

### New Capabilities

- `nix-config-module`: A complete Nix module declaring all opencode.json options (theme, logLevel, username, model, agents, providers, permissions, MCP servers, keybinds, TUI settings, server, skills, LSP, formatters, watcher, compaction, enterprise, experimental) as typed NixOS-style options with defaults and documentation.
- `mk-opencode-config`: A `lib.mkOpenCodeConfig moduleList` function exposed from the flake that evaluates a list of Nix modules and produces a derivation creating a valid `opencode.json` file.
- `config-tests`: Automated Nix-based tests that exercise the module system — minimal config, full config, module merging, type validation errors, and JSON output validation against the opencode Zod schema.
- `ci-workflow`: A GitHub Actions workflow that runs `nix flake check` on every push/PR, using Cachix for binary caching to keep CI fast.
- `wrap-opencode`: A `lib.wrapOpenCode { name, modules }` function that produces a derivation wrapping the opencode binary so it runs with a Nix-generated config. Uses Nix's `makeWrapper`/`symlinkJoin` to set `--config` or the appropriate environment, yielding a self-contained `opencode` executable that includes the generated `opencode.json`.

### Modified Capabilities

_(none — this is purely additive)_

## Impact

- **New files**: Nix module definition(s), test files, flake output additions, `.github/workflows/check.yml`
- **Flake outputs**: New `lib.mkOpenCodeConfig` function; `checks.<system>` for Zod validation tests
- **Dependencies**: `nixpkgs.lib` for `mkOption`, `types`, `evalModules`; `opencode-src` flake input (non-flake, raw source) for Zod schema validation in tests
- **Existing code**: No changes to the opencode source; no changes to existing Nix build derivations
- **Users**: Can `nix eval` or `nix build` to produce `opencode.json` with full type checking and documentation via `nixos-option`-style tooling
