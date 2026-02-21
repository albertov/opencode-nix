## Context

This change introduces a multi-instance NixOS service for opencode with an overlay-first packaging direction. Operators need to declare many project-scoped opencode servers (virtual-host style) while preserving strict runtime isolation and predictable networking.

The module must balance two goals that usually conflict:
- secure-by-default hardening for unattended headless services,
- enough configurability to expose useful opencode CLI behavior and controlled network reachability.

Current state has no dedicated NixOS service for this use case, so instance lifecycle, isolation policy, and firewall behavior are ad hoc.

## Goals / Non-Goals

**Goals:**
- Provide `services.opencode.instances.<name>` as a declarative API for multiple concurrent instances.
- Integrate instance config with existing opencode.json generation machinery so runtime config is declarative.
- Map supported headless opencode CLI options into typed NixOS options with sensible defaults.
- Run each instance in its own hardened systemd unit with resource/isolation controls.
- Provide configurable network policy per instance: inbound listen-port handling and outbound CIDR allow-list policy.
- Provide default-deny filesystem/process/kernel isolation with explicit read-write/read-only path and socket-sharing allowlists.
- Provide declarative environment variable configuration and secret-friendly `environmentFile` support per instance.
- Provide per-instance systemd `path` injection so operators can supply additional CLI tools available to opencode runtime.
- Set sandbox `HOME` to `stateDir` so opencode state naturally lands in `$HOME/.local/share/opencode`.
- Provide a dedicated per-instance persistent state directory separate from instance `directory`, with strict cross-instance isolation and backup-friendly host paths.
- Provide a dedicated per-instance setup service that initializes state safely and idempotently when state is uninitialized.
- Keep module consumable through flake outputs and compatible with overlay-first helper usage.

**Non-Goals:**
- Supporting interactive/TUI workflows in service mode.
- Designing a full multi-tenant auth layer above opencode.
- Managing TLS termination directly in this module (expected to be handled by reverse proxy when needed).

## Decisions

### 1) Per-instance submodule API under `services.opencode.instances`

Each instance is defined as an attrset entry (`services.opencode.instances.<name>`). Shared defaults live at `services.opencode.defaults` and are merged into each instance.

Why:
- Mirrors NixOS patterns used for virtual-host-style services.
- Keeps per-project declarations concise while allowing full per-instance overrides.

Alternative considered:
- Single-instance module with duplicated module imports.

Why not:
- Poor ergonomics and weak composability for many instances.

### 2) One systemd service unit per instance

Generate `systemd.services.opencode-<instance>` from instance definitions. Each unit runs opencode in headless server mode with explicit `WorkingDirectory`, dedicated runtime user/group controls, restart policy, and hardening flags.

Why:
- Native lifecycle management, observability, and cgroup isolation per instance.
- Fine-grained resource and failure isolation.

Alternative considered:
- One manager process supervising all instances.

Why not:
- Larger blast radius and less transparent operations in NixOS.

### 3) Typed CLI option projection

Expose only CLI options that make sense for isolated headless operation (for example listen address/port, model/provider knobs, logging, limits, feature flags). Build command line deterministically from typed options; preserve an `extraArgs` escape hatch.

Why:
- Strong validation and safer defaults while retaining flexibility.

Alternative considered:
- Raw string command option only.

Why not:
- Weak validation and harder long-term compatibility.

### 4) Network policy through layered controls

Inbound:
- bind service only to configured listen address/port,
- optional `openFirewall` to add host firewall allowance for instance port.

Outbound:
- support an allow-list of CIDR ranges enforced with a generated nftables/ipset policy attached to instance traffic identity,
- provide `networkIsolation.enable` to toggle policy enforcement and fail safe when policy backend is unavailable,
- log blocked outbound connection attempts (with rate limiting and instance-identifying context) so operators can iteratively update allow-lists.

Why:
- Separates reachability intent (`openFirewall`) from egress control intent (CIDR allow-list), with explicit operator control.

Alternative considered:
- Only service bind controls without firewall policy.

