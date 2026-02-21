## MODIFIED Requirements

### Requirement: Root scalar options

Every root-level scalar field in the opencode configuration schema SHALL have a corresponding `mkOption` in the Nix module. The `"$schema"` field SHALL NOT be exposed as a user-facing Nix option. The module SHALL NOT require or accept `"$schema"` from user configuration input.

#### Scenario: Standard scalar options remain typed

- **WHEN** a user sets `opencode.model = "sonnet"` in a config module
- **THEN** the evaluated config SHALL include `model = "sonnet"` with correct type checking

#### Scenario: Schema field not settable by users

- **WHEN** a user attempts to set `opencode."$schema" = "https://opencode.ai/config.json"` in a config module
- **THEN** evaluation SHALL fail because `"$schema"` is not a defined option

#### Scenario: Omitted optional scalars produce no JSON key

- **WHEN** a user does not set `opencode.theme`
- **THEN** the generated JSON SHALL NOT contain a `"theme"` key

### Requirement: NixOS service integration compatibility

The typed config module SHALL be directly consumable as a NixOS submodule within `services.opencode.instances.<name>.config`. Instance configuration SHALL compile through the existing opencode.json generation pipeline. The generated config SHALL be materialized at the instance's `$HOME/.config/opencode/opencode.json`. Users SHALL interact with config attributes directly (e.g., `config.model`) without needing the `opencode.` prefix that standalone module usage requires.

#### Scenario: Instance config compiles to opencode.json

- **WHEN** a NixOS instance sets `config.model = "sonnet"` and `config.tui.theme = "dark"`
- **THEN** the generated opencode.json SHALL contain `{"model": "sonnet", "tui": {"theme": "dark"}}`

#### Scenario: Existing standalone pipeline still works

- **WHEN** `mkOpenCodeConfig [ { opencode.model = "sonnet"; } ]` is called outside the NixOS module
- **THEN** the generated opencode.json SHALL contain `{"model": "sonnet"}` as before

#### Scenario: Config materialized at HOME config path

- **WHEN** an instance generates its config
- **THEN** the setup service SHALL place it at `$HOME/.config/opencode/opencode.json`

### Requirement: Multi-instance config generation isolation

Each instance's configuration SHALL be evaluated in its own module evaluation scope. Configuration values from one instance SHALL NOT leak into another instance's generated JSON.

#### Scenario: Independent instance configs

- **WHEN** instance `dev` sets `config.model = "sonnet"` and instance `prod` sets `config.model = "opus"`
- **THEN** `dev`'s JSON SHALL contain `"model": "sonnet"` and `prod`'s JSON SHALL contain `"model": "opus"`

### Requirement: Secret-safe integration with runtime environment injection

Secrets SHALL NOT appear in the Nix store or generated JSON. The `environmentFile` mechanism SHALL inject secrets at service runtime. Generated config SHALL reference environment variables using template syntax where needed.

#### Scenario: API key injected at runtime

- **WHEN** `config.providers.anthropic.apiKey` references an env var and `environmentFile` provides the value
- **THEN** the running service SHALL have access to the secret without it appearing in the Nix store

## ADDED Requirements

### Requirement: Automatic schema injection in generated JSON

The JSON generation pipeline SHALL automatically include `"$schema": "https://opencode.ai/config.json"` in every generated `opencode.json` file. This injection SHALL happen at the serialization layer, not as a user-facing option.

#### Scenario: Generated JSON includes schema URL

- **WHEN** any config module is evaluated and serialized to JSON
- **THEN** the output JSON SHALL contain `"$schema": "https://opencode.ai/config.json"` as the first key

#### Scenario: Schema URL not overridable by users

- **WHEN** a config is generated through `mkOpenCodeConfig` or the NixOS instance pipeline
- **THEN** the `"$schema"` value SHALL always be `"https://opencode.ai/config.json"` regardless of user input
