## ADDED Requirements

### Requirement: Default-deny filesystem isolation

Each instance MUST run with filesystem access restricted to explicit paths only.

#### Scenario: Secure default filesystem policy
- **WHEN** an instance is configured with only required options
- **THEN** read-write access is granted to instance `directory`
- **AND** read-write access is granted to instance `stateDir`
- **AND** read-only access is granted to `/nix/store`
- **AND** write access outside allowed paths is denied.

### Requirement: Configurable filesystem allowlists

The system MUST expose per-instance `sandbox.readWritePaths` and `sandbox.readOnlyPaths` options that extend default filesystem access.

#### Scenario: Additional read-write path is honored
- **WHEN** an instance adds `/var/lib/my-cache` to `sandbox.readWritePaths`
- **THEN** process writes to `/var/lib/my-cache` succeed.

#### Scenario: Non-allowlisted path remains blocked
- **WHEN** an instance has no allowlist for `/etc`
- **THEN** writing to `/etc` fails.

### Requirement: Process and /proc isolation

Each instance MUST use process and `/proc` isolation settings that prevent broad host process visibility.

#### Scenario: Process visibility is restricted
- **WHEN** the instance inspects `/proc`
- **THEN** only allowed process metadata is visible according to configured `ProtectProc`/`ProcSubset` policy.

### Requirement: Kernel and control-plane hardening

Each instance MUST enable hardening controls for kernel tunables, kernel modules, and cgroups unless explicitly relaxed by operator configuration.

#### Scenario: Kernel tunable mutation blocked by default
- **WHEN** process inside the instance attempts to modify protected kernel tunables
- **THEN** the operation is denied.

### Requirement: Explicit Unix socket sharing

Unix socket access beyond default sandbox boundaries MUST require explicit opt-in via `sandbox.unixSockets.allow`.

#### Scenario: Socket not allowlisted is inaccessible
- **WHEN** an instance attempts to connect to a host socket not listed in `sandbox.unixSockets.allow`
- **THEN** the connection fails.

#### Scenario: Allowlisted socket is reachable
- **WHEN** `/run/postgresql/.s.PGSQL.5432` is listed in `sandbox.unixSockets.allow`
- **THEN** the instance can connect to that socket.

### Requirement: Cross-instance state isolation

Instance state directories MUST be isolated so one opencode instance has no access to another instance's state.

#### Scenario: Instance cannot read other instance state
- **WHEN** instance `opencode-a` attempts to read files under instance `opencode-b` state directory
- **THEN** access is denied.

#### Scenario: Instance cannot write other instance state
- **WHEN** instance `opencode-a` attempts to write into instance `opencode-b` state directory
- **THEN** access is denied.
