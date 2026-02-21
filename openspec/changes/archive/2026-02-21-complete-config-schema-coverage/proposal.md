## Why

`opencode-nix` currently validates and generates most of `opencode.json`, but it still cannot express several real-world schema fields used in production configs. This prevents full round-tripping from existing JSONC configs, forces ad hoc workarounds, and blocks our goal of treating the Nix module as a complete, authoritative interface for Opencode configuration.

Achieving 100% schema support now lets teams migrate fully to typed, composable Nix config without losing provider metadata, nested permission semantics, or legacy compatibility flags.

## What Changes

- Add full provider registry modeling for fields currently missing in `opencode.provider.*` (including provider display metadata and model registry metadata used by OpenAI-compatible providers).
- Add hierarchical permission modeling so nested permission structures are representable (for example `external_directory` path rules and per-skill permission maps).
- Add compatibility support for agent fields that exist in upstream schema but are not currently modeled (including `primary` behavior).
- Add schema-parity tests that prove every currently unsupported field can be expressed in Nix, emitted to JSON, and accepted by upstream Zod validation.
- Update examples and docs to remove current limitation notes and demonstrate complete schema coverage.

## Capabilities

### New Capabilities

- `provider-registry-metadata`: Model provider-level and model-level metadata fields (for example `npm`, `name`, and `models` metadata such as limits/modalities/tool flags) so provider definitions can be represented without dropping fields.
- `hierarchical-permissions`: Support nested permission shapes beyond flat tool-to-action maps, including path-scoped external directory policies and scoped skill permissions.
- `agent-compatibility-flags`: Add support for schema-compatible agent flags (for example `primary`) and define normalization/precedence rules with existing mode semantics.
- `schema-parity-validation`: Add parity-focused tests and fixtures proving end-to-end JSON output parity for previously unsupported schema fields.

### Modified Capabilities

- _(none — repository currently has no baseline specs under `openspec/specs/`; this change introduces new capabilities)_

## Impact

- **Affected code**: `nix/config/options/providers.nix`, `nix/config/options/permissions.nix`, `nix/config/options/agents.nix`, JSON cleaning/normalization logic, tests, examples, and docs.
- **Behavioral effect**: Configs that previously required omissions or comments can be fully represented in Nix and emitted losslessly to `opencode.json`.
- **Testing**: Expanded Zod-backed tests for new nested and provider metadata fields, plus parity fixtures for real-world config migration.
- **Compatibility**: Primarily additive; existing configs continue to work, with clearer normalization rules when both legacy and modern agent primary semantics are set.
