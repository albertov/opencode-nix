# mk-opencode-config

Library function that evaluates a list of Nix modules and produces a derivation containing the `opencode.json` file.

## ADDED Requirements

### Requirement: Function signature and return type

`pkgs.lib.opencode.mkOpenCodeConfig` accepts a list of modules and returns a derivation. The implementation MUST evaluate against the overlay-selected package set and MUST NOT hardcode `x86_64-linux`.

#### Scenario: Overlay exposes helper namespace

- **WHEN** nixpkgs is instantiated with this flake's overlay
- **THEN** `pkgs.lib.opencode.mkOpenCodeConfig` exists and is callable.

#### Scenario: Overlay namespace is canonical helper interface

- **WHEN** consumers use helper functions from this flake
- **THEN** the supported entrypoint is `pkgs.lib.opencode.*` via overlayed nixpkgs
- **AND** consumers are not required to use flake-level helper entrypoints.

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