Why not:
- Insufficient for isolation guarantees in multi-tenant environments.

### 5) Canonical package source from overlay-aware context

Module resolves opencode package from `pkgs` in evaluation context by default, with per-instance `package` override.

Why:
- Aligns with overlay-first API and system-correct package resolution.

Alternative considered:
- Hard reference to flake package outputs by architecture.

Why not:
- Reintroduces architecture coupling and reduces composability.

### 6) Full sandbox isolation with explicit escape hatches

Each instance gets a strict systemd sandbox profile by default:
- filesystem isolation defaults to:
  - read-write: instance `directory`,
  - read-only: `/nix/store`,
  - everything else denied unless explicitly allowed,
- process and `/proc` isolation enabled (`ProtectProc`, `ProcSubset`, no ambient process visibility),
- kernel and control-plane hardening enabled (`ProtectKernelTunables`, `ProtectKernelModules`, `ProtectControlGroups`, plus related hardening knobs).

Expose typed options to extend access explicitly per instance:
- `sandbox.readWritePaths` and `sandbox.readOnlyPaths`,
- `sandbox.unixSockets.allow` for explicit Unix socket paths/directories that must be reachable,
- optional extra hardening overrides for advanced operators.

Why:
- Meets the requirement for strong multi-instance isolation while still supporting explicit integration with host services (for example nix-daemon or databases).

Alternative considered:
- Soft sandbox defaults with broad host filesystem access.

Why not:
- Too permissive for intended multi-tenant/project isolation goals.

### 7) Environment model with secret-file integration

Expose per-instance environment options:
- `environment` (attribute set of non-secret variables),
- `environmentFile` (file path in `EnvironmentFile=` format, for secret-backed variables).

Support default values under `services.opencode.defaults.*` and per-instance overrides. Define deterministic precedence:
1. module-generated required vars,
2. explicit `environment`,
3. `environmentFile` overrides last.

Require that secret use cases work with runtime-managed paths such as sops-nix materialized files under `/run/secrets/*`.

Why:
- Operators need both declarative non-secret config and secure secret injection without placing secret values in world-readable or store-copied Nix expressions.

Alternative considered:
- Only inline `environment` and no `EnvironmentFile` support.

Why not:
- Inadequate for secrets and common NixOS secret workflows.

### 7b) Service PATH injection and HOME ergonomics

Expose per-instance `path` option (list of packages/paths) wired to systemd service `path` so opencode can call required external tools without global host coupling.

Set `HOME` in the unit environment to the instance `stateDir` itself by default.

Setup ensures expected opencode paths exist incrementally and idempotently under HOME:
- `$HOME/.local/share/opencode/` for runtime state,
- `$HOME/.config/opencode/` for configuration,
- `$HOME/.config/opencode/opencode.json` as a symlink to the generated config artifact.

Allow declarative extension content (for example skills/agents) to be projected under `$HOME/.config/opencode/` without clobbering existing state-managed files.

Why:
- Operators often need additional CLI tools available in runtime PATH.
- Many CLIs/libraries assume HOME exists and is writable; `HOME = stateDir` avoids fragile behavior and aligns with opencode defaults.

Alternative considered:
- No service `path` support and no explicit HOME configuration.

Why not:
- Leads to brittle runtime behavior and ad-hoc per-host workarounds.

### 8) Reuse existing opencode.json generation machinery

The NixOS module must generate each instance config through the existing opencode.json infrastructure (typed config module and helper pipeline) rather than introducing a second ad-hoc renderer.

Why:
- Avoids config drift across integration paths.
- Leverages existing validation and schema consistency.

Alternative considered:
- Build opencode.json directly in the service module with bespoke rendering logic.

Why not:
- Duplicated logic and higher risk of behavioral mismatch.

### 9) Dedicated per-instance state directory model

Each instance gets a persistent state directory (default `/var/lib/opencode/instance-state/<instance-name>`) that is distinct from instance `directory`.

