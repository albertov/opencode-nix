# mk-opencode-config

Library function that evaluates a list of Nix modules and produces a derivation containing the `opencode.json` file.

## ADDED Requirements

### Requirement: Function signature and behavior

`pkgs.lib.opencode.mkOpenCodeConfig` SHALL accept a list of Nix modules and produce a derivation containing a valid `opencode.json` file. The function SHALL remain the canonical standalone entrypoint for generating opencode configuration from Nix modules. The function SHALL be system-aware, using `pkgs` to resolve any system-dependent values. The implementation MUST evaluate against the overlay-selected package set and MUST NOT hardcode `x86_64-linux`.

#### Scenario: Overlay exposes helper namespace

- **WHEN** nixpkgs is instantiated with this flake's overlay
- **THEN** `pkgs.lib.opencode.mkOpenCodeConfig` exists and is callable.

#### Scenario: Overlay namespace is canonical helper interface

- **WHEN** consumers use helper functions from this flake
- **THEN** the supported entrypoint is `pkgs.lib.opencode.*` via overlayed nixpkgs
- **AND** consumers are not required to use flake-level helper entrypoints.

#### Scenario: Standalone config generation unchanged

- **WHEN** `pkgs.lib.opencode.mkOpenCodeConfig [ { opencode.model = "sonnet"; } ]` is called
- **THEN** the result SHALL be a derivation whose output is a valid JSON file containing `"model": "sonnet"`

#### Scenario: Basic invocation

- **WHEN** called as:
```nix
pkgs.lib.opencode.mkOpenCodeConfig [
  { theme = "catppuccin"; logLevel = "debug"; }
]
```
- **THEN** it returns a derivation that, when built, produces an `opencode.json` file.

#### Scenario: Output is valid JSON

- **WHEN** the derivation is built
- **THEN** `$out` contains a valid JSON file parseable by `builtins.fromJSON` and any JSON parser.

#### Scenario: Multiple modules composed

- **WHEN** called with multiple modules:
```nix
pkgs.lib.opencode.mkOpenCodeConfig [
  { theme = "dark"; }
  { logLevel = "info"; agent.plan.steps = 50; }
  ./my-opencode-module.nix
]
```
- **THEN** all modules are merged via `lib.evalModules` and the output JSON reflects the merged config.

#### Scenario: Module files accepted

- **WHEN** a list entry is a path to a `.nix` file
- **THEN** it is imported as a module (standard Nix module system behavior).

#### Scenario: System-aware package set selection

- **WHEN** `pkgs.lib.opencode.mkOpenCodeConfig` is evaluated for a supported non-x86_64 system (for example `aarch64-linux` or `aarch64-darwin`)
- **THEN** it resolves package dependencies from the active overlay package set (`final`) for that system
- **AND** evaluation does not depend on `nixpkgs.legacyPackages.x86_64-linux`.

---

### Requirement: Null/unset filtering

Unset options must not appear in the JSON output.

#### Scenario: Only set values appear

WHEN a module sets only `{ theme = "dark"; }`
THEN the JSON contains only `{"theme":"dark"}` — no other keys.

#### Scenario: Deeply nested filtering

WHEN a module sets `{ agent.plan.model = "anthropic/claude-sonnet-4-20250514"; }`
THEN the JSON contains `{"agent":{"plan":{"model":"anthropic/claude-sonnet-4-20250514"}}}` — no sibling keys in `plan`, no sibling agents.

#### Scenario: Empty attrsets removed

WHEN filtering leaves an empty object (e.g., agent with no set fields)
THEN the empty object is omitted from the JSON entirely.

---

### Requirement: Special value handling

Certain fields accept non-standard JSON values that must be preserved.

#### Scenario: Boolean false for lsp/formatter

WHEN a module sets `{ lsp = false; }`
THEN the JSON contains `"lsp":false` (not an empty object, not omitted).

#### Scenario: Provider timeout false

WHEN a module sets `{ provider.x.options.timeout = false; }`
THEN the JSON contains `"timeout":false`.

#### Scenario: Autoupdate string-or-boolean

WHEN a module sets `{ autoupdate = "notify"; }`
THEN the JSON contains `"autoupdate":"notify"`.

WHEN a module sets `{ autoupdate = true; }`
THEN the JSON contains `"autoupdate":true`.

---

### Requirement: Error on invalid configuration

Invalid configurations must fail at Nix evaluation time, not silently produce broken JSON.

#### Scenario: Type mismatch

WHEN a module sets `{ logLevel = 42; }`
THEN Nix evaluation fails with a type error.

#### Scenario: Invalid enum value

WHEN a module sets `{ share = "invalid"; }`
THEN Nix evaluation fails because the value is not in `["manual" "auto" "disabled"]`.

#### Scenario: Unknown top-level key

WHEN a module sets `{ nonExistentOption = true; }`
THEN Nix evaluation fails with an "option does not exist" error (freeformType is NOT used at root).

---

### Requirement: Automatic schema URL injection

Every generated `opencode.json` SHALL contain `"$schema": "https://opencode.ai/config.json"` as a top-level key. The `$schema` value is injected at the serialization layer after module evaluation and null-filtering — it is NOT a user-facing Nix option and MUST NOT appear in the option definitions.

#### Scenario: Schema present in generated JSON

- **WHEN** `pkgs.lib.opencode.mkOpenCodeConfig [ { opencode.model = "sonnet"; } ]` is built
- **THEN** the output JSON contains `"$schema": "https://opencode.ai/config.json"` alongside `"model": "sonnet"`.

#### Scenario: Schema present in empty config

- **WHEN** `pkgs.lib.opencode.mkOpenCodeConfig [ ]` is built with no modules
- **THEN** the output JSON is exactly `{"$schema":"https://opencode.ai/config.json"}`.

#### Scenario: Schema is not a settable option

- **WHEN** a module attempts `{ opencode."$schema" = "something"; }`
- **THEN** Nix evaluation SHALL fail because `$schema` is not a declared option.

---

### Requirement: Reusable config evaluation for NixOS integration

A companion function `pkgs.lib.opencode.mkOpenCodeConfigFromAttrs` SHALL accept an already-evaluated config attribute set (not a module list) and produce a derivation containing `opencode.json`. This function SHALL share the same null-filtering, schema-injection, and serialization pipeline as `mkOpenCodeConfig`, ensuring byte-identical output for equivalent inputs. This enables the NixOS service module to pass pre-merged config attributes without re-evaluating through the module system.

#### Scenario: Companion function produces identical output

- **WHEN** `mkOpenCodeConfigFromAttrs { model = "sonnet"; }` is built
- **THEN** the output JSON is identical to `mkOpenCodeConfig [ { opencode.model = "sonnet"; } ]`.

#### Scenario: Companion function applies null filtering and schema injection

- **WHEN** `mkOpenCodeConfigFromAttrs { model = "sonnet"; theme = null; }` is built
- **THEN** the output JSON contains `"model": "sonnet"` and `"$schema": "https://opencode.ai/config.json"` but not `"theme"`.
