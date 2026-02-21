## Why

The current helper wiring hardcodes `x86_64-linux` for both `nixpkgs` and `opencode`, which breaks evaluation on other supported systems. While fixing that, we should also correct the public API shape before adoption: expose the helpers through an overlay so they naturally resolve against the caller's system-specific `final`/`prev` package set.

## What Changes

- Introduce an overlay-first API that exposes helper functions under `pkgs.lib.opencode`.
- Move helper resolution (`pkgs` and default `opencode`) to overlay evaluation context (`final`/`prev`) instead of hardcoded architecture selection.
- Remove reliance on fixed `outputs.lib` helper wiring as the primary integration path.
- Ensure helper behavior is consistent across all supported systems.

## Capabilities

### Modified Capabilities

- `mk-opencode-config`: Update requirements to use overlay-based API (`pkgs.lib.opencode.mkOpenCodeConfig`) with system-aware package resolution.
- `wrap-opencode`: Update requirements to use overlay-based API (`pkgs.lib.opencode.wrapOpenCode`) with system-aware default package resolution.

## Impact

- Affected code: `flake.nix` overlay and helper wiring (`overlays.default`, helper namespace placement, package resolution).
- Affected API: helper entrypoints move to overlay-backed namespace (`pkgs.lib.opencode.*`) as the canonical interface.
- Affected behavior: default package selection and wrapper/config generation become system-correct without hardcoded architecture.
- Affected validation: checks must exercise overlay usage and at least one non-x86_64 system path.
