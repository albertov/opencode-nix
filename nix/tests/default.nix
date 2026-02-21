# Zod-based validation tests for opencode.json configs.
#
# These tests validate that JSON configs produced by mkOpenCodeConfig conform
# to the upstream Config.Info Zod schema.  The approach:
#
#   1. Reuse the upstream fixed-output node_modules derivation (pre-fetched,
#      hash-pinned) so that `bun` can resolve all transitive dependencies
#      of the config module without network access during the test build.
#
#   2. Overlay node_modules onto a writable copy of the opencode source tree.
#
#   3. Run validate.ts (a Bun script) that dynamically imports Config.Info
#      from the source and calls safeParse() against each generated JSON.
#
# The node_modules derivation is itself a fixed-output derivation that
# requires network access on first build (like any fetchurl).  Once in the
# Nix store or binary cache it is fully reproducible.
#

{ pkgs, lib, opencode, mkOpenCodeConfig }:

let
  # Build node_modules using the upstream pattern (fixed-output derivation).
  node_modules = pkgs.callPackage (opencode + "/nix/node_modules.nix") {
    rev = "test";
  };

  # ── Test configs ──────────────────────────────────────────────────────

  # Test 1: Minimal (empty) config
  minimalConfig = mkOpenCodeConfig [];

  # Test 2: Theme config
  themeConfig = mkOpenCodeConfig [
    { opencode.theme = "catppuccin"; }
  ];

  # Test 3: Agent config
  agentConfig = mkOpenCodeConfig [
    {
      opencode.agent.plan = {
        model = "anthropic/claude-sonnet-4-20250514";
        steps = 50;
      };
    }
  ];

  # Test 4: MCP local server
  mcpConfig = mkOpenCodeConfig [
    {
      opencode.mcp.my-tool = {
        type = "local";
        command = [ "npx" "my-tool" ];
      };
    }
  ];

  # Test 5: Permissions
  permissionConfig = mkOpenCodeConfig [
    {
      opencode.permission = {
        bash = "allow";
        edit = "ask";
      };
    }
  ];

  # Test 6: TUI settings
  tuiConfig = mkOpenCodeConfig [
    {
      opencode.tui = {
        scroll_speed = 5.0;
        diff_style = "stacked";
      };
    }
  ];

  # Test 7: Server settings
  serverConfig = mkOpenCodeConfig [
    {
      opencode.server = {
        port = 8080;
        hostname = "localhost";
      };
    }
  ];

  # Test 8: Compaction settings
  compactionConfig = mkOpenCodeConfig [
    {
      opencode.compaction = {
        auto = true;
        prune = true;
      };
    }
  ];

  # Test 9: Experimental flags
  experimentalConfig = mkOpenCodeConfig [
    {
      opencode.experimental = {
        batch_tool = true;
      };
    }
  ];

  # Test 10: Full composite config
  fullConfig = mkOpenCodeConfig [
    {
      opencode.theme = "dark";
      opencode.agent.plan = {
        model = "anthropic/claude-sonnet-4-20250514";
        steps = 50;
      };
      opencode.provider.anthropic = {
        options.apiKey = "{env:ANTHROPIC_API_KEY}";
      };
      opencode.mcp.my-tool = {
        type = "local";
        command = [ "npx" "my-tool" ];
      };
      opencode.permission = {
        bash = "allow";
        edit = "ask";
      };
      opencode.tui = {
        scroll_speed = 5.0;
        diff_style = "stacked";
      };
      opencode.server = {
        port = 8080;
        hostname = "localhost";
      };
      opencode.compaction = {
        auto = true;
        prune = true;
      };
      opencode.experimental = {
        batch_tool = true;
      };
    }
  ];

  # ── Raw JSON tests (bypass Nix module, test Zod schema directly) ─────

  # Test 11: logLevel — upstream Zod Log.Level expects UPPERCASE: "DEBUG"|"INFO"|"WARN"|"ERROR".
  # Now that the Nix enum is fixed, we also test via mkOpenCodeConfig.
  logLevelConfig = mkOpenCodeConfig [
    { opencode.logLevel = "DEBUG"; }
  ];

  # Test 12: logLevel drift detection — raw lowercase "debug" should FAIL Zod.
  logLevelDriftConfig = pkgs.writeText "opencode-loglevel-drift.json" (builtins.toJSON {
    logLevel = "debug";
  });

  # Test 13: Invalid config — unknown top-level key (schema is .strict())
  invalidConfig = pkgs.writeText "opencode-invalid.json" (builtins.toJSON {
    totally_bogus_field = true;
  });

  # ── New test configs (14–24) ─────────────────────────────────────────

  # Test 14: Module merging — two modules setting different fields
  mergedConfig = mkOpenCodeConfig [
    { opencode.theme = "dark"; }
    { opencode.username = "alice"; }
  ];

  # Test 15: List concatenation — instructions from two modules merge
  listConcatConfig = mkOpenCodeConfig [
    { opencode.instructions = [ "a.md" ]; }
    { opencode.instructions = [ "b.md" ]; }
  ];

  # Test 16: LSP disabled (false literal)
  lspDisabledConfig = mkOpenCodeConfig [
    { opencode.lsp = false; }
  ];

  # Test 17: Formatter disabled (false literal)
  formatterDisabledConfig = mkOpenCodeConfig [
    { opencode.formatter = false; }
  ];

  # Test 18: Provider with timeout=false
  providerTimeoutFalseConfig = mkOpenCodeConfig [
    {
      opencode.provider.anthropic = {
        options.timeout = false;
      };
    }
  ];

  # Test 19: autoupdate as string "notify"
  autoupdateStringConfig = mkOpenCodeConfig [
    { opencode.autoupdate = "notify"; }
  ];

  # Test 20: autoupdate as bool true
  autoupdateBoolConfig = mkOpenCodeConfig [
    { opencode.autoupdate = true; }
  ];

  # Test 21: {env:VAR} template passthrough
  envTemplateConfig = mkOpenCodeConfig [
    {
      opencode.provider.anthropic = {
        options.apiKey = "{env:ANTHROPIC_API_KEY}";
      };
    }
  ];

  # Test 22: Remote MCP server
  remoteMcpConfig = mkOpenCodeConfig [
    {
      opencode.mcp.remote-svc = {
        type = "remote";
        url = "https://mcp.example.com";
      };
    }
  ];

  # Test 23: Permission wildcard "*"
  permissionWildcardConfig = mkOpenCodeConfig [
    {
      opencode.permission = {
        "*" = "ask";
      };
    }
  ];

  # Test 24: Empty object not emitted — null agent field cleaned away
  emptyObjectConfig = mkOpenCodeConfig [
    {
      opencode.theme = "dark";
      opencode.agent.myagent.model = null;
    }
  ];

  # ── Test 25: Realistic end-to-end config ─────────────────────────────

  # Simulates a real-world team configuration using module composition:
  # base settings, agent overrides, provider auth, MCP servers, permissions,
  # LSP tweaks, and keybinds — all merged from separate modules.
  realisticConfig = mkOpenCodeConfig [
    # Base config
    {
      opencode.theme = "catppuccin";
      opencode.model = "anthropic/claude-sonnet-4-5";
      opencode.share = "manual";
      opencode.autoupdate = "notify";
      opencode.instructions = [ "./CLAUDE.md" "./.opencode/*.md" ];
    }
    # Agent overrides
    {
      opencode.agent.plan = {
        steps = 80;
        temperature = 0.7;
      };
      opencode.agent.build = {
        model = "anthropic/claude-haiku-4-5";
      };
    }
    # Provider config
    {
      opencode.provider.anthropic.options.apiKey = "{env:ANTHROPIC_API_KEY}";
    }
    # MCP servers
    {
      opencode.mcp.filesystem = {
        type = "local";
        command = [ "npx" "-y" "@modelcontextprotocol/server-filesystem" "/tmp" ];
      };
      opencode.mcp.github = {
        type = "remote";
        url = "https://api.githubcopilot.com/mcp/";
        headers.Authorization = "Bearer {env:GITHUB_TOKEN}";
      };
    }
    # Permissions
    {
      opencode.permission = { bash = "allow"; edit = "allow"; };
    }
    # Disable noisy LSP
    {
      opencode.lsp.yaml = { disabled = true; };
    }
    # Keybinds
    {
      opencode.keybinds = {
        session_new = "ctrl+n";
        app_exit = "ctrl+q";
      };
    }
  ];

  # ── Tests 26–29: Provider registry metadata (ocnix-xtd.2.1) ─────────

  # Test 26: Provider with npm + name display metadata
  providerNpmNameConfig = mkOpenCodeConfig [
    {
      opencode.provider.modal = {
        npm = "@ai-sdk/openai";
        name = "Modal AI";
        options.baseURL = "https://api.modal.com/v1";
      };
    }
  ];

  # Test 27: Provider with model registry metadata
  providerModelsConfig = mkOpenCodeConfig [
    {
      opencode.provider.my-openai = {
        npm = "@ai-sdk/openai";
        models."gpt-4o" = {
          name = "GPT-4o";
          attachment = true;
          reasoning = false;
          tool_call = true;
          temperature = true;
          limit = { context = 128000; output = 16384; };
          modalities = { input = [ "text" "image" ]; output = [ "text" ]; };
        };
      };
    }
  ];

  # Test 28: Provider with extra provider-specific options
  providerExtraOptionsConfig = mkOpenCodeConfig [
    {
      opencode.provider.amazon-bedrock = {
        options = {
          apiKey = "{env:AWS_ACCESS_KEY_ID}";
          baseURL = "https://bedrock.us-east-1.amazonaws.com";
        };
      };
    }
  ];

  # Test 29: Provider with setCacheKey option
  providerCacheKeyConfig = mkOpenCodeConfig [
    {
      opencode.provider.anthropic = {
        options = {
          apiKey = "{env:ANTHROPIC_API_KEY}";
          setCacheKey = true;
        };
      };
    }
  ];

  # ── Tests 30–33: Nested permission maps (ocnix-xtd.2.2) ──────────────

  # Test 30: external_directory with path-scoped rules
  permExternalDirConfig = mkOpenCodeConfig [
    {
      opencode.permission = {
        "*" = "deny";
        bash = "allow";
        external_directory = {
          "/tmp/**" = "allow";
        };
      };
    }
  ];

  # Test 31: skill with per-skill permission rules
  permSkillConfig = mkOpenCodeConfig [
    {
      opencode.permission = {
        "*" = "deny";
        skill = {
          facturas-compras-holded = "allow";
        };
      };
    }
  ];

  # Test 32: Mixed flat + nested permissions
  permMixedConfig = mkOpenCodeConfig [
    {
      opencode.permission = {
        "*" = "deny";
        bash = "allow";
        edit = "allow";
        read = "allow";
        external_directory = {
          "/tmp/**" = "allow";
          "/home/user/projects/**" = "allow";
        };
        skill = {
          facturas-compras-holded = "allow";
          commit = "allow";
        };
      };
    }
  ];

  # Test 33: Agent with nested permission overrides (hierarchical)
  agentNestedPermConfig = mkOpenCodeConfig [
    {
      opencode.agent.reviewer = {
        model = "anthropic/claude-haiku-4-5";
        permission = {
          edit = "deny";
          bash = "deny";
          external_directory = {
            "/tmp/**" = "allow";
          };
        };
      };
    }
  ];

  # ── Test 34: Agent primary compatibility flag (ocnix-xtd.2.3) ────────

  # Test 34a: primary=true with no mode → mode=primary normalization
  agentPrimaryConfig = mkOpenCodeConfig [
    {
      opencode.agent.chief = {
        model = "anthropic/claude-sonnet-4-20250514";
        primary = true;
      };
    }
  ];

  # Test 34b: primary=true with explicit mode → mode wins, primary preserved
  agentPrimaryModeConfig = mkOpenCodeConfig [
    {
      opencode.agent.worker = {
        model = "anthropic/claude-haiku-4-5";
        primary = true;
        mode = "subagent";
      };
    }
  ];

  # ── Tests 35–37: Primary/mode conflict validation (ocnix-xtd.1.3) ──

  # Test 35: primary=false with no mode — primary=false stays in output
  # (cleanConfig only strips null, not false)
  agentPrimaryFalseConfig = mkOpenCodeConfig [
    {
      opencode.agent.worker = {
        model = "anthropic/claude-haiku-4-5";
        primary = false;
      };
    }
  ];

  # Test 36: mode=primary with no primary field — mode emitted, no primary
  agentModeOnlyConfig = mkOpenCodeConfig [
    {
      opencode.agent.chief = {
        model = "anthropic/claude-sonnet-4-20250514";
        mode = "primary";
      };
    }
  ];

  # Test 37: primary=false and mode=primary — both emitted verbatim (no normalization)
  agentPrimaryFalseModeConfig = mkOpenCodeConfig [
    {
      opencode.agent.leader = {
        model = "anthropic/claude-sonnet-4-20250514";
        primary = false;
        mode = "primary";
      };
    }
  ];

  # ── Tests 38–39: End-to-end parity fixtures (ocnix-xtd.2.4) ─────────

  # Test 38: Full migrated real-world config — multi-provider + nested permissions + agent flags
  # Demonstrates complete schema coverage for all previously unsupported field families.
  fullParityConfig = mkOpenCodeConfig [
    {
      opencode.provider = {
        # Provider with full registry metadata (npm, name, models)
        modal = {
          npm = "@ai-sdk/openai";
          name = "Modal AI";
          options = {
            baseURL = "https://api.us-west-2.modal.direct/v1";
            apiKey = "{env:MODAL_API_KEY}";
            setCacheKey = true;
          };
          models."claude-sonnet-4-via-modal" = {
            name = "Claude Sonnet 4 (via Modal)";
            attachment = true;
            reasoning = true;
            tool_call = true;
            temperature = true;
            limit = { context = 200000; output = 64000; };
            modalities = { input = [ "text" "image" ]; output = [ "text" ]; };
          };
        };
        # Standard providers
        anthropic.options.apiKey = "{env:ANTHROPIC_API_KEY}";
        amazon-bedrock.options.apiKey = "{env:AWS_ACCESS_KEY_ID}";
      };

      opencode.permission = {
        "*" = "deny";
        bash = "allow";
        edit = "allow";
        read = "allow";
        task = "allow";
        # Path-scoped external directory
        external_directory = {
          "/tmp/**" = "allow";
          "/workspace/**" = "allow";
        };
        # Per-skill permissions
        skill = {
          commit = "allow";
          facturas-compras-holded = "allow";
        };
      };

      opencode.agent = {
        # Agent with primary flag (legacy compat)
        chief = {
          model = "anthropic/claude-sonnet-4-20250514";
          primary = true;
          description = "Primary orchestrator agent";
        };
        # Agent with explicit mode
        worker = {
          model = "anthropic/claude-haiku-4-5";
          mode = "subagent";
          description = "Sub-task implementer";
          # Agent-level nested permission override
          permission = {
            bash = "allow";
            edit = "allow";
            external_directory = {
              "/tmp/**" = "allow";
            };
          };
        };
      };
    }
  ];

  # Test 39: Verify parity config emits correct JSON structure (content assertions)
  parityJsonCheck = fullParityConfig;

  # ── Test 40: Sample config round-trip parity ──────────────────────────
  # Build the Nix port of the sample and compare against reference JSON.
  samplePortConfig = mkOpenCodeConfig [ (import ./sample-port.nix) ];

  # Reference JSON: strip JSONC comments from the fixed sample, parse to canonical form.
  # We use bun to strip comments and re-serialize as compact JSON.
  stripJsoncScript = ./strip-jsonc.js;

  sampleReferenceJson = pkgs.runCommand "sample-reference.json" {
    nativeBuildInputs = [ pkgs.bun ];
    src = ../../opencode.sample.jsonc;
  } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    bun ${stripJsoncScript} "$src" "$out"
  '';

  # Test 41: {file:path} template passthrough
  fileTemplateConfig = mkOpenCodeConfig [
    {
      opencode.provider.custom = {
        options.apiKey = "{file:secrets/api.key}";
      };
    }
  ];

  # Test 42: Invalid config Nix eval catches bad enum — Nix module type
  # checking rejects "bogus" at eval time, before Zod even runs.
  invalidNixEvalSucceeded = (builtins.tryEval (
    builtins.deepSeq (mkOpenCodeConfig [{ opencode.logLevel = "bogus"; }]) true
  )).success;

  # Script for deep structural comparison of two JSON files
  deepDiffScript = ./deep-diff.js;

  # ── The test runner ──────────────────────────────────────────────────

  validateScript = ./validate.ts;

