## Context

This change adds a Nix module system for generating `opencode.json` config files. The opencode config uses a strict Zod schema (no extra fields allowed) with 50+ root-level fields covering agents, providers, MCP servers, permissions, keybinds, TUI settings, LSP, formatters, and experimental flags. Today users hand-edit JSON, which is error-prone and undiscoverable.

The deliverable is a flake exposing `lib.mkOpenCodeConfig` that takes a list of Nix modules, evaluates them via the NixOS module system, and produces a derivation writing `opencode.json`.

## Goals

- Model the **complete** opencode.json schema as Nix module options with types, defaults, and documentation
- Expose `lib.mkOpenCodeConfig :: [Module] → Derivation` from the flake
- Validate generated JSON against the upstream Zod schema in automated tests
- Every option is documented inline via `mkOption { description = ... }`
- Purely additive — no changes to existing files

## Non-Goals

- Runtime config management or symlink-based activation (this just produces a file)
- NixOS/home-manager module integration (future work, but the option types are reusable)
- Supporting deprecated fields (`mode`, `tools`, `autoshare`, `layout`, `maxSteps`) — users should use the current equivalents
- NixOS/home-manager module integration (future work)

## Decisions

### D1: Use `lib.evalModules` for module evaluation

**Choice**: Use `lib.evalModules` directly rather than a NixOS module or home-manager module.

**Why**: `lib.evalModules` is the primitive that NixOS modules and home-manager modules are built on. Using it directly means:
- No dependency on NixOS or home-manager
- The same option definitions can later be wrapped as a NixOS module or HM module
- Users get the full module system: merging, overriding, `mkIf`, `mkForce`, `mkDefault`, imports

**Trade-off**: Users unfamiliar with `evalModules` may find `mkOpenCodeConfig` slightly less obvious than a NixOS option like `programs.opencode.settings = { ... }`. But the module list interface is idiomatic Nix and well-documented.

### D2: One Nix file per config section, one root module that imports them all

**Choice**: Structure as:
```
nix/
  config/
    module.nix          # root module — imports all section modules
    options/
      agents.nix        # agent.<name>.{model, steps, ...}
      providers.nix     # provider.<name>.{apiKey, baseURL, ...}
      mcp.nix           # mcp.<name>.{type, command, url, ...}
      permissions.nix   # permission.<tool>
      keybinds.nix      # keybinds.<action>
      commands.nix      # command.<name>.{template, ...}
      tui.nix           # tui.{scroll_speed, ...}
      server.nix        # server.{port, hostname, ...}
      lsp.nix           # lsp.<name>.{command, extensions, ...}
      formatter.nix     # formatter.<name>.{command, ...}
      skills.nix        # skills.{paths, urls}
      compaction.nix    # compaction.{auto, prune, reserved}
      watcher.nix       # watcher.{ignore}
      experimental.nix  # experimental.{batch_tool, ...}
      enterprise.nix    # enterprise.{url}
      top-level.nix     # scalar root fields: theme, logLevel, model, etc.
    lib.nix             # mkOpenCodeConfig implementation
```

**Why**: Each file stays small and reviewable. Adding a new section is isolated. The `module.nix` file just imports the list and defines no options itself. This mirrors how NixOS modules are organized.

### D3: Nix types mirror Zod types precisely

**Mapping**:

| Zod Type | Nix Type | Notes |
|----------|----------|-------|
| `z.string()` | `types.str` | |
| `z.string().optional()` | `types.nullOr types.str` | null = omit from JSON |
| `z.number()` | `types.number` | |
| `z.number().int().positive()` | `types.ints.positive` | |
| `z.boolean()` | `types.bool` | |
| `z.enum([...])` | `types.enum [...]` | |
| `z.union([z.boolean(), z.literal("notify")])` | `types.either types.bool (types.enum ["notify"])` | for `autoupdate` |
| `z.record(z.string(), T)` | `types.attrsOf T` | |
| `z.array(z.string())` | `types.listOf types.str` | |
| `z.object({...}).strict()` | `types.submodule { options = {...}; }` | strict = we don't add extras |
| `z.discriminatedUnion("type", [...])` | `types.submodule` with `type` enum + `mkIf`-guarded options | MCP local vs remote |
| `z.literal(false) \| z.record(...)` | `types.either (types.enum [false]) (types.attrsOf ...)` | LSP/formatter disable-all |

**Key constraint**: The Zod schema uses `.strict()`, meaning any unrecognized field causes validation failure. Our Nix types must not introduce spurious fields. We use `lib.filterAttrsRecursive (n: v: v != null)` to strip `null` values before serializing.

### D4: `mkOpenCodeConfig` returns a derivation

**Signature**:
```nix
mkOpenCodeConfig :: [Module] -> Derivation
```

