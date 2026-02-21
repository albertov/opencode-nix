## ADDED Requirements

### Requirement: Multi-instance service model

The system MUST provide a NixOS module that exposes `services.opencode.instances.<name>` as an attribute set of instance definitions.

#### Scenario: Define two independent instances
- **WHEN** a host config defines `services.opencode.instances.project-a` and `services.opencode.instances.project-b`
- **THEN** module evaluation succeeds and produces two independent systemd units.

### Requirement: Per-instance service unit generation

For each enabled instance, the system MUST generate exactly one service unit named `opencode-<instance-name>`.

#### Scenario: Enabled instance generates a unit
- **WHEN** `services.opencode.instances.my-project.enable = true`
- **THEN** `systemd.services.opencode-my-project` is present with a concrete `ExecStart`.

#### Scenario: Disabled instance does not start
- **WHEN** `services.opencode.instances.my-project.enable = false`
- **THEN** the instance does not run at boot.

### Requirement: Per-instance setup service for state initialization

For each enabled instance, the system MUST provide a dedicated setup unit that initializes instance state only when state is uninitialized.

#### Scenario: Setup runs on first initialization only
- **WHEN** an instance state directory is uninitialized
- **THEN** setup unit runs before main service and initializes required state structure.

#### Scenario: Setup incrementally prepares expected HOME tree
- **WHEN** setup runs for an instance with `HOME = stateDir`
- **THEN** it incrementally prepares required paths such as `$HOME/.local/share/opencode` and `$HOME/.config/opencode`
- **AND** does not destructively replace existing contents.

#### Scenario: Setup is idempotent
- **WHEN** setup unit is executed again after successful initialization
- **THEN** it performs a safe no-op (or equivalent idempotent checks) and does not corrupt existing state.

#### Scenario: Setup does not initialize working directory
- **WHEN** setup unit runs
- **THEN** it initializes only `stateDir` concerns
- **AND** does not create or mutate contents of instance `directory`.

#### Scenario: Setup does not perform migrations
- **WHEN** setup unit runs
- **THEN** it does not perform ad-hoc state migrations
- **AND** leaves migration behavior to opencode runtime.

### Requirement: Setup lifecycle hooks

Each instance MUST support optional `preInitScript` and `postInitScript` options that hook into setup execution.

#### Scenario: preInitScript runs before setup actions
- **WHEN** an instance defines `preInitScript`
- **THEN** setup executes `preInitScript` before module-managed setup steps.

#### Scenario: postInitScript runs after successful setup actions
- **WHEN** an instance defines `postInitScript`
- **THEN** setup executes `postInitScript` after module-managed setup steps complete successfully.

#### Scenario: hook failure fails setup
- **WHEN** `preInitScript` or `postInitScript` exits non-zero
- **THEN** setup unit fails
- **AND** main service start is blocked until setup succeeds.

### Requirement: Shared defaults with per-instance override

The system MUST support `services.opencode.defaults` and merge it into each instance, with instance fields taking precedence over defaults.

#### Scenario: Instance overrides default port
- **WHEN** defaults set `listen.port = 8080` and an instance sets `listen.port = 9090`
- **THEN** the generated unit for that instance uses port `9090`.

### Requirement: Service PATH injection for tooling

The system MUST expose `services.opencode.instances.<name>.path` and wire it to systemd service `path` so opencode can invoke declared CLI tools.

#### Scenario: Declared tool is available in runtime PATH
- **WHEN** an instance includes a package providing binary `jq` in `path`
- **THEN** processes launched by `systemd.services.opencode-<name>` can execute `jq` without absolute path references.

### Requirement: Per-instance persistent state directory

Each instance MUST have a dedicated state directory separate from instance `directory`, with default path `/var/lib/opencode/instance-state/<instance-name>`.

#### Scenario: Default state directory path
- **WHEN** `services.opencode.instances.my-project.stateDir` is not explicitly set
- **THEN** runtime state path resolves to `/var/lib/opencode/instance-state/my-project`.

#### Scenario: State root is independent from working directory
- **WHEN** `directory = "/srv/vibing/my-project"`
- **THEN** opencode runtime state is stored under instance `stateDir`
- **AND** not under `directory` unless explicitly configured.

### Requirement: Backup-friendly state persistence

State directory paths MUST be stable host paths so operators can back up and restore them outside the service sandbox.

#### Scenario: Operator can back up state directory
- **WHEN** instance `my-project` is configured with default or explicit `stateDir`
- **THEN** operator tooling can archive `/var/lib/opencode/instance-state/my-project` (or configured path) without requiring cross-instance sandbox relaxations.

### Requirement: Flake module export

The flake MUST expose the module under `nixosModules` so hosts can import it declaratively.

#### Scenario: Consumer imports module from flake output
- **WHEN** a consumer imports `self.nixosModules.opencode` (or equivalent documented export name)
- **THEN** the module options under `services.opencode.*` are available in evaluation.
