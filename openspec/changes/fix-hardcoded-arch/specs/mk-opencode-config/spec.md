## MODIFIED Requirements

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