The unit environment/configuration must route opencode state writes (including `~/.local/share/opencode` contents such as auth DB/files, logs, snapshots, storage, tool output, and worktree metadata) into that instance-specific state root.

Isolation requirements:
- Instance A has read-write access to its own state root.
- Instance A has no access to Instance B state root.

Operational requirements:
- state paths are stable on host filesystem,
- operators can back up and restore state directories outside service sandbox.

Why:
- Preserves required runtime state while preventing cross-instance leakage.
- Supports practical operations (backup, restore, migration).

Alternative considered:
- Keep state in each instance `directory`.

Why not:
- Mixes code/worktree and mutable runtime state; harder isolation and backup management.

### 10) Idempotent per-instance setup service

Each instance gets a dedicated one-shot setup unit (for example `opencode-<instance>-setup`) that runs before the main service and initializes only state directory concerns.

Setup service requirements:
- run only when instance state is not yet initialized,
- be idempotent and safe on repeated activation,
- create/prepare state directory ownership/permissions as needed,
- support optional per-instance `preInitScript` and `postInitScript` hooks,
- run `preInitScript` before module-managed setup steps and `postInitScript` after successful setup steps,
- fail setup if either hook returns non-zero,
- MUST NOT initialize, create, or mutate instance `directory` worktree content,
- MUST NOT perform ad-hoc state migrations; leave migration behavior to opencode itself.

Why:
- Separates bootstrap and steady-state concerns.
- Prevents accidental writes to operator-managed work directories.
- Preserves safe, non-destructive behavior so opencode can run its own migrations.
- Provides explicit extension points for site-specific bootstrap logic without forking module internals.

Alternative considered:
- Perform initialization inline in the main service `ExecStartPre`.

Why not:
- Harder to reason about idempotence/failure behavior and weaker migration lifecycle control.

## Risks / Trade-offs

- [Complex firewall + cgroup policy interactions] -> Provide conservative defaults, explicit validation, and integration tests for representative policies.
- [Sandbox rules can break legitimate integrations] -> Make integration paths explicit via typed read-only/read-write/socket allowlists and provide clear validation errors.
- [Secret leakage via misconfiguration] -> Keep secret values out of options by default guidance, prefer `environmentFile` for secrets, and document sops-nix integration patterns.
- [Cross-instance state leakage] -> enforce per-instance state roots with deny-by-default cross-access and add explicit isolation tests.
- [Unsafe or repeated bootstrap mutates live data] -> isolate setup into idempotent one-shot unit scoped to state-dir initialization only.
- [Overexposed CLI surface creates unsafe combinations] -> Whitelist supported flags, type-check values, and gate dangerous options behind explicit opt-ins.
- [Per-instance unit explosion on large deployments] -> Document scaling expectations and allow selective enable/disable.
- [Backend dependency for egress policy (nftables/ipset)] -> Detect support at evaluation/runtime and surface actionable errors.

## Migration Plan

1. Add NixOS module and expose via flake `nixosModules` output.
2. Implement option schema and per-instance unit generation with secure defaults.
3. Add service `path` option wiring and instance-scoped HOME defaults.
4. Integrate per-instance config generation with existing opencode.json machinery and symlink it into `$HOME/.config/opencode/opencode.json`.
5. Add dedicated per-instance state directory support and route runtime state there (`HOME = stateDir`).
6. Add per-instance setup unit for safe, idempotent first-run state initialization and incremental HOME tree preparation.
6a. Add optional lifecycle hook options (`preInitScript`, `postInitScript`) with deterministic ordering and failure semantics.
7. Add network-policy integration (`openFirewall`, outbound CIDR controls) and validation checks.
8. Add NixOS tests for multi-instance startup, strict sandbox defaults, explicit path/socket allowlists, inbound port behavior, outbound restriction behavior, environment/environmentFile propagation, per-instance state isolation, setup idempotence, and PATH/HOME behavior.
9. Document example configuration and operational guidance.

## Verification Strategy (Comprehensive NixOS Test Matrix)

Test coverage should include both module-evaluation tests and VM integration tests, and should include positive and negative cases for each isolation control.

