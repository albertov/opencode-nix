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

{ pkgs, lib, opencode-src, mkOpenCodeConfig }:

let
  # Build node_modules using the upstream pattern (fixed-output derivation).
  node_modules = pkgs.callPackage (opencode-src + "/nix/node_modules.nix") {
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
    emptyObjectConfig;

  buildPhase = ''
    runHook preBuild

    # Bun needs a writable HOME for its cache/config
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    # ── Prepare writable source tree with node_modules ──
    cp -r "${opencode-src}" "$TMPDIR/opencode"
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

    echo ""
    echo "All 24 tests passed! ($PASS Zod validations)"

    runHook postBuild
  '';

  installPhase = ''
    touch $out
  '';
}
