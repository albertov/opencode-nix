## 1. Module scaffolding and flake wiring

- [x] 1.1 Add a new NixOS module file for `services.opencode.instances.<name>` and expose it from `nixosModules` in `flake.nix`.
- [x] 1.2 Define top-level options (`enable`, `defaults`, `instances`) and typed per-instance submodule structure.
- [x] 1.3 Implement defaults merge semantics so instance values override `services.opencode.defaults` deterministically.

## 2. Runtime option model and command projection

- [x] 2.1 Add typed headless runtime options (listen, logging, provider/model, limits, feature flags) with safe defaults for unattended service mode.
- [x] 2.2 Implement deterministic CLI argument rendering from typed options plus ordered `extraArgs` append behavior.
- [x] 2.3 Add validation for invalid enum/range values with actionable evaluation errors.

## 3. Per-instance service and setup units

- [x] 3.1 Generate one main unit per enabled instance (`systemd.services.opencode-<name>`) with appropriate restart behavior and `WorkingDirectory`.
- [x] 3.2 Generate one setup unit per enabled instance that runs before main service and initializes only uninitialized `stateDir`.
- [x] 3.3 Make setup idempotent on repeated runs and ensure it never initializes or mutates instance `directory`.
- [x] 3.4 Ensure setup does not perform ad-hoc state migrations and leaves migration behavior to opencode runtime.
- [x] 3.5 Add per-instance `path` option and wire it to systemd service `path` for runtime CLI tool injection.
- [x] 3.6 Set default sandbox HOME to `stateDir`.
- [x] 3.7 In setup unit, incrementally prepare `$HOME/.local/share/opencode` and `$HOME/.config/opencode` without destructive rewrites.
- [x] 3.8 Add optional `preInitScript` and `postInitScript` instance options and execute them in setup phase with deterministic ordering.
- [x] 3.9 Enforce hook failure semantics: non-zero pre/post hook exit fails setup and blocks main service start.

## 4. Config generation and environment integration

- [x] 4.1 Integrate instance config generation with existing opencode.json machinery (reuse current pipeline, no second renderer).
- [x] 4.2 Ensure per-instance config artifacts are isolated so values cannot leak between instances.
- [x] 4.2a Materialize generated config at `$HOME/.config/opencode/opencode.json` via symlink to generated artifact.
- [x] 4.2b Support declarative extension content via generated config (for example `opencode.skills.paths`) while preserving the `$HOME/.config/opencode/opencode.json` symlink contract.
- [x] 4.3 Add `environment` option wiring to unit environment and `environmentFile` wiring to systemd `EnvironmentFile=`.
- [x] 4.4 Enforce precedence `module-required -> environment -> environmentFile` and ensure secrets come from runtime file paths (including `/run/secrets/*`).
- [x] 4.5 Verify secret values are not embedded in generated static config or derivation outputs.

## 5. Filesystem, process, and state isolation

- [x] 5.1 Implement default filesystem sandbox policy: RW `directory` + RW `stateDir`, RO `/nix/store`, deny writes elsewhere unless allowlisted.
- [x] 5.2 Add `sandbox.readWritePaths`, `sandbox.readOnlyPaths`, and `sandbox.unixSockets.allow` explicit extension points.
- [x] 5.3 Apply process and kernel hardening (`ProtectProc`, `ProcSubset`, kernel/module/cgroup protections) with explicit override hooks.
- [x] 5.4 Introduce default per-instance state path `/var/lib/opencode/instance-state/<name>` and route opencode state writes there.
- [x] 5.5 Enforce cross-instance state isolation so instance A cannot read/write instance B state root.
- [x] 5.6 Ensure state roots remain stable host paths suitable for operator backup/restore workflows.

## 6. Network policy and observability

- [x] 6.1 Implement inbound bind restrictions from `listen.address`/`listen.port` and default `openFirewall = false` behavior.
- [x] 6.2 Implement optional firewall opening for only the configured instance port when `openFirewall = true`.
- [x] 6.3 Implement outbound CIDR allow-list enforcement per instance identity using nftables/ipset-backed policy.
- [x] 6.4 Fail safely when outbound isolation is enabled but policy backend cannot be activated.
- [x] 6.5 Add blocked outbound attempt logging with rate limiting and instance/destination context for allow-list tuning.

## 7. Comprehensive NixOS test coverage

- [x] 7.1 Add module evaluation tests for option typing/defaults and rendered unit fields (including `ExecStart`, hardening flags, and `EnvironmentFile=`).
- [x] 7.2 Add VM tests with at least two instances validating independent startup, health, and restart isolation.
- [x] 7.3 Add filesystem and sandbox tests (default deny behavior, allowlist positive cases, disallowed path/socket negative cases).
- [x] 7.4 Add state tests for default `stateDir`, separation from `directory`, cross-instance denial, and backup-friendly host path behavior.
- [x] 7.5 Add setup service tests for first-run initialization, idempotent reruns, and no `directory` mutation.
- [x] 7.6 Add network tests for inbound/firewall behavior, outbound allow/block behavior, and blocked-attempt log observability with rate limiting. _Evidence: nix/nixos/tests/network-policy.nix (multi-node behavioral test), nix/nixos/tests/open-firewall.nix (openFirewall VM test), nix/nixos/tests/eval-tests.nix (firewall eval tests)._
- [x] 7.7 Add environment tests for `environment` injection, `environmentFile` loading, precedence order, and `/run/secrets/*` compatibility.
- [x] 7.8 Add regression tests proving module path reuses existing opencode.json generation machinery.
- [x] 7.9 Add tests verifying `path` injection makes declared tools available and default HOME is writable/instance-scoped.
- [x] 7.10 Add tests verifying `HOME = stateDir`, incremental setup of HOME subpaths, and non-destructive behavior on reruns.
- [x] 7.11 Add tests verifying `$HOME/.config/opencode/opencode.json` symlink target correctness and coexistence with declarative extension pathways (for example `opencode.skills.paths`).
- [x] 7.12 Add setup hook tests verifying pre-before-core-before-post ordering and that hook failures fail setup. _Evidence: nix/nixos/tests/hook-ordering.nix (timestamp ordering), nix/nixos/tests/hook-failure.nix (exit 1 blocks service)._

## 8. Documentation and rollout checks

- [x] 8.1 Document canonical module usage with multi-instance examples, security defaults, and explicit allowlist patterns.
- [x] 8.2 Document state directory operational guidance (backup/restore, permissions, and isolation expectations).
- [x] 8.3 Document network troubleshooting workflow using blocked-outbound logs to iteratively tune CIDR allow-lists. _Evidence: nix/nixos/README.md "Network Policy Troubleshooting" section._
- [x] 8.4 Run project verification commands (including NixOS/module tests and `nix flake check`) and capture follow-up issues.
