## ADDED Requirements

### Requirement: Nested permission maps are representable
The Nix module system SHALL support nested permission maps in addition to flat tool-to-action mappings.

#### Scenario: Flat and nested permissions coexist
- **WHEN** a module defines `permission."*" = "deny"`, `permission.bash = "allow"`, and nested maps in the same config
- **THEN** generated `opencode.json` includes both flat and nested permission entries without shape loss

### Requirement: External directory path rules are representable
The Nix module system SHALL support path-scoped `external_directory` permission maps where each path/glob maps to an action.

#### Scenario: external_directory map emits correctly
- **WHEN** a module sets `permission.external_directory."/tmp/**" = "allow"` and `permission.external_directory."/tmp/*" = "allow"`
- **THEN** generated `opencode.json` contains a nested `external_directory` object with both keys and actions

### Requirement: Skill-scoped permissions are representable
The Nix module system SHALL support per-skill permission mappings under `permission.skill`.

#### Scenario: Skill permission scope emits correctly
- **WHEN** a module sets `permission.skill.facturas-compras-holded = "allow"`
- **THEN** generated `opencode.json` contains `permission.skill.facturas-compras-holded` with action `allow`
