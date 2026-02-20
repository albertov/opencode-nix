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

  minimalConfig = mkOpenCodeConfig [];

  themeConfig = mkOpenCodeConfig [
    { opencode.theme = "catppuccin"; }
  ];

  agentConfig = mkOpenCodeConfig [
    {
      opencode.agent.plan = {
        model = "anthropic/claude-sonnet-4-20250514";
        steps = 50;
      };
    }
  ];

  mcpConfig = mkOpenCodeConfig [
    {
      opencode.mcp.my-tool = {
        type = "local";
        command = [ "npx" "my-tool" ];
      };
    }
  ];

  permissionConfig = mkOpenCodeConfig [
    {
      opencode.permission = {
        bash = "allow";
        edit = "ask";
      };
    }
  ];

  tuiConfig = mkOpenCodeConfig [
    {
      opencode.tui = {
        scroll_speed = 5.0;
        diff_style = "stacked";
      };
    }
  ];

  serverConfig = mkOpenCodeConfig [
    {
      opencode.server = {
        port = 8080;
        hostname = "localhost";
      };
    }
  ];

  compactionConfig = mkOpenCodeConfig [
    {
      opencode.compaction = {
        auto = true;
        prune = true;
      };
    }
  ];

  experimentalConfig = mkOpenCodeConfig [
    {
      opencode.experimental = {
        batch_tool = true;
      };
    }
  ];

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

  # Upstream Zod Log.Level expects UPPERCASE: "DEBUG"|"INFO"|"WARN"|"ERROR".
  # The Nix module currently defines lowercase — this raw test validates the
  # correct upstream values directly.
  logLevelConfig = pkgs.writeText "opencode-loglevel.json" (builtins.toJSON {
    theme = "dark";
    logLevel = "DEBUG";
  });

  # Detect the Nix module logLevel drift: lowercase "debug" should FAIL the
  # upstream Zod schema.
  logLevelDriftConfig = mkOpenCodeConfig [
    { opencode.logLevel = "debug"; }
  ];

  # ── Negative test: invalid config that should fail Zod validation ────
  # Write raw JSON with an unknown top-level key (schema is .strict())
  invalidConfig = pkgs.writeText "opencode-invalid.json" (builtins.toJSON {
    totally_bogus_field = true;
  });

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
    fullConfig logLevelConfig logLevelDriftConfig invalidConfig;

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

    run_test() {
      local label="$1" config="$2" extra="''${3:-}"
      echo "=== $label ==="
      echo "  config: $(cat "$config")"
      bun run ${validateScript} "$config" $extra
      echo "  PASS"
    }

    run_test "Test 1: Minimal (empty) config"    "$minimalConfig"
    run_test "Test 2: Theme config"                "$themeConfig"
    run_test "Test 3: Agent config"               "$agentConfig"
    run_test "Test 4: MCP local server"           "$mcpConfig"
    run_test "Test 5: Permissions"                "$permissionConfig"
    run_test "Test 6: TUI settings"               "$tuiConfig"
    run_test "Test 7: Server settings"            "$serverConfig"
    run_test "Test 8: Compaction settings"        "$compactionConfig"
    run_test "Test 9: Experimental flags"         "$experimentalConfig"
    run_test "Test 10: Full composite config"     "$fullConfig"
    run_test "Test 11: logLevel (raw uppercase)"  "$logLevelConfig"
    run_test "Test 12: logLevel drift detection (expect-fail)" "$logLevelDriftConfig" "--expect-fail"
    run_test "Test 13: Invalid config (expect-fail)" "$invalidConfig" "--expect-fail"

    echo ""
    echo "All 13 tests passed!"

    runHook postBuild
  '';

  installPhase = ''
    touch $out
  '';
}
