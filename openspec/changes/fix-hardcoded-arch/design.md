## Context

`flake.nix` currently hardcodes `x86_64-linux` for helper package resolution in three places: default `opencode` selection and `nixpkgs.legacyPackages` lookup inside both helper entrypoints. That prevents correct behavior on other supported systems.

We also have no downstream consumers yet, so this is the right point to correct API shape instead of preserving a transitional interface. An overlay-based entrypoint gives system-specific `final`/`prev` for free and avoids threading `system` manually through a secondary helper API.

## Goals / Non-Goals

**Goals:**
- Remove `x86_64-linux` hardcoding from helper internals.
- Make overlay-backed helpers resolve from the caller's package set (`final`/`prev`) per system.
- Establish `pkgs.lib.opencode` as the canonical API surface before adoption.
- Preserve helper behavior (module evaluation, wrapper semantics) while changing integration shape.

**Non-Goals:**
- Preserving backward compatibility for provisional `outputs.lib` helper entrypoints.
- Changing unrelated capabilities or runtime behavior of opencode configuration semantics.
- Introducing new external dependencies.

## Decisions

### 1) Use overlay as the primary API boundary

Expose helpers through `overlays.default` under `pkgs.lib.opencode`.

**Why:** Overlay evaluation already carries the active system package set. This avoids manual system pluming and makes helper behavior composition-friendly with other overlays.

**Alternative considered:** Keep `outputs.lib` and add `forSystem`-style helper selectors.

**Why not:** More API surface, duplicated integration paths, and less idiomatic nixpkgs composition than overlays.

### 2) Keep `mkLib` as implementation seam, but bind it to overlay `final`

Keep `mkLib` for helper implementation and instantiate it with overlay `final` so helper internals use system-correct packages.

**Why:** Maintains local implementation structure while changing only package-set sourcing and API placement.

**Alternative considered:** Rework helper internals into a different module architecture.

**Why not:** Unnecessary for solving system correctness and API shape in this change.

### 3) Resolve default opencode from the same overlay-bound package set

When `wrapOpenCode` receives no explicit `opencode`, default it from the same overlay-resolved system context used for helper execution.

**Why:** Prevents cross-system mismatches and fully removes `x86_64-linux` coupling.

**Alternative considered:** Unpin `pkgs` only.

**Why not:** Leaves wrapper default behavior partially broken on non-x86 systems.

### 4) Prefer one canonical integration path

Do not keep parallel first-class helper APIs. Treat overlay-backed `pkgs.lib.opencode.*` as canonical.

**Why:** No consumers exist yet, so minimizing long-term API ambiguity is higher value than preserving temporary compatibility shims.

## Risks / Trade-offs

- [Overlay API break for anyone using provisional `outputs.lib`] -> Accept as intentional now; document canonical API clearly.
- [Overlay composition conflicts from mutating `lib`] -> Keep scope narrow to `lib.opencode` namespace and preserve existing `prev.lib` members.
- [System/opencode mismatch regressions] -> Ensure one source of truth for selected package set is reused for helper execution and wrapper defaults.
- [Coverage gaps on non-x86 systems] -> Add checks that evaluate overlay usage on at least one non-x86 path.

## Migration Plan

1. Add `overlays.default` that exposes `pkgs.lib.opencode` and binds helper implementation to overlay `final`.
2. Move canonical helper usage and docs to `pkgs.lib.opencode.mkOpenCodeConfig` / `pkgs.lib.opencode.wrapOpenCode`.
3. Remove `x86_64-linux`-pinned helper wiring.
4. Update checks to validate overlay path and non-x86 evaluation.

Rollback strategy: restore previous helper wiring and defer overlay-first API decision to a follow-up change.

## Open Questions

- None for this change; decision is to pivot now to overlay-first API.
