## Context

`opencode-nix` can already generate valid `opencode.json` for the majority of fields, but several upstream schema shapes are still unrepresentable in the Nix module layer:

- provider registry metadata (`provider.<id>.npm`, `provider.<id>.name`, `provider.<id>.models.*`)
- nested permission maps (`permission.external_directory`, `permission.skill.<name>`)
- agent compatibility fields (`agent.<name>.primary`)
- provider option keys outside the currently hardcoded subset (`region`, `profile`, and other provider-specific options)

The result is a migration gap: real configs can only be partially ported, examples contain limitation notes, and parity tests cannot assert complete round-trip coverage.

This design closes that gap while preserving existing config behavior and the current JSON cleaning pipeline (`null` removal, empty-object elision, false preservation).

## Goals / Non-Goals

**Goals:**
- Achieve representational parity for all currently unsupported fields identified in the proposal.
- Keep existing typed options intact for current users while adding forward-compatible extensibility.
- Preserve deterministic JSON emission semantics from `mkOpenCodeConfig`.
- Add parity tests proving the new shapes serialize and pass upstream Zod validation.

**Non-Goals:**
- Re-model every upstream schema field into exhaustive strict Nix types in one pass.
- Implement runtime behavior changes in opencode itself.
- Remove existing options or introduce breaking renames.

## Decisions

### 1) Provider model: typed core + extensible metadata

Decision:
- Extend `opencode.provider.<id>` with first-class fields for `npm`, `name`, and `models`.
- Add `models` as `attrsOf (submodule ...)` with typed core metadata:
  - `name`, `tools`, `tool_call`, `reasoning`, `attachment`, `temperature`
  - `limit.context`, `limit.output`
  - `modalities.input`, `modalities.output`
- Expand provider `options` to support provider-specific keys beyond the existing fixed set.

Rationale:
- This directly covers real-world configs and eliminates the largest documented gap.
- Typed core fields improve editor discoverability and error quality.
- Allowing provider-specific option keys avoids repeated churn for vendor-specific fields.

Alternatives considered:
- **Pure freeform provider attrsets**: easiest but loses type safety and documentation quality.
- **Strict exhaustive modeling only**: highest precision but high maintenance and slower schema catch-up.

### 2) Permission model: hierarchical permission node type

Decision:
- Replace flat permission value typing with a hierarchical node type where values can be:
  - action leaves (`"allow" | "ask" | "deny"`)
  - nested maps for scoped policies (for example `external_directory` path rules and `skill.<name>` overrides)

Rationale:
- Matches upstream schema usage patterns and current user configs.
- Unblocks path-scoped and skill-scoped policies without special-casing one-off keys.

Alternatives considered:
- **Special-case only `external_directory` and `skill`**: smaller change now, but brittle as new nested scopes appear.
- **Keep flat type + JSON override escape hatch**: preserves status quo but fails parity goal.

### 3) Agent compatibility flags: support `primary` with explicit normalization rules

Decision:
- Add optional `agent.<name>.primary` boolean.
- Define normalization precedence during config emission:
  1. If `mode` is explicitly set, keep `mode` as source of truth.
  2. If `mode` is unset and `primary = true`, emit `mode = "primary"`.
  3. Preserve explicit `primary` field when user sets it for schema compatibility.

Rationale:
- Maintains backward compatibility with legacy configs while aligning with current mode semantics.
- Avoids breaking existing configs that already use `mode`.

Alternatives considered:
- **Map `primary` to `mode` and drop `primary` at output**: cleaner JSON but not parity-preserving.
- **Allow both without normalization**: ambiguous behavior when values conflict.

### 4) Validation strategy: parity fixtures + Zod-backed checks

Decision:
- Add parity fixtures covering each previously unsupported shape.
- Add one end-to-end fixture matching the full migrated config style (multi-provider + nested permissions + compatibility flags).
- Continue validating via upstream `Config.Info` Zod schema in `config-zod-tests`.

Rationale:
- Keeps "100% support" measurable and regression-resistant.
- Uses upstream validation as canonical correctness oracle.

Alternatives considered:
- **Unit-only tests on emitted JSON text**: faster but weaker than schema validation.

## Risks / Trade-offs

- **[Risk] Type complexity increases for providers and permissions** → Mitigation: keep typed core fields, constrain recursion depth where practical, and add clear option docs/examples.
- **[Risk] Overly permissive freeform options reduce type precision** → Mitigation: prefer typed fields first; isolate freeform support to provider-specific option maps.
- **[Risk] `primary` + `mode` conflict confusion** → Mitigation: document precedence and add dedicated conflict test scenarios.
- **[Risk] Upstream schema drift** → Mitigation: keep Zod-based CI checks and expand parity fixture coverage.

## Migration Plan

1. Implement option type extensions in providers, permissions, and agents modules.
2. Update normalization/cleaning logic for compatibility mapping (`primary`/`mode`) without altering existing outputs unexpectedly.
3. Add/expand Zod parity tests for each new field family.
4. Update example modules and README docs to remove "not yet supported" limitation notes.
5. Run full `nix flake check` and schema test suite in CI.

Rollback strategy:
- Revert option extensions and normalization changes while keeping existing stable option behavior.
- Keep previous tests as baseline; parity tests can be disabled/reverted with the same change rollback.

## Open Questions

- Should provider `options` be modeled as a typed known-key set plus `extraOptions`, or as a freeform map with optional typed aliases?
- For `primary=false` with `mode="primary"`, should we emit both verbatim or flag as configuration error?
- Do we want to enforce key-pattern validation for `external_directory` path rules (glob-like constraints) or treat keys as opaque strings?
