## Why

Defining per-instance OpenCode configuration in NixOS currently requires wiring standalone module lists, which is less ergonomic than the rest of the `services.opencode.instances.<name>` interface. We should make isolated instance configuration feel native to NixOS modules while still preserving standalone config generation for non-service use.

## What Changes

- Add `services.opencode.instances.<name>.config` as an ergonomic attribute-set entrypoint that uses the existing OpenCode config module definition directly.
- Add `services.opencode.instances.<name>.configFile` for explicit JSON file overrides; when unset, default it to the generated JSON produced from `config`.
- Define per-instance config source precedence: explicit `configFile` wins; otherwise generated JSON from `config` is used.
- Keep standalone config generation workflows functional (`pkgs.lib.opencode.mkOpenCodeConfig` and non-service wrapping/invocation paths).
- Remove the need for users to provide `"$schema"` in Nix module input; generate `"$schema"` in emitted JSON automatically.
- **BREAKING**: remove `"$schema"` from the Nix option surface so configuration is schema-free on the Nix side.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `opencode-nixos-multi-instance-service`: extend instance options with ergonomic `config` and `configFile`, and define override/default behavior for isolated instances.
- `nix-config-module`: update module option expectations so `"$schema"` is no longer part of user-authored Nix config, while JSON output still contains it.
- `mk-opencode-config`: preserve and clarify standalone (non-service) config generation behavior while introducing the new NixOS integration path.

## Impact

- NixOS service module option definitions and config wiring in `nix/nixos/module.nix`.
- Config option definitions and JSON emission behavior in `nix/config/options/` and related config library code.
- Example modules and tests that currently set `"$schema"` or depend on module-list style service config.
- Check coverage in `nix/tests/` and `nix/nixos/tests/` to validate default generation, override behavior, and non-service compatibility.
