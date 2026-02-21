## ADDED Requirements

### Requirement: Declarative instance environment variables

The system MUST expose `services.opencode.instances.<name>.environment` as an attribute set of environment variables for that instance.

#### Scenario: Environment variables are present in runtime
- **WHEN** an instance sets `environment.OPENCODE_FOO = "bar"`
- **THEN** the generated unit injects `OPENCODE_FOO=bar` into the service runtime environment.

### Requirement: Secret-friendly environment file option

The system MUST expose `services.opencode.instances.<name>.environmentFile` and wire it to systemd `EnvironmentFile=` for runtime-loaded variables.

#### Scenario: Environment file is loaded at runtime
- **WHEN** an instance sets `environmentFile = "/run/secrets/opencode-my-project.env"`
- **THEN** the service reads variables from that file at startup.

#### Scenario: sops-nix style secret path support
- **WHEN** `environmentFile` points to a materialized sops-nix path under `/run/secrets/*`
- **THEN** the instance starts successfully and receives those variables at runtime.

### Requirement: Deterministic precedence between sources

Environment values MUST be resolved in deterministic precedence order: module-required values first, then explicit `environment`, then `environmentFile` overrides last.

#### Scenario: Environment file overrides inline environment value
- **WHEN** `environment.API_BASE = "https://sample"` and `environmentFile` defines `API_BASE=https://secret-override`
- **THEN** runtime value for `API_BASE` is `https://secret-override`.

### Requirement: Sandbox HOME defaults are ergonomic

The system MUST set `HOME` for each instance to that instance's `stateDir` by default so opencode and common CLI/tool behavior work in the sandbox.

#### Scenario: Default HOME is instance-scoped and writable
- **WHEN** an instance `my-project` uses default HOME behavior
- **THEN** runtime `HOME` equals that instance's `stateDir`
- **AND** the service user can write to it.

#### Scenario: Opencode state path resolves under HOME
- **WHEN** runtime `HOME` is set to instance `stateDir`
- **THEN** opencode default state location resolves to `$HOME/.local/share/opencode`
- **AND** that path is writable for the instance service user.

### Requirement: Secret values are not stored in build artifacts

The system MUST NOT require secret values to be embedded in Nix store paths or generated world-readable config files.

#### Scenario: Secret supplied only via environment file
- **WHEN** credentials are provided through `environmentFile`
- **THEN** generated derivations and static configuration artifacts do not contain the secret plaintext values.
