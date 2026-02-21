# config-tests

Automated tests validating that generated JSON configs are accepted by the upstream opencode Zod schema.

## ADDED Requirements

### Requirement: Zod schema validation

Generated JSON is validated against the actual opencode Zod schema from upstream source.

#### Scenario: Minimal config passes

WHEN `mkOpenCodeConfig [ { theme = "dark"; } ]` is built
THEN validating its output against the Zod `Info` schema succeeds with no errors.

#### Scenario: Full config passes

WHEN a config using all major sections (agent, provider, mcp, permission, command, lsp, formatter, tui, server, keybinds, skills, watcher, compaction, enterprise, experimental) is built
THEN validating its output against the Zod schema succeeds.

#### Scenario: Schema rejection detected

WHEN a Nix test intentionally produces JSON with an invalid field
THEN the Zod validation rejects it, proving the test harness catches real errors.

---

### Requirement: Source from flake input

The opencode source code for Zod validation comes from a flake input, not the local `./opencode` directory.

#### Scenario: Flake input defined

WHEN `flake.nix` is inspected
THEN it contains an input like:
```nix
opencode-src = { url = "github:anthropics/opencode"; flake = false; };
```

#### Scenario: Tests use flake input

WHEN the test derivation is built
THEN it references `inputs.opencode-src` for the Zod schema source, not `./opencode`.

#### Scenario: Updating tracks upstream

WHEN `nix flake update opencode-src` is run
THEN the lock file updates to the latest opencode commit, and `nix flake check` validates against the new schema.

---

### Requirement: Test derivation structure

Tests run as Nix derivations exposed via `checks.<system>`.

#### Scenario: Check is discoverable

WHEN `nix flake check` is run
THEN it executes the config validation tests.

#### Scenario: Test installs dependencies

WHEN the test derivation builds
THEN it installs opencode's npm dependencies (via bun) from the flake input source before running validation.

#### Scenario: Failure is visible

WHEN a test fails (Zod rejects the JSON)
THEN the build fails with a clear error message showing which field was rejected and why.

---

### Requirement: Test coverage breadth

Tests cover representative configs, not just trivial ones.

#### Scenario: Empty config

WHEN `mkOpenCodeConfig [ {} ]` is built and validated
THEN the empty JSON object `{}` passes Zod validation (all fields are optional).

#### Scenario: Scalar fields config

WHEN a config with all root scalar fields is validated
THEN it passes.

#### Scenario: Agent config

WHEN a config with multiple agents (including custom names, permissions, all typed fields) is validated
THEN it passes.

#### Scenario: MCP config with both types

WHEN a config with both local and remote MCP servers is validated
THEN it passes.

#### Scenario: LSP disabled and configured

WHEN a config with `lsp = false` is validated, and separately a config with LSP servers configured is validated
THEN both pass.

#### Scenario: Provider with nested model config

WHEN a config with providers including whitelist, blacklist, and model overrides is validated
THEN it passes.