**Implementation sketch**:
```nix
mkOpenCodeConfig = modules:
  let
    evaluated = lib.evalModules {
      modules = [ ./config/module.nix ] ++ modules;
    };
    configJSON = builtins.toJSON (cleanConfig evaluated.config.opencode);
  in
    pkgs.writeText "opencode.json" configJSON;
```

**Why a derivation, not a raw attrset**: Derivations integrate with `nix build`, CI, and deployment. Users can `nix build .#opencode-config` and get the file. They can also use `.outPath` or `builtins.readFile` if they need the content.

The `cleanConfig` function recursively strips `null` values and converts Nix types to JSON-compatible values (e.g., `true`/`false` stay as-is, enums become strings).

### D5: Test strategy — validate JSON against upstream Zod schema via flake input

**Source of truth**: The opencode source is a **flake input**, not the gitignored `./opencode` directory (which exists only for developer exploration). This means:
- `nix flake update` in CI automatically picks up schema changes
- Tests always validate against a pinned, reproducible version of the Zod schema
- No gitignored artifacts are referenced by any derivation

**Flake input**:
```nix
inputs.opencode-src = {
  url = "github:anthropics/opencode";
  flake = false;  # raw source, not evaluated as a flake
};
```

**Approach**: Use `nix flake check` with a test derivation that:
1. Evaluates several test config modules via `mkOpenCodeConfig`
2. Installs the opencode source's dependencies from the flake input (`bun install` in `${inputs.opencode-src}`)
3. Runs a small Bun script that imports the Zod schema from the flake input source and validates each generated JSON: `Config.Info.parse(JSON.parse(...))`
4. If Zod parsing fails, the derivation fails → `nix flake check` fails

**Test cases**:
- Minimal config (empty modules list → `{}` or minimal valid config)
- Full config (every option populated)
- Section-specific configs (agents only, MCP only, etc.)
- Invalid configs (expect Zod failure — negative tests)

**Why Zod validation over JSON Schema**: The upstream uses Zod with `.strict()`, `.refine()`, and discriminated unions. A JSON Schema would be a lossy approximation. Validating against the actual Zod schema is the source of truth.

