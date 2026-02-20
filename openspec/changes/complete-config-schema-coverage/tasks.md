## 1. Extend Nix Option Models

- [ ] 1.1 Extend `nix/config/options/providers.nix` to support provider metadata fields (`npm`, `name`, `models`) and provider-specific option keys.
- [ ] 1.2 Add typed provider model metadata fields (`name`, capability flags, `limit`, `modalities`) under `provider.<id>.models.<model-id>`.
- [ ] 1.3 Replace flat permission typing in `nix/config/options/permissions.nix` with hierarchical permission nodes supporting nested maps.
- [ ] 1.4 Extend `nix/config/options/agents.nix` with optional `primary` compatibility flag and document `mode`/`primary` behavior.

## 2. Serialization and Normalization

- [ ] 2.1 Implement `primary`/`mode` precedence handling in config emission so explicit `mode` remains authoritative.
- [ ] 2.2 Ensure JSON cleaning preserves nested permission objects and provider model metadata while still removing null/empty attrsets.
- [ ] 2.3 Add/adjust validation around conflicting `primary` and `mode` combinations per documented precedence rules.

## 3. Parity Test Coverage

- [ ] 3.1 Add Zod-backed tests for provider metadata fields (`npm`, `name`, `models`, provider-specific options like `region/profile`).
- [ ] 3.2 Add Zod-backed tests for nested permissions (`external_directory` path maps and `skill.<name>` maps).
- [ ] 3.3 Add Zod-backed tests for agent `primary` compatibility and `mode` precedence scenarios.
- [ ] 3.4 Add one realistic end-to-end parity fixture matching a migrated multi-provider config and validate it through `config-zod-tests`.

## 4. Examples and Documentation

- [ ] 4.1 Update `examples/chief-coding-assistant` modules to use newly supported fields instead of limitation comments.
- [ ] 4.2 Update `examples/chief-coding-assistant/README.md` and repository docs to remove obsolete limitation notes and describe full schema support.
- [ ] 4.3 Run `nix flake check` and verify all parity tests pass in CI-compatible check outputs.