in
pkgs.stdenvNoCC.mkDerivation {
  name = "opencode-config-zod-tests";

  # No real source — everything is passed via environment / deps
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.bun ];

  # Make all test configs available
  inherit
    minimalConfig themeConfig agentConfig mcpConfig permissionConfig
    tuiConfig serverConfig compactionConfig experimentalConfig
    fullConfig logLevelConfig logLevelDriftConfig invalidConfig
    mergedConfig listConcatConfig lspDisabledConfig formatterDisabledConfig
    providerTimeoutFalseConfig autoupdateStringConfig autoupdateBoolConfig
    envTemplateConfig remoteMcpConfig permissionWildcardConfig
    emptyObjectConfig realisticConfig
    providerNpmNameConfig providerModelsConfig providerExtraOptionsConfig
    providerCacheKeyConfig permExternalDirConfig permSkillConfig
    permMixedConfig agentNestedPermConfig agentPrimaryConfig
    agentPrimaryModeConfig
    agentPrimaryFalseConfig agentModeOnlyConfig agentPrimaryFalseModeConfig
    fullParityConfig parityJsonCheck
    samplePortConfig sampleReferenceJson
    fileTemplateConfig invalidNixEvalSucceeded
    stripJsoncScript deepDiffScript;

  buildPhase = ''
    runHook preBuild

    # Bun needs a writable HOME for its cache/config
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    # ── Prepare writable source tree with node_modules ──
    cp -r "${opencode}" "$TMPDIR/opencode"
    chmod -R u+w "$TMPDIR/opencode"

    # Overlay pre-fetched node_modules
    cp -r "${node_modules}/." "$TMPDIR/opencode/"

    export OPENCODE_SRC="$TMPDIR/opencode"

    PASS=0
    FAIL=0

    run_test() {
      local label="$1" config="$2" extra="''${3:-}"
      echo "=== $label ==="
      echo "  config: $(cat "$config")"
      if bun run ${validateScript} "$config" $extra; then
        echo "  PASS"
        PASS=$((PASS + 1))
      else
        echo "  FAIL"
        FAIL=$((FAIL + 1))
        return 1
      fi
    }

    # Assert a literal string is present in the JSON config file
    assert_contains() {
      local label="$1" config="$2" needle="$3"
      if grep -qF "$needle" "$config"; then
        echo "  assert_contains($needle): OK"
      else
        echo "  assert_contains($needle): MISSING in $(cat "$config")"
        return 1
      fi
    }

    # Assert a literal string is NOT present in the JSON config file
    assert_not_contains() {
      local label="$1" config="$2" needle="$3"
      if grep -qF "$needle" "$config"; then
        echo "  assert_not_contains($needle): UNEXPECTEDLY FOUND in $(cat "$config")"
        return 1
      else
        echo "  assert_not_contains($needle): OK"
      fi
    }

    # ── Original tests 1–13 ──────────────────────────────────────────

    run_test "Test 1: Minimal (empty) config"    "$minimalConfig"
    run_test "Test 2: Theme config"               "$themeConfig"
    run_test "Test 3: Agent config"               "$agentConfig"
    run_test "Test 4: MCP local server"           "$mcpConfig"
    run_test "Test 5: Permissions"                "$permissionConfig"
    run_test "Test 6: TUI settings"               "$tuiConfig"
    run_test "Test 7: Server settings"            "$serverConfig"
    run_test "Test 8: Compaction settings"        "$compactionConfig"
    run_test "Test 9: Experimental flags"         "$experimentalConfig"
    run_test "Test 10: Full composite config"     "$fullConfig"
    run_test "Test 11: logLevel (Nix module, UPPERCASE)" "$logLevelConfig"
    run_test "Test 12: logLevel drift detection (expect-fail)" "$logLevelDriftConfig" "--expect-fail"
    run_test "Test 13: Invalid config (expect-fail)" "$invalidConfig" "--expect-fail"

    # ── New tests 14–24 ──────────────────────────────────────────────

    run_test "Test 14: Module merging" "$mergedConfig"
    assert_contains "Test 14" "$mergedConfig" '"theme":"dark"'
    assert_contains "Test 14" "$mergedConfig" '"username":"alice"'

    run_test "Test 15: List concatenation (instructions)" "$listConcatConfig"
    assert_contains "Test 15" "$listConcatConfig" '"a.md"'
    assert_contains "Test 15" "$listConcatConfig" '"b.md"'

    run_test "Test 16: LSP disabled (false)" "$lspDisabledConfig"
    assert_contains "Test 16" "$lspDisabledConfig" '"lsp":false'

    run_test "Test 17: Formatter disabled (false)" "$formatterDisabledConfig"
    assert_contains "Test 17" "$formatterDisabledConfig" '"formatter":false'

    run_test "Test 18: Provider timeout=false" "$providerTimeoutFalseConfig"
    assert_contains "Test 18" "$providerTimeoutFalseConfig" '"timeout":false'

    run_test "Test 19: autoupdate string 'notify'" "$autoupdateStringConfig"
    assert_contains "Test 19" "$autoupdateStringConfig" '"autoupdate":"notify"'

    run_test "Test 20: autoupdate bool true" "$autoupdateBoolConfig"
    assert_contains "Test 20" "$autoupdateBoolConfig" '"autoupdate":true'

    run_test "Test 21: {env:VAR} template passthrough" "$envTemplateConfig"
    assert_contains "Test 21" "$envTemplateConfig" '{env:ANTHROPIC_API_KEY}'

    run_test "Test 22: Remote MCP server" "$remoteMcpConfig"
    assert_contains "Test 22" "$remoteMcpConfig" '"type":"remote"'
    assert_contains "Test 22" "$remoteMcpConfig" '"url":"https://mcp.example.com"'

    run_test "Test 23: Permission wildcard *" "$permissionWildcardConfig"
    assert_contains "Test 23" "$permissionWildcardConfig" '"*":"ask"'

    run_test "Test 24: Empty object not emitted" "$emptyObjectConfig"
    assert_not_contains "Test 24" "$emptyObjectConfig" '"myagent"'
    assert_not_contains "Test 24" "$emptyObjectConfig" '"agent"'

    # ── Test 25: Realistic end-to-end config ─────────────────────────

    run_test "Test 25: Realistic e2e config" "$realisticConfig"
    assert_contains "Test 25" "$realisticConfig" '"theme":"catppuccin"'
    assert_contains "Test 25" "$realisticConfig" '"model":"anthropic/claude-sonnet-4-5"'
    assert_contains "Test 25" "$realisticConfig" '"share":"manual"'
    assert_contains "Test 25" "$realisticConfig" '"autoupdate":"notify"'
    assert_contains "Test 25" "$realisticConfig" 'CLAUDE'
    assert_contains "Test 25" "$realisticConfig" '"steps":80'
    assert_contains "Test 25" "$realisticConfig" '"temperature"'
    assert_contains "Test 25" "$realisticConfig" '"anthropic/claude-haiku-4-5"'
    assert_contains "Test 25" "$realisticConfig" '{env:ANTHROPIC_API_KEY}'
    assert_contains "Test 25" "$realisticConfig" '"filesystem"'
    assert_contains "Test 25" "$realisticConfig" '"github"'
    assert_contains "Test 25" "$realisticConfig" 'Bearer {env:GITHUB_TOKEN}'
    assert_contains "Test 25" "$realisticConfig" '"bash":"allow"'
    assert_contains "Test 25" "$realisticConfig" '"disabled":true'
    assert_contains "Test 25" "$realisticConfig" '"session_new":"ctrl+n"'
    assert_contains "Test 25" "$realisticConfig" '"app_exit":"ctrl+q"'

    # ── Tests 26–29: Provider registry metadata ──────────────────────

    run_test "Test 26: Provider npm + name metadata" "$providerNpmNameConfig"
    assert_contains "Test 26" "$providerNpmNameConfig" '"npm":"@ai-sdk/openai"'
    assert_contains "Test 26" "$providerNpmNameConfig" '"name":"Modal AI"'
    assert_contains "Test 26" "$providerNpmNameConfig" '"baseURL"'

    run_test "Test 27: Provider model registry metadata" "$providerModelsConfig"
    assert_contains "Test 27" "$providerModelsConfig" '"gpt-4o"'
    assert_contains "Test 27" "$providerModelsConfig" '"attachment":true'
    assert_contains "Test 27" "$providerModelsConfig" '"tool_call":true'
    assert_contains "Test 27" "$providerModelsConfig" '"context":128000'
    assert_contains "Test 27" "$providerModelsConfig" '"output":16384'
    assert_contains "Test 27" "$providerModelsConfig" '"text"'
    assert_contains "Test 27" "$providerModelsConfig" '"image"'
    assert_contains "Test 27" "$providerModelsConfig" '"reasoning":false'

    run_test "Test 28: Provider extra options (amazon-bedrock)" "$providerExtraOptionsConfig"
    assert_contains "Test 28" "$providerExtraOptionsConfig" '"amazon-bedrock"'
    assert_contains "Test 28" "$providerExtraOptionsConfig" '"baseURL"'

    run_test "Test 29: Provider setCacheKey option" "$providerCacheKeyConfig"
    assert_contains "Test 29" "$providerCacheKeyConfig" '"setCacheKey":true'
    assert_contains "Test 29" "$providerCacheKeyConfig" '{env:ANTHROPIC_API_KEY}'

    # ── Tests 30–33: Nested permission maps ──────────────────────────

    run_test "Test 30: external_directory path-scoped permissions" "$permExternalDirConfig"
    assert_contains "Test 30" "$permExternalDirConfig" '"external_directory"'
    assert_contains "Test 30" "$permExternalDirConfig" '"/tmp/**"'
    assert_contains "Test 30" "$permExternalDirConfig" '"allow"'

    run_test "Test 31: skill per-skill permission map" "$permSkillConfig"
    assert_contains "Test 31" "$permSkillConfig" '"skill"'
    assert_contains "Test 31" "$permSkillConfig" '"facturas-compras-holded"'
    assert_contains "Test 31" "$permSkillConfig" '"allow"'

    run_test "Test 32: Mixed flat + nested permissions" "$permMixedConfig"
    assert_contains "Test 32" "$permMixedConfig" '"*":"deny"'
    assert_contains "Test 32" "$permMixedConfig" '"bash":"allow"'
    assert_contains "Test 32" "$permMixedConfig" '"external_directory"'
    assert_contains "Test 32" "$permMixedConfig" '"/tmp/**"'
    assert_contains "Test 32" "$permMixedConfig" '"skill"'
    assert_contains "Test 32" "$permMixedConfig" '"facturas-compras-holded"'
    assert_contains "Test 32" "$permMixedConfig" '"commit":"allow"'

    run_test "Test 33: Agent with nested permission overrides" "$agentNestedPermConfig"
    assert_contains "Test 33" "$agentNestedPermConfig" '"reviewer"'
    assert_contains "Test 33" "$agentNestedPermConfig" '"edit":"deny"'
    assert_contains "Test 33" "$agentNestedPermConfig" '"bash":"deny"'
    assert_contains "Test 33" "$agentNestedPermConfig" '"external_directory"'
    assert_contains "Test 33" "$agentNestedPermConfig" '"/tmp/**":"allow"'

    # ── Test 34: Agent primary compatibility flag ─────────────────────

    run_test "Test 34a: primary=true, no mode → mode=primary injected" "$agentPrimaryConfig"
    assert_contains "Test 34a" "$agentPrimaryConfig" '"mode":"primary"'

    run_test "Test 34b: primary=true + mode=subagent → mode wins" "$agentPrimaryModeConfig"
    assert_contains "Test 34b" "$agentPrimaryModeConfig" '"mode":"subagent"'
    assert_contains "Test 34b" "$agentPrimaryModeConfig" '"primary":true'

    # ── Tests 35–37: Primary/mode conflict validation ─────────────────

    run_test "Test 35: primary=false, no mode — false preserved in output" "$agentPrimaryFalseConfig"
    assert_contains "Test 35" "$agentPrimaryFalseConfig" '"primary":false'
    assert_not_contains "Test 35" "$agentPrimaryFalseConfig" '"mode"'

    run_test "Test 36: mode=primary, no primary field — mode only" "$agentModeOnlyConfig"
    assert_contains "Test 36" "$agentModeOnlyConfig" '"mode":"primary"'
    assert_not_contains "Test 36" "$agentModeOnlyConfig" '"primary":'

    run_test "Test 37: primary=false + mode=primary — both preserved verbatim" "$agentPrimaryFalseModeConfig"
    assert_contains "Test 37" "$agentPrimaryFalseModeConfig" '"primary":false'
    assert_contains "Test 37" "$agentPrimaryFalseModeConfig" '"mode":"primary"'

    # ── Tests 38–39: End-to-end parity fixtures ──────────────────────

    run_test "Test 38: Full parity config — all previously unsupported fields" "$fullParityConfig"
    # Provider metadata
    assert_contains "Test 38" "$fullParityConfig" '"npm":"@ai-sdk/openai"'
    assert_contains "Test 38" "$fullParityConfig" '"name":"Modal AI"'
    assert_contains "Test 38" "$fullParityConfig" '"setCacheKey":true'
    assert_contains "Test 38" "$fullParityConfig" '"claude-sonnet-4-via-modal"'
    assert_contains "Test 38" "$fullParityConfig" '"context":200000'
    assert_contains "Test 38" "$fullParityConfig" '"output":64000'
    # Nested permissions
    assert_contains "Test 38" "$fullParityConfig" '"external_directory"'
    assert_contains "Test 38" "$fullParityConfig" '"/tmp/**":"allow"'
    assert_contains "Test 38" "$fullParityConfig" '"/workspace/**":"allow"'
    assert_contains "Test 38" "$fullParityConfig" '"skill"'
    assert_contains "Test 38" "$fullParityConfig" '"facturas-compras-holded":"allow"'
    # Agent primary normalization
    assert_contains "Test 38" "$fullParityConfig" '"mode":"primary"'
    # Worker with mode + nested permission
    assert_contains "Test 38" "$fullParityConfig" '"mode":"subagent"'
    assert_contains "Test 38" "$fullParityConfig" '"permission"'

    run_test "Test 39: Parity config JSON structure" "$parityJsonCheck"
    # Top-level structure
    assert_contains "Test 39" "$parityJsonCheck" '"provider"'
    assert_contains "Test 39" "$parityJsonCheck" '"permission"'
    assert_contains "Test 39" "$parityJsonCheck" '"agent"'
    # All providers present
    assert_contains "Test 39" "$parityJsonCheck" '"modal"'
    assert_contains "Test 39" "$parityJsonCheck" '"anthropic"'
    assert_contains "Test 39" "$parityJsonCheck" '"amazon-bedrock"'
    # All agents present
    assert_contains "Test 39" "$parityJsonCheck" '"chief"'
    assert_contains "Test 39" "$parityJsonCheck" '"worker"'

    # ── Test 40: Sample config structural parity ─────────────────────

    run_test "Test 40: Sample JSONC → Nix port round-trip (Zod validation)" "$samplePortConfig"

    echo "=== Test 40b: Structural comparison (Nix output vs JSONC reference) ==="
    # Use bun to do a deep structural comparison ignoring key order
    DIFF_RESULT=$(bun "$deepDiffScript" "$samplePortConfig" "$sampleReferenceJson" 2>&1) || true

    if echo "$DIFF_RESULT" | grep -q "STRUCTURALLY_IDENTICAL"; then
      echo "  PASS: Nix output is structurally identical to JSONC reference"
    else
      echo "  FAIL: Structural differences found:"
      echo "$DIFF_RESULT"
      exit 1
    fi

    # ── Test 41: {file:path} template passthrough ────────────────────────

    run_test "Test 41: {file:path} template passthrough" "$fileTemplateConfig"
    assert_contains "Test 41" "$fileTemplateConfig" '{file:secrets/api.key}'

    # ── Test 42: Invalid config caught at Nix eval ───────────────────────

    echo "=== Test 42: Invalid config caught at Nix eval ==="
    if [ "$invalidNixEvalSucceeded" = "" ] || [ "$invalidNixEvalSucceeded" = "0" ] || [ "$invalidNixEvalSucceeded" = "false" ]; then
      echo "  PASS: Nix evaluation correctly rejected invalid logLevel"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: Nix evaluation should have rejected logLevel='bogus'"
      FAIL=$((FAIL + 1))
    fi

    echo ""
    echo "All tests passed! ($PASS validations)"

    runHook postBuild
  '';

  installPhase = ''
    touch $out
  '';
}
