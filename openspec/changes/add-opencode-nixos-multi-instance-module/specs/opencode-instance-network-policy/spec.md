## ADDED Requirements

### Requirement: Inbound listener restriction

Each instance MUST only accept incoming traffic on its configured listen address and port.

#### Scenario: Service listens on configured endpoint
- **WHEN** an instance sets `listen.address = "127.0.0.1"` and `listen.port = 8787`
- **THEN** the service binds only to `127.0.0.1:8787`.

### Requirement: Firewall exposure is explicit

The system MUST expose `openFirewall` per instance, and it MUST default to closed.

#### Scenario: Firewall remains closed by default
- **WHEN** `openFirewall` is omitted or `false`
- **THEN** no host firewall rule is created to expose the instance port.

#### Scenario: openFirewall opens only instance port
- **WHEN** `openFirewall = true` and `listen.port = 8787`
- **THEN** host firewall rules allow inbound traffic to port `8787`
- **AND** do not implicitly open unrelated ports.

### Requirement: Outbound CIDR allow-list policy

The system MUST support per-instance outbound network policy with explicit CIDR allow-lists.

#### Scenario: Allowed destination succeeds
- **WHEN** `networkIsolation.enable = true` and `networkIsolation.outboundAllowCidrs` includes `10.10.0.0/16`
- **THEN** outbound connections to addresses inside `10.10.0.0/16` succeed.

#### Scenario: Non-allowlisted destination is blocked
- **WHEN** `networkIsolation.enable = true` and destination address is outside configured CIDR allow-lists
- **THEN** outbound connection is blocked.

### Requirement: Blocked outbound attempts are observable

When outbound network isolation is enabled, blocked outbound connection attempts MUST be logged with enough context for operators to tune allow-lists.

#### Scenario: Blocked outbound attempt is logged
- **WHEN** `networkIsolation.enable = true` and an instance attempts outbound traffic to a non-allowlisted destination
- **THEN** the attempt is denied
- **AND** a log record is emitted with an instance-identifying prefix (for example `opencode-<name>-blocked`) and kernel network metadata including destination details.

#### Scenario: Log volume is controlled
- **WHEN** repeated blocked outbound attempts occur
- **THEN** logging is rate-limited to avoid unbounded log spam while preserving operator visibility.

### Requirement: Deterministic behavior when policy backend unavailable

The system MUST fail safely when outbound network isolation is enabled but required enforcement backend is unavailable.

#### Scenario: Isolation enabled without nftables backend
- **WHEN** `networkIsolation.enable = true` and `networking.nftables.enable = false`
- **THEN** NixOS evaluation fails with an actionable assertion error.

#### Scenario: Isolation enabled while legacy firewall backend is active
- **WHEN** any instance enables `networkIsolation.enable = true` and `networking.firewall.enable = true`
- **THEN** NixOS evaluation fails with an actionable assertion error describing the nftables requirement.