1. Module option and unit rendering tests
- Validate option types/defaults for `instances`, `defaults`, sandbox/network/environment options.
- Verify generated `systemd.services.opencode-<name>` units contain expected hardening flags, `WorkingDirectory`, command line projection, service `path` wiring, HOME environment wiring, and `EnvironmentFile` wiring.

2. Multi-instance lifecycle tests
- Boot with at least two instances with different directories, ports, and env settings.
- Assert both units start, remain healthy, and restart independently after induced failure.

3. Filesystem isolation tests
- Default profile: instance can write only inside configured `directory`; read `/nix/store`; cannot write elsewhere.
- Allowlist profile: configured `sandbox.readOnlyPaths`/`sandbox.readWritePaths` are effective.
- Negative checks: access outside allowlists fails.

3b. State directory tests
- Default state root resolves to `/var/lib/opencode/instance-state/<instance-name>`.
- Runtime state writes land in instance state root, not in instance `directory`.
- Instance A cannot read/write Instance B state root.
- Host-side backup process can archive state roots without disabling sandbox defaults.

3c. Setup service idempotence tests
- First activation initializes state dir only when uninitialized.
- Re-activation is idempotent (no destructive changes, safe no-op behavior).
- Setup does not create or mutate instance `directory` contents.
- Setup does not perform implicit state migrations.
- Setup incrementally creates expected HOME subpaths and preserves pre-existing user-managed files.
- `preInitScript` runs before module-managed setup actions.
- `postInitScript` runs after successful module-managed setup actions.
- Non-zero exit in `preInitScript`/`postInitScript` fails setup and blocks main service start.

4. Process, /proc, and kernel hardening tests
- Confirm restricted process visibility and `/proc` behavior match configured `ProtectProc`/`ProcSubset`.
- Confirm kernel/control-plane protections are enabled and mutation attempts are denied (tunables, modules, cgroups).

5. Unix socket integration tests
- Negative: connection to non-allowed socket path fails.
- Positive: explicit `sandbox.unixSockets.allow` enables access to allowed sockets (for example a test DB socket).

6. Network policy tests
- Inbound: default bind is reachable only as configured; `openFirewall = false` keeps host firewall closed; `openFirewall = true` opens only instance port.
- Outbound: CIDR allowlist permits approved destinations and blocks non-approved ranges.
- Logging: blocked outbound attempts emit rate-limited log entries including enough context (instance + destination) for operator whitelist decisions.

7. Environment and secret ingestion tests
- `environment` variables are present in service runtime.
- `environmentFile` values are loaded and override/merge according to precedence rules.
- sops-nix style `/run/secrets/*` paths work at runtime.
- Default HOME equals `stateDir` and opencode can read/write `$HOME/.local/share/opencode`.
- Ensure secret values are not materialized into derivation outputs or world-readable config files.

7b. Config materialization and extensibility tests
- Generated opencode config is available at `$HOME/.config/opencode/opencode.json` via symlink.
- Declaratively projected extension content (for example skills/agents) can coexist under `$HOME/.config/opencode/`.

8. Regression and compatibility tests
- Existing opencode config generation/wrapping behavior continues to work.
- NixOS module uses the same opencode.json generation path as existing machinery.
- Overlay-based package resolution remains system-correct and architecture-agnostic.

Rollback:
- Disable `services.opencode.enable` and remove instance definitions.
- Revert module addition in flake outputs if broader issues appear.

## Open Questions

- Which exact opencode CLI flags are considered stable enough for first-class typed options vs `extraArgs` only?
- Should outbound CIDR policy be enforced strictly per instance identity or initially at host/service group scope with documented limitations?
- Do we require default loopback bind (`127.0.0.1`) unless `openFirewall = true`, or allow explicit non-loopback bind without firewall opening?
- Should Unix socket allow rules support glob/prefix patterns or only exact paths for deterministic policy review?
- Should we additionally support `environmentFiles` (list) in a follow-up, while keeping `environmentFile` as the required baseline option?
