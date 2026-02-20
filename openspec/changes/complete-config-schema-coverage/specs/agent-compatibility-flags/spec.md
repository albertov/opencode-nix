## ADDED Requirements

### Requirement: Agent primary flag is configurable
The Nix module system SHALL support `opencode.agent.<agent-id>.primary` as an optional boolean compatibility field.

#### Scenario: primary flag emits to JSON
- **WHEN** a module sets `opencode.agent.invoicer.primary = true`
- **THEN** generated `opencode.json` includes `agent.invoicer.primary = true`

### Requirement: mode takes precedence when explicitly set
When both `primary` and `mode` are configured, the system MUST apply documented precedence so `mode` remains authoritative for runtime semantics.

#### Scenario: Explicit mode overrides derived primary behavior
- **WHEN** a module sets `opencode.agent.foo.primary = true` and `opencode.agent.foo.mode = "subagent"`
- **THEN** generated `opencode.json` preserves explicit `mode = "subagent"` and does not rewrite it to `primary`

### Requirement: primary can derive primary mode when mode is absent
When `primary = true` and `mode` is not set, the system SHALL emit JSON that is schema-compatible and semantically primary.

#### Scenario: primary=true without mode remains primary-compatible
- **WHEN** a module sets `opencode.agent.chief.primary = true` and omits `mode`
- **THEN** generated `opencode.json` passes upstream schema validation and is treated as a primary agent configuration
