## ADDED Requirements

### Requirement: Typed headless runtime options

The system MUST expose typed NixOS options for headless opencode runtime flags that are valid for long-running server instances.

#### Scenario: Service options map to command arguments
- **WHEN** an instance sets supported runtime options (for example listen address, listen port, log level, provider/model options)
- **THEN** the generated `ExecStart` command includes the corresponding CLI arguments deterministically.

### Requirement: Safe defaults for unattended service mode

Each instance MUST have secure and practical defaults for headless operation when options are omitted.

#### Scenario: Minimal instance config still starts
- **WHEN** an instance sets only `directory`
- **THEN** defaults are applied for remaining required runtime options and the instance starts without interactive input.

### Requirement: Validation of unsupported or conflicting flags

The system MUST reject invalid, unsupported, or conflicting runtime option combinations at evaluation time.

#### Scenario: Invalid option value fails evaluation
- **WHEN** an instance sets an out-of-range or enum-invalid value
- **THEN** NixOS evaluation fails with an actionable error message.

#### Scenario: Interactive-only flag in service mode
- **WHEN** an instance enables a CLI option that requires interactive TTY behavior
- **THEN** evaluation fails and explains that the option is unsupported in headless mode.

### Requirement: Escape hatch for advanced flags

The system MUST provide `extraArgs` for explicitly passing additional CLI arguments not yet modeled by typed options.

#### Scenario: Extra args appended after typed args
- **WHEN** an instance sets `extraArgs = [ "--foo" "bar" ]`
- **THEN** `ExecStart` preserves typed option projection and appends `--foo bar` deterministically.
