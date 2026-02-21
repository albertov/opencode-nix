# AGENTS.md — ocnix project conventions

## Repo layout

```
flake.nix                          # outputs: overlays.default, nixosModules, checks, nixosTests, examples
nix/config/lib.nix                 # { mkOpenCodeConfig, wrapOpenCode } — core config helpers
nix/config/default.nix             # module system root (imports options/*)
nix/config/options/                # typed opencode.json option files
nix/nixos/module.nix               # NixOS multi-instance service module
nix/nixos/tests/                   # eval-tests.nix + VM test skeletons
nix/tests/                         # Zod schema validation (Bun/Node)
examples/                          # importable example module configs
```

## Canonical API surface

| Output | How to use |
|--------|-----------|
| `overlays.default` | `pkgs.extend ocnix.overlays.default` → unlocks `pkgs.lib.opencode.*` |
| `pkgs.lib.opencode.mkOpenCodeConfig modules` | Generates opencode.json store path from NixOS modules |
| `pkgs.lib.opencode.wrapOpenCode { name, modules, opencode }` | Wraps opencode binary with baked-in config via `OPENCODE_CONFIG` |
| `nixosModules.opencode` | NixOS module: `services.opencode.instances.<name>` |
| `checks.*` | `nix flake check` — runs on all systems (+ VM tests on x86_64-linux) |
| `nixosTests.*` | `nix build .#nixosTests.<name>` — individual VM tests |

## Hard invariants — never violate

- **No `self.lib.*` entrypoints** — all helpers are under `pkgs.lib.opencode` via the overlay
- **No hardcoded `x86_64-linux`** — use `pkgs.system` or `forAllSystems`; examples may pin a system but must use overlay-applied pkgs
- **No secrets in Nix store** — credentials go in `environmentFile` at runtime, never in module options
- **Sandbox closed by default** — `readWritePaths`/`readOnlyPaths`/`unixSockets.allow` are opt-in
- **All CLI flags via typed options or `extraArgs`** — no raw string command construction outside the module
- **`stateDir != directory`** — enforced by module assertion; stateDir is runtime state, directory is the project worktree

## NixOS test conventions

- **Assert behavior, not internals** — every VM test MUST assert the service is up and responding via HTTP (`GET /global/health`), not just that files were written or units exist
- **No stub binaries** — all VM tests use the real `pkgs.opencode` binary from the overlay; never use `writeShellScriptBin "opencode" "exec sleep infinity"`
- **Shared health check** — use `pkgs.writeText` to write a Python healthcheck script and run it with `python3` (add `pkgs.python3` to `environment.systemPackages`); never use heredocs in testScript
- **Minimum per-test assertions**: `wait_for_unit(setup)` → `wait_for_unit(main)` → `wait_for_open_port` → health check → feature-specific behavioral assertions

## Running checks

```bash
nix flake check                          # all eval + VM tests on x86_64-linux
nix build .#nixosTests.<name>            # individual VM test (requires KVM)
nix eval .#overlays.default              # sanity-check overlay evaluates
```

## Commit conventions

| Prefix | When |
|--------|------|
| `GREEN: <bead-ids>:` | Implementation complete, all gates pass |
| `RED: <bead-ids>:` | Failing tests committed (TDD red phase) |
| `FIX-BASELINE:` | Pre-existing lint/warning cleanup |

## Test locations

| Test | File | Runs in |
|------|------|---------|
| Empty config | `checks.empty-config` | `nix flake check` |
| Zod schema | `nix/tests/default.nix` | `nix flake check` |
| Module eval | `nix/nixos/tests/eval-tests.nix` | `nix flake check` |
| VM tests | `nix/nixos/tests/*.nix` | `nix build .#nixosTests.*` / `nix flake check` on x86_64-linux |

## Key module options (nix/nixos/module.nix)

`services.opencode.instances.<name>`: `directory` (required), `stateDir`, `listen.{address,port}`, `openFirewall`, `environment`, `environmentFile`, `path`, `logLevel`, `model`, `provider`, `extraArgs`, `sandbox.{readWritePaths,readOnlyPaths,unixSockets.allow}`, `networkIsolation.{enable,outboundAllowCidrs}`, `preInitScript`, `postInitScript`, `opencodeCfg`
