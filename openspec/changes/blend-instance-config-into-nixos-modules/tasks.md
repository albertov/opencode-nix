# Tasks — blend-instance-config-into-nixos-modules

## Bead 1: Remove `$schema` from Nix option surface and auto-inject in JSON output

**Traces:** nix-config-module/Root scalar options (MODIFIED), mk-opencode-config/Automatic schema URL injection (ADDED)

### Files to change

- `nix/config/options/top-level.nix` — remove the `"$schema"` option definition
- `nix/config/lib.nix` — in `mkOpenCodeConfig`, inject `"$schema" = "https://opencode.ai/config.json"` into the JSON output after null-filtering, before serialization
- `examples/chief-coding-assistant/default.nix` — remove `opencode."$schema"` setting
- `nix/tests/sample-port.nix` — remove `"$schema"` from test fixture if present
- Any other test/example files that set `$schema`

### Tasks

- [ ] Remove `"$schema"` option from `nix/config/options/top-level.nix`
- [ ] In `nix/config/lib.nix`, add `"$schema"` injection in the `mkOpenCodeConfig` pipeline (after cleanConfig, before writeText)
- [ ] Update all examples that set `opencode."$schema"` to remove that line
- [ ] Update all test fixtures that set `"$schema"` to remove it
- [ ] Verify `nix flake check` passes — standalone config generation still works, generated JSON includes `$schema`

---

## Bead 2: Add `config` submodule and `configFile` to instance options, replace `opencodeCfg`

**Traces:** opencode-nixos-multi-instance-service/Per-instance ergonomic config submodule (ADDED), opencode-nixos-multi-instance-service/Per-instance configFile override (ADDED), mk-opencode-config/Reusable config evaluation for NixOS integration (ADDED)

### Files to change

- `nix/config/lib.nix` — add a companion function (or extend `mkOpenCodeConfig`) to accept an already-evaluated config attrset and produce JSON, reusing the same null-filtering and schema-injection pipeline
- `nix/nixos/module.nix` — add `config` submodule option (reusing `nix/config/default.nix` options without `opencode.` prefix) and `configFile` option (types.path, defaulting to generated JSON from `config`); remove `opencodeCfg` entirely

### Tasks

- [ ] In `nix/config/lib.nix`, add `mkOpenCodeConfigFromAttrs` (or similar) that takes a raw config attrset → normalizes → cleans → injects `$schema` → `writeText`; shares pipeline with `mkOpenCodeConfig`
- [ ] In `nix/nixos/module.nix`, define `config` option as a submodule type importing `nix/config/default.nix`, with adapter to strip `opencode.` prefix so users write `config.model` not `config.opencode.model`
- [ ] In `nix/nixos/module.nix`, define `configFile` option as `types.path` with default that evaluates `config` through the new config-from-attrs pipeline
- [ ] Remove `opencodeCfg` option entirely from `instanceOpts` (unreleased, no deprecation needed)
- [ ] Update `mkInstanceConfig` to use `configFile` directly
- [ ] Ensure `services.opencode.defaults` merges `config` values properly with per-instance `config` via NixOS module merge semantics
- [ ] Verify `nix flake check` passes — instances with `config` produce correct JSON, `configFile` default works

---

## Bead 3: Update examples, tests, and docs

**Traces:** nix-config-module/NixOS service integration compatibility (MODIFIED), opencode-nixos-multi-instance-service/Per-instance service unit generation (MODIFIED)

### Files to change

- `examples/simple-coding-assistant/default.nix` — replace `opencodeCfg` with `config`
- `nix/nixos/tests/env-and-config.nix` — replace `opencodeCfg` with `config`
- `nix/nixos/tests/hook-ordering.nix` — replace `opencodeCfg` with `config`
- `nix/nixos/tests/eval-tests.nix` — add eval tests for new `config`/`configFile` behavior
- `nix/nixos/README.md` — update options table (replace `opencodeCfg` with `config`/`configFile`)
- `AGENTS.md` — update key module options list

### Tasks

- [ ] Replace `opencodeCfg` with `config` in `examples/simple-coding-assistant/default.nix`
- [ ] Replace `opencodeCfg` with `config` in VM test configs (`env-and-config.nix`, `hook-ordering.nix`)
- [ ] Add eval tests: config submodule produces correct JSON, configFile override works
- [ ] Update `nix/nixos/README.md` options table and usage examples
- [ ] Update `AGENTS.md` key module options list to replace `opencodeCfg` with `config`/`configFile`
- [ ] Final `nix flake check` — all eval tests, schema validation, and VM tests pass
