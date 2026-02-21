## MODIFIED Requirements

### Requirement: Function signature

`pkgs.lib.opencode.wrapOpenCode` MUST accept an attrset with `name`, `modules`, and optional `opencode` package.

When `opencode` is omitted, the default package MUST resolve from the active overlay package set for that system, and MUST NOT be hardcoded to `x86_64-linux`.

#### Scenario: Overlay exposes helper namespace

- **WHEN** nixpkgs is instantiated with this flake's overlay
- **THEN** `pkgs.lib.opencode.wrapOpenCode` exists and is callable.

#### Scenario: Overlay namespace is canonical helper interface

- **WHEN** consumers use helper functions from this flake
- **THEN** the supported entrypoint is `pkgs.lib.opencode.*` via overlayed nixpkgs
- **AND** consumers are not required to use flake-level helper entrypoints.

#### Scenario: Basic invocation

- **WHEN** called as:
```nix
pkgs.lib.opencode.wrapOpenCode {
  name = "my-opencode";
  modules = [ { theme = "dark"; agent.plan.steps = 100; } ];
}
```
- **THEN** it returns a derivation containing a wrapped `opencode` binary.

#### Scenario: Custom opencode package

- **WHEN** called with an explicit `opencode` argument:
```nix
pkgs.lib.opencode.wrapOpenCode {
  name = "my-opencode";
  modules = [ { theme = "dark"; } ];
  opencode = pkgs.opencode;
}
```
- **THEN** it wraps that specific opencode package instead of a default.

#### Scenario: Default package follows selected system

- **WHEN** called without an explicit `opencode` on a supported non-x86_64 system
- **THEN** default package resolution uses the active overlay package set for `<that-system>`
- **AND** evaluation does not depend on `opencode.packages.x86_64-linux.default`.

### Requirement: Binary wrapping mechanism

The wrapper implementation MUST use standard Nix wrapping tools.

#### Scenario: symlinkJoin + makeWrapper

- **WHEN** the derivation is built
- **THEN** it uses `symlinkJoin` and `makeWrapper` (from `pkgs.makeBinaryWrapper` or `pkgs.makeWrapper`) to create the wrapped binary.

#### Scenario: Name controls derivation and executable

- **WHEN** `name = "my-opencode"` is passed
- **THEN** the derivation name is `my-opencode` (visible in store path)
- **AND** the executable is installed as `$out/bin/my-opencode`
- **AND** when exposed as a flake package (for example, `packages.aarch64-linux.my-opencode = pkgs.lib.opencode.wrapOpenCode { ... };`)
- **THEN** `nix run .#my-opencode` finds and launches `$out/bin/my-opencode` via the standard `meta.mainProgram` / bin discovery mechanism.

#### Scenario: Binary is executable

- **WHEN** `$out/bin/<name>` is inspected
- **THEN** it is executable and runs opencode with the config pre-loaded.
