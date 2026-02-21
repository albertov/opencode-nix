## ADDED Requirements

### Requirement: Parity fixtures cover previously unsupported schema fields
The test suite SHALL include fixtures and assertions for every field family that was previously unsupported in `opencode-nix`.

#### Scenario: Unsupported fields are covered by tests
- **WHEN** the suite runs against fixtures containing provider metadata, nested permissions, and agent compatibility flags
- **THEN** each fixture validates successfully against upstream `Config.Info` Zod schema

### Requirement: Parity tests are part of flake checks
Schema parity tests MUST run through the existing flake check path so regressions fail CI.

#### Scenario: Parity regression fails CI
- **WHEN** a code change drops or reshapes a parity field in emitted JSON
- **THEN** `nix flake check` fails with a validation error from the parity test set

### Requirement: Migrated real-world config example validates end-to-end
The repository SHALL include at least one migrated real-world configuration that validates via the parity test flow.

#### Scenario: Full migrated example validates
- **WHEN** a realistic multi-provider configuration module is rendered and validated
- **THEN** the generated JSON passes upstream schema validation without manual post-processing
