## ADDED Requirements

### Requirement: Per-instance ergonomic config submodule

Each instance defined under `services.opencode.instances.<name>` SHALL expose a `config` option that is a NixOS submodule reusing the typed opencode config module definition from `nix/config/default.nix`. Users SHALL set configuration values directly as attributes (e.g., `config.model = "sonnet";`) without needing to wrap them in module lists or use the `opencode.` prefix.

#### Scenario: Inline config attribute assignment

- **WHEN** a NixOS configuration defines `services.opencode.instances.dev.config.model = "sonnet"`
- **THEN** the generated `opencode.json` for instance `dev` SHALL contain `"model": "sonnet"`

#### Scenario: Nested config attributes

- **WHEN** a NixOS configuration defines `services.opencode.instances.dev.config.tui.theme = "dark"`
- **THEN** the generated `opencode.json` for instance `dev` SHALL contain `"tui": { "theme": "dark" }`

#### Scenario: Config submodule uses full typed option set

- **WHEN** the `config` submodule is evaluated
- **THEN** it SHALL expose the same typed options as `nix/config/default.nix` (agents, providers, mcp, permissions, commands, tui, server, lsp, formatter, skills, compaction, watcher, experimental, enterprise, keybinds, and all root scalars)

### Requirement: Per-instance configFile override

Each instance SHALL expose a `configFile` option of type `types.path`. When not explicitly set by the user, `configFile` SHALL default to the JSON derivation generated from the `config` submodule. When explicitly set, the user-provided path SHALL be used verbatim, bypassing config module evaluation for that instance.

#### Scenario: Default configFile from config submodule

- **WHEN** an instance defines `config.model = "sonnet"` and does NOT set `configFile`
- **THEN** `configFile` SHALL resolve to a Nix store path containing the generated `opencode.json` with `"model": "sonnet"`

#### Scenario: Explicit configFile overrides config

- **WHEN** an instance defines `configFile = ./my-opencode.json`
- **THEN** the service SHALL use `./my-opencode.json` as the config file
- **AND** the `config` submodule values SHALL be ignored for that instance

#### Scenario: Explicit configFile with empty config

- **WHEN** an instance sets `configFile = /run/secrets/opencode.json` and leaves `config` at defaults
- **THEN** the service SHALL use `/run/secrets/opencode.json` without errors

### Requirement: Removal of opencodeCfg option

The legacy `opencodeCfg` option (list of modules) SHALL be removed entirely. It is replaced by the `config` submodule and `configFile` override. No deprecation warnings or migration shims are needed (unreleased API).

## MODIFIED Requirements

### Requirement: Per-instance service unit generation

For each enabled instance in `services.opencode.instances`, the module SHALL generate a dedicated systemd service unit named `opencode-<name>`. The service unit SHALL use the instance's resolved `configFile` (whether generated from `config` or explicitly provided) to populate the opencode configuration at the instance's `$HOME/.config/opencode/opencode.json`.

#### Scenario: Service uses generated configFile

- **WHEN** instance `dev` has `config.model = "sonnet"` and no explicit `configFile`
- **THEN** the setup service SHALL symlink the generated JSON store path to `$HOME/.config/opencode/opencode.json`

#### Scenario: Service uses explicit configFile

- **WHEN** instance `dev` has `configFile = /etc/opencode/dev.json`
- **THEN** the setup service SHALL symlink `/etc/opencode/dev.json` to `$HOME/.config/opencode/opencode.json`

### Requirement: Shared defaults with per-instance override

The module SHALL support a top-level `services.opencode.defaults` option. Per-instance `config` values SHALL be merged on top of defaults using NixOS module merge semantics (not just shallow merge). Per-instance values SHALL take precedence over defaults.

#### Scenario: Instance config overrides defaults

- **WHEN** defaults set `config.model = "sonnet"` and instance `dev` sets `config.model = "opus"`
- **THEN** instance `dev` SHALL use `"model": "opus"` in its generated JSON
