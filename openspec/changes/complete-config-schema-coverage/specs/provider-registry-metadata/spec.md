## ADDED Requirements

### Requirement: Provider registry metadata fields are representable
The Nix module system SHALL support provider-level registry metadata fields required by upstream schema compatibility, including `npm` and `name` under `opencode.provider.<provider-id>`.

#### Scenario: Provider metadata is emitted to JSON
- **WHEN** a module sets `opencode.provider.modal.npm` and `opencode.provider.modal.name`
- **THEN** generated `opencode.json` includes those fields unchanged under `provider.modal`

### Requirement: Provider model metadata is representable
The Nix module system SHALL support model registry metadata under `opencode.provider.<provider-id>.models.<model-id>`, including model name, capability flags, limits, and modalities.

#### Scenario: Model metadata round-trips
- **WHEN** a module sets `models.<id>.name`, `tools/tool_call/reasoning/attachment/temperature`, `limit.context/output`, and `modalities.input/output`
- **THEN** generated `opencode.json` preserves each configured value at the expected model path

### Requirement: Provider options support provider-specific keys
The Nix module system MUST allow provider-specific option keys that are valid upstream but not part of a small fixed key subset.

#### Scenario: Non-core provider options are preserved
- **WHEN** a module sets `opencode.provider.amazon-bedrock.options.region` and `profile`
- **THEN** generated `opencode.json` contains those keys and values under `provider.amazon-bedrock.options`
