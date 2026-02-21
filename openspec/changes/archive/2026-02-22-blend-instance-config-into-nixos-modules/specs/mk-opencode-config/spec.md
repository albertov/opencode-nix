## MODIFIED Requirements

### Requirement: Function signature and behavior

`pkgs.lib.opencode.mkOpenCodeConfig` SHALL accept a list of Nix modules and produce a derivation containing a valid `opencode.json` file. The function SHALL remain the canonical standalone entrypoint for generating opencode configuration from Nix modules. The function SHALL be system-aware, using `pkgs` to resolve any system-dependent values.

#### Scenario: Standalone config generation unchanged

- **WHEN** `pkgs.lib.opencode.mkOpenCodeConfig [ { opencode.model = "sonnet"; } ]` is called
- **THEN** the result SHALL be a derivation whose output is a valid JSON file containing `"model": "sonnet"`

#### Scenario: System-aware evaluation

- **WHEN** `mkOpenCodeConfig` is called with modules referencing `pkgs`
- **THEN** the evaluation SHALL use the package set from the overlay-applied `pkgs`

### Requirement: Null and unset value filtering

The generated JSON SHALL only include values that were explicitly set. Null option values and empty attribute sets SHALL be filtered out recursively before serialization.

#### Scenario: Unset optional values omitted

- **WHEN** a module sets `opencode.model = "sonnet"` but leaves `opencode.theme` unset (null)
- **THEN** the generated JSON SHALL contain `"model": "sonnet"` but SHALL NOT contain a `"theme"` key

#### Scenario: Empty nested objects pruned

- **WHEN** all sub-options of a nested section (e.g., `opencode.tui`) are null or unset
- **THEN** the generated JSON SHALL NOT contain the `"tui"` key at all

## ADDED Requirements

### Requirement: Automatic schema URL injection

`mkOpenCodeConfig` SHALL inject `"$schema": "https://opencode.ai/config.json"` into the generated JSON output. This injection SHALL happen after module evaluation and null filtering, at the serialization step. The `$schema` key SHALL NOT be part of the module option definitions.

#### Scenario: Schema URL present in standalone output

- **WHEN** `mkOpenCodeConfig [ { opencode.model = "sonnet"; } ]` generates JSON
- **THEN** the output SHALL contain `"$schema": "https://opencode.ai/config.json"`

#### Scenario: Schema URL present regardless of module content

- **WHEN** `mkOpenCodeConfig` is called with any valid module list (including empty)
- **THEN** the output JSON SHALL always include the `"$schema"` field

### Requirement: Reusable config evaluation for NixOS integration

`mkOpenCodeConfig` (or a companion function) SHALL support being called with the evaluated config attrset from a NixOS submodule, not just a module list. This enables the NixOS instance module to pass the already-evaluated `config` submodule result through the same JSON generation pipeline.

#### Scenario: NixOS module passes evaluated config

- **WHEN** the NixOS instance module evaluates `config` submodule and passes the result to the JSON generation pipeline
- **THEN** the pipeline SHALL produce valid `opencode.json` with the same null-filtering and schema-injection behavior as standalone `mkOpenCodeConfig`

#### Scenario: Both entrypoints produce identical output for same input

- **WHEN** standalone `mkOpenCodeConfig [ { opencode.model = "sonnet"; } ]` and NixOS instance `config.model = "sonnet"` generate JSON
- **THEN** both outputs SHALL be byte-identical (same content, same schema URL, same filtering)
