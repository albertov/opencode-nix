## ADDED Requirements

### Requirement: NixOS service integration compatibility

The typed config module MUST be consumable by the NixOS opencode service module through the existing opencode.json generation machinery for per-instance configuration generation.

#### Scenario: Instance configuration compiles to opencode config
- **WHEN** a NixOS instance declares opencode configuration options through the typed module interface
- **THEN** the service integration produces a valid opencode configuration artifact consumed by the instance runtime.

#### Scenario: Existing opencode.json pipeline is reused
- **WHEN** the NixOS service module renders per-instance opencode configuration
- **THEN** it uses the existing opencode.json generation path
- **AND** does not introduce a second independent renderer with divergent behavior.

#### Scenario: Generated config is materialized at HOME config path
- **WHEN** an instance starts with default HOME/stateDir behavior
- **THEN** generated config is exposed at `$HOME/.config/opencode/opencode.json` via symlink to the generated artifact.

### Requirement: Declarative extension integration

Service integration MUST allow declarative extension content (for example skills) to be referenced through generated opencode configuration without replacing module-managed HOME layout.

#### Scenario: Declarative extension references coexist with generated config symlink
- **WHEN** operator declares extension paths (for example `opencode.skills.paths`) in instance config modules
- **THEN** generated `opencode.json` contains those extension references for runtime use
- **AND** generated `opencode.json` symlink at `$HOME/.config/opencode/opencode.json` remains intact.

### Requirement: Multi-instance config generation isolation

Configuration generation MUST be instance-scoped so one instance's config options do not leak into another instance's generated config.

#### Scenario: Two instances with conflicting themes
- **WHEN** instance `a` sets `theme = "dark"` and instance `b` sets `theme = "catppuccin"`
- **THEN** generated configs remain separate and each instance receives only its own value.

### Requirement: Secret-safe integration with runtime environment injection

Service integration MUST support secrets delivered through runtime environment files without requiring secret plaintext in generated static config.

#### Scenario: Secret supplied through environment file
- **WHEN** API credentials are provided via NixOS `environmentFile`
- **THEN** generated static opencode configuration does not embed those secret values and runtime resolves them from environment.
