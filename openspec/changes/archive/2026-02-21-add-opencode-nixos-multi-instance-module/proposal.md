## Why

We need a first-class NixOS module for running multiple isolated opencode server instances with an API shape similar to virtual hosts, while preserving the overlay-first direction. Today there is no standardized way to define per-project opencode services with strong sandboxing, sensible headless defaults, and configurable network boundaries.

## What Changes

- Add a NixOS module exposing `services.opencode.instances.<name>` for multi-instance opencode service management.
- Define per-instance options for working directory, runtime identity, listen configuration, and relevant headless CLI flags with safe defaults.
- Configure each instance as a dedicated systemd unit with cgroup-based isolation and hardening suitable for long-running server operation.
- Add configurable network isolation controls per instance, including outbound allow-list by CIDR, inbound restriction to the configured listen port, and logging for blocked outbound attempts to support iterative allow-list tuning.
- Add an `openFirewall` option so operators can intentionally expose the listening port through host firewall rules.
- Add strict per-instance filesystem and namespace isolation with configurable read-write/read-only path allowlists (defaults: instance `directory` read-write, `/nix/store` read-only).
- Add explicit allow mechanisms for selected Unix socket sharing (for example nix-daemon or database sockets) while keeping sandbox defaults closed.
- Add declarative per-instance environment variable options and an `environmentFile` option for secret-backed variables.
- Ensure secret file integration works with common NixOS secret managers (for example sops-nix paths under `/run/secrets/*`) without embedding secret values in the Nix store.
- Add a per-instance `path` option wired to systemd service `path` so operators can inject CLI tools available to opencode runtime.
- Set sandbox `HOME` equal to per-instance `stateDir` so opencode state naturally lives under `$HOME/.local/share/opencode` as expected.
- Materialize generated config as `$HOME/.config/opencode/opencode.json` (symlink to generated file) and leave room for declarative extension content (for example skills/agents) under `$HOME/.config/opencode/`.
- Integrate the NixOS module with existing opencode.json generation machinery so each instance can declaratively define the opencode config consumed at runtime.
- Add a dedicated per-instance persistent state directory model (default `/var/lib/opencode/instance-state/<instance-name>`) separate from instance `directory`.
- Add a dedicated per-instance setup service that initializes instance state only when state is uninitialized, and never initializes or mutates instance `directory`.
- Add optional per-instance setup lifecycle hooks (`preInitScript`, `postInitScript`) so operators can run custom logic before/after module-managed setup steps.
- Enforce cross-instance state isolation so one instance cannot access another instance's state directory.
- Ensure state directory layout is operator-manageable for host-side backup/restore workflows outside the sandbox.

## Capabilities

### New Capabilities
- `opencode-nixos-multi-instance-service`: Declarative multi-instance NixOS service API under `services.opencode.instances.<name>` with virtual-host-style instance definitions.
- `opencode-instance-runtime-options`: Per-instance mapping of supported headless opencode CLI options with sensible defaults and explicit validation.
- `opencode-instance-environment`: Per-instance environment configuration (`environment`, `environmentFile`, and `HOME = stateDir`) with deterministic merge/precedence behavior and secret-friendly file references.
- `opencode-instance-isolation`: Systemd/cgroup and namespace isolation profile per instance (users/groups, filesystem mounts, `/proc` and process visibility, kernel protection flags, resource controls, service hardening).
- `opencode-instance-network-policy`: Per-instance network policy controls for outbound CIDR allow-lists, inbound listen-port restriction, and optional firewall opening.

### Modified Capabilities
- `nix-config-module`: Extend requirements to include NixOS service integration through existing opencode.json machinery for per-instance runtime config, not only static config generation.

## Impact

- Affected code: NixOS module definitions, flake exports for module consumption, service/wrapper integration, and related tests.
- Affected systems: NixOS hosts running one or more opencode instances.
- Security impact: Introduces explicit sandbox/network policy surface that must be default-safe and auditable.
- Data durability impact: Introduces per-instance persistent state directories that must remain isolated and backup-friendly.
- Runtime ergonomics impact: Introduces explicit service `path` injection and sandbox HOME semantics for CLI/tool compatibility.
- Operational impact: Enables multi-tenant/project opencode hosting with per-instance isolation and firewall behavior controls.
