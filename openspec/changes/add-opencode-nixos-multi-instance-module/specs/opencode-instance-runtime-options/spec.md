## ADDED Requirements

### Requirement: Typed headless runtime options

The system MUST expose typed NixOS options for headless opencode runtime flags that are valid for long-running server instances.

#### Scenario: Service options map to command arguments
- **WHEN** an instance sets supported runtime options (for example listen address, listen port, log level, provider/model options)
- **THEN** the generated `ExecStart` command includes the corresponding CLI arguments deterministically
- **AND** uses headless server invocation (`opencode serve`) with explicit `--port` and `--hostname` projection.

### Requirement: Safe defaults for unattended service mode

Each instance MUST have secure and practical defaults for headless operation when options are omitted.

#### Scenario: Minimal instance config still starts
- **WHEN** an instance sets only `directory`
- **THEN** defaults are applied for remaining required runtime options and the instance starts without interactive input.

### Requirement: Journald-visible service logs

Each instance MUST run opencode with log emission to stderr so unit logs are visible through journald for debugging and test assertions.

#### Scenario: ExecStart enables stderr log streaming
- **WHEN** an instance service starts
- **THEN** generated `ExecStart` includes `--print-logs`
- **AND** opencode logs are observable via `journalctl -u opencode-<instance>`.

### Requirement: Validation of typed values

The system MUST reject invalid typed runtime option values at evaluation time.

#### Scenario: Invalid option value fails evaluation
- **WHEN** an instance sets an out-of-range or enum-invalid value
- **THEN** NixOS evaluation fails with an actionable error message.

### Requirement: Escape hatch for advanced flags

The system MUST provide `extraArgs` for explicitly passing additional CLI arguments not yet modeled by typed options.

#### Scenario: Extra args appended after typed args
- **WHEN** an instance sets `extraArgs = [ "--foo" "bar" ]`
- **THEN** `ExecStart` preserves typed option projection and appends `--foo bar` deterministically.
