## 1. Implement overlay-first helper API

- [ ] 1.1 Add `overlays.default` in `flake.nix` that exposes helper functions under `pkgs.lib.opencode`.
- [ ] 1.2 Instantiate helper implementation with overlay `final` so helper package access is system-specific by construction.
- [ ] 1.3 Refactor `wrapOpenCode` default opencode selection to use overlay-selected system context and remove all hardcoded `x86_64-linux` paths.
- [ ] 1.4 Remove or demote provisional `outputs.lib` helper wiring so `pkgs.lib.opencode.*` is the canonical interface.

## 2. Validate capability requirements

- [ ] 2.1 Add/update checks that instantiate nixpkgs with `self.overlays.default` and call `pkgs.lib.opencode.mkOpenCodeConfig`.
- [ ] 2.2 Add/update checks that instantiate nixpkgs with `self.overlays.default` and call `pkgs.lib.opencode.wrapOpenCode` without explicit `opencode`.
- [ ] 2.3 Confirm non-x86_64 evaluation path succeeds and does not require `x86_64-linux` package resolution.
- [ ] 2.4 Re-run existing config-generation checks to confirm JSON output semantics remain unchanged.

## 3. Close out and document behavior

- [ ] 3.1 Document canonical usage via overlay (`pkgs.lib.opencode.*`) and include a migration note for any local experiments using old `outputs.lib` helpers.
- [ ] 3.2 Verify `nix flake check` (or equivalent project checks) passes for current system and capture any follow-up items.
