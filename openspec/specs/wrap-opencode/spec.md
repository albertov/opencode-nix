# wrap-opencode

Library function that wraps the opencode binary with a generated config file baked in via environment variable.

## ADDED Requirements

### Requirement: Function signature

`lib.wrapOpenCode` accepts an attrset with `name`, `modules`, and optional `opencode` package.

#### Scenario: Basic invocation

WHEN called as:
```nix
lib.wrapOpenCode {
  name = "my-opencode";
  modules = [ { theme = "dark"; agent.plan.steps = 100; } ];
}
```
THEN it returns a derivation containing a wrapped `opencode` binary.

#### Scenario: Custom opencode package

WHEN called with an explicit `opencode` argument:
```nix
lib.wrapOpenCode {
  name = "my-opencode";
  modules = [ { theme = "dark"; } ];
  opencode = pkgs.opencode;
}
```
THEN it wraps that specific opencode package instead of a default.

---

### Requirement: OPENCODE_CONFIG environment variable

The wrapper sets `OPENCODE_CONFIG` to point to the generated config file.

#### Scenario: Env var is set

WHEN the wrapped binary is executed
THEN the `OPENCODE_CONFIG` environment variable points to the Nix store path of the generated `opencode.json`.

#### Scenario: Config is generated via mkOpenCodeConfig

WHEN `wrapOpenCode` is called with modules
THEN it internally calls `mkOpenCodeConfig` with those modules to produce the config derivation.

#### Scenario: Config survives garbage collection

WHEN the wrapped derivation is in a Nix profile or referenced by a GC root
THEN the config derivation is also retained (it's a build dependency).

---

### Requirement: Binary wrapping mechanism

Uses standard Nix wrapping tools.

#### Scenario: symlinkJoin + makeWrapper

WHEN the derivation is built
THEN it uses `symlinkJoin` and `makeWrapper` (from `pkgs.makeBinaryWrapper` or `pkgs.makeWrapper`) to create the wrapped binary.

#### Scenario: Name controls derivation and executable

WHEN `name = "my-opencode"` is passed
THEN the derivation name is `my-opencode` (visible in store path)
AND the executable is installed as `$out/bin/my-opencode`
so that when the user exposes it as a flake package (e.g., `packages.x86_64-linux.my-opencode = lib.wrapOpenCode { ... }`)
THEN `nix run .#my-opencode` finds and launches `$out/bin/my-opencode` via the standard `meta.mainProgram` / bin discovery mechanism.

#### Scenario: Binary is executable

WHEN `$out/bin/<name>` is inspected
THEN it is executable and runs opencode with the config pre-loaded.

---

### Requirement: Opencode runtime behavior with wrapper

The wrapped binary behaves like normal opencode but with the config pre-applied.

#### Scenario: Project config still merges

WHEN the wrapped binary is run in a directory with its own `opencode.json`
THEN both configs are loaded — the wrapper config at custom config precedence (level 3) and the project config at project level (level 4), following opencode's standard precedence rules.

#### Scenario: Template resolution at runtime

WHEN the baked-in config contains `{env:MY_VAR}` strings
THEN opencode resolves them at runtime using the actual environment, not at Nix build time.