**Why a flake input, not `./opencode`**: The gitignored `./opencode` directory is for local developer exploration only. Using it in derivations would break reproducibility (Nix can't reference gitignored paths in pure evaluation) and prevent CI from tracking upstream changes automatically.

### D6: Documentation via `mkOption` descriptions

Every option gets a `description` in `mkOption`:

```nix
model = mkOption {
  type = types.nullOr types.str;
  default = null;
  description = ''
    Default model for all agents. Format: `provider/model-id`.
    Example: `"anthropic/claude-sonnet-4-20250514"`
  '';
  example = "anthropic/claude-sonnet-4-20250514";
};
```

This makes options discoverable via `nix repl`, `nixos-option`, and generated docs. No separate documentation file needed — the module system **is** the documentation.

### D7: Handle `{env:VAR}` and `{file:PATH}` substitution syntax

**Choice**: Pass these through as literal strings. They are runtime substitutions that opencode performs when loading the config. The Nix module just writes them verbatim into the JSON.

```nix
provider.anthropic.apiKey = "{env:ANTHROPIC_API_KEY}";
```

No special Nix type needed — `types.str` handles it.

### D8: MCP discriminated union modeling

The MCP config has two forms: `{type: "local", command: [...], ...}` and `{type: "remote", url: "...", ...}`. In Nix:

```nix
mcp = mkOption {
  type = types.attrsOf (types.submodule {
    options = {
      type = mkOption { type = types.enum [ "local" "remote" ]; };
      # local-specific
      command = mkOption { type = types.nullOr (types.listOf types.str); default = null; };
      environment = mkOption { type = types.nullOr (types.attrsOf types.str); default = null; };
      # remote-specific
      url = mkOption { type = types.nullOr types.str; default = null; };
      headers = mkOption { type = types.nullOr (types.attrsOf types.str); default = null; };
      oauth = mkOption { ... };
      # shared
      enabled = mkOption { type = types.nullOr types.bool; default = null; };
      timeout = mkOption { type = types.nullOr types.ints.positive; default = null; };
    };
  });
};
```

We rely on the Zod schema validation (in tests) to catch invalid combinations (e.g., local MCP with `url` set). This avoids complex `mkIf` logic in the Nix module while keeping the type precise enough for practical use.

### D9: `false` literals for LSP and formatter disable-all

Both `lsp` and `formatter` accept `false` (the boolean) to disable all servers/formatters. In Nix:

```nix
lsp = mkOption {
  type = types.oneOf [
    (types.enum [ false ])
    (types.attrsOf (types.submodule { ... }))
  ];
  default = {};
};
```

The `cleanConfig` function handles the `false` case: if the value is exactly `false`, emit `false` in JSON. Otherwise, emit the attrset.

### D10: GitHub Actions CI with Cachix

**Choice**: A `.github/workflows/check.yml` workflow that:
1. Triggers on push to `main` and on all pull requests
2. Installs Nix via `DeterminateSystems/nix-installer-action`
3. Configures Cachix via `cachix/cachix-action` for binary caching
4. Runs `nix flake check` (which exercises all test derivations)

**Workflow sketch**:
```yaml
name: Check
on:
  push:
    branches: [main]
  pull_request:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: cachix/cachix-action@v15
        with:
          name: <cachix-cache-name>
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
      - run: nix flake check
```

**Why Cachix**: Test derivations install bun dependencies and build from source — this is slow (~2-5 min). Cachix caches the results so subsequent runs are fast. Only schema changes or Nix option changes trigger rebuilds.

**Why `DeterminateSystems/nix-installer-action`**: It's faster and more reliable than the official `install-nix-action`, and enables flakes by default.

**Scope**: The workflow runs `nix flake check` only — it does not build the opencode binary or run opencode's own test suite. It validates that our Nix module generates valid configs.

### D11: `wrapOpenCode` — executable wrapping with generated config

**Choice**: A `lib.wrapOpenCode { name, modules }` function that produces a wrapped `opencode` derivation with the generated config baked in via `OPENCODE_CONFIG`.

**Mechanism**: Opencode supports the `OPENCODE_CONFIG` environment variable — when set, it loads the config file from that path (precedence level 3, above project-level config). This is the hook for our wrapper.

**Signature**:
```nix
wrapOpenCode :: { name :: String, modules :: [Module], opencode :: Derivation? } -> Derivation
```

**Implementation sketch**:
```nix
wrapOpenCode = { name ? "opencode", modules, opencode ? pkgs.opencode }:
  let
    configDrv = mkOpenCodeConfig modules;
  in
    pkgs.symlinkJoin {
      name = name;
      paths = [ opencode ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/opencode \
          --set OPENCODE_CONFIG "${configDrv}"
      '';
    };
```

**Key design points**:
- Uses `symlinkJoin` + `makeWrapper` — the standard Nix pattern for wrapping executables
- Sets `OPENCODE_CONFIG` to point at the generated `opencode.json` inside the config derivation
- Accepts an optional `opencode` argument defaulting to `pkgs.opencode`, so users can pin a specific version or use the one from the opencode flake's overlay
- The `name` parameter allows multiple wrapped variants (e.g., `opencode-work`, `opencode-personal`)
- The generated config is a separate derivation, so changing config doesn't rebuild opencode itself

**Why `OPENCODE_CONFIG` over `OPENCODE_CONFIG_CONTENT`**: The file-path approach is cleaner — the config lives in the Nix store as a proper file, avoids shell quoting issues with large JSON in env vars, and matches opencode's intended usage pattern.

**Why `symlinkJoin` over `wrapProgram` alone**: `symlinkJoin` creates a proper derivation with `bin/`, `share/`, etc. symlinked from the original, then `wrapProgram` modifies only the binary. This preserves shell completions, man pages, and other assets from the original opencode derivation.

## Risks and Trade-offs

### R1: Schema drift

**Risk**: The upstream opencode Zod schema evolves. Our Nix options could fall behind, causing generated configs to fail validation.

**Mitigation**: The opencode source is a flake input (`inputs.opencode-src`). Running `nix flake update` updates the pinned source, and `nix flake check` immediately catches any mismatches between our Nix options and the current Zod schema. CI can run `nix flake update && nix flake check` to detect drift proactively.

### R2: Strict mode false positives

**Risk**: The Zod schema uses `.strict()`. If our `cleanConfig` function fails to strip a `null` or introduces an unexpected field, validation fails.

**Mitigation**: `cleanConfig` is tested in isolation. The full-config test exercises every option to ensure no spurious fields leak through.

### R3: Complex nested types are hard to get right

**Risk**: Deeply nested types (e.g., `provider.<name>.models.<model>.variants.<variant>`) are error-prone in the module system.

**Mitigation**: Start with the most commonly used options. Less-used nested options (like per-model variants) can use `types.attrsOf types.anything` initially and be refined later. Tests will catch any serialization issues.

### R4: `types.anything` escape hatches reduce type safety

**Risk**: Using `types.anything` for complex subfields defeats the purpose of typed config.

**Mitigation**: Reserve `types.anything` only for `agent.*.options` (which is `Record<string, any>` upstream) and `lsp.*.initialization` (also arbitrary). Everything else gets a precise type. Document where escape hatches exist and why.
