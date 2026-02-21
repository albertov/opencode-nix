# Tasks: add-opencode-config-nix-module

## 1. Flake scaffolding

- [x] 1.1 Add `opencode-src` flake input pointing to `github:anthropics/opencode` with `flake = false` _(intentional divergence: using `opencode` input from `github:anomalyco/opencode`)_
- [x] 1.2 Create `nix/config/` directory structure with `default.nix` root module that imports all option submodules
- [x] 1.3 Wire `lib.mkOpenCodeConfig` and `lib.wrapOpenCode` in `flake.nix` outputs
- [x] 1.4 Verify `nix flake check` passes with empty module list (no options set → minimal valid JSON `{}`)

## 2. Root scalar options

- [x] 2.1 Create `nix/config/options/root.nix` with top-level scalar options: `$schema`, `theme`, `logLevel`, `username`, `model`, `small_model`, `default_agent`, `snapshot`, `share`, `autoupdate`, `disabled_providers`, `enabled_providers`, `instructions`, `plugin`
- [x] 2.2 Implement `logLevel` as enum type (`"trace"`, `"debug"`, `"info"`, `"warn"`, `"error"`, `"fatal"`)
- [x] 2.3 Implement `share` as enum type (`"manual"`, `"auto"`, `"disabled"`)
- [x] 2.4 Implement `autoupdate` as `either bool (enum [ "notify" ])` to support both boolean and string
- [x] 2.5 Document every option with `mkOption { description = "..." }`

## 3. Agent options

- [x] 3.1 Create `nix/config/options/agent.nix` with agent submodule type supporting arbitrary agent names via `attrsOf`
- [x] 3.2 Define agent submodule fields: `model`, `variant`, `temperature`, `top_p`, `prompt`, `description`, `mode` (enum: `"subagent"`, `"primary"`, `"all"`), `hidden`, `disable`, `steps`, `color`, `options`
- [x] 3.3 Implement per-agent `permission` as nested submodule (same type as root permission)
- [x] 3.4 Implement `color` as either hex string (`#RRGGBB`) or theme color enum
- [x] 3.5 Implement `options` as `attrsOf anything` escape hatch for provider-specific passthrough

## 4. Provider options

- [x] 4.1 Create `nix/config/options/provider.nix` with provider submodule type supporting arbitrary provider names
- [x] 4.2 Define provider fields: `apiKey` (string, supports `{env:VAR}` templates), `baseURL`, `enterpriseUrl`, `setCacheKey`, `timeout` (either number or `false` literal), `whitelist`, `blacklist`
- [x] 4.3 Implement nested `models` submodule: `disabled` bool, `variants` attrset
- [x] 4.4 Document `{env:VAR}` passthrough pattern in `apiKey` description

## 5. MCP options

- [x] 5.1 Create `nix/config/options/mcp.nix` with MCP submodule supporting arbitrary server names
- [x] 5.2 Implement flat submodule with `type` (enum: `"local"`, `"remote"`), shared fields (`enabled`, `timeout`), local-only fields (`command`, `environment`), remote-only fields (`url`, `headers`, `oauth`)
- [x] 5.3 Implement toggle-only form: `mcp.<name>.enabled = false` (no type required)
- [x] 5.4 Implement `oauth` as nested submodule (`clientId`, `clientSecret`, `scope`) or `false` literal _(tracked in beads)_

## 6. Permission options

- [x] 6.1 Create `nix/config/options/permission.nix` with root-level permission config
- [x] 6.2 Define permission action type as enum (`"ask"`, `"allow"`, `"deny"`)
- [x] 6.3 Support wildcard `"*"` key and tool-specific keys (`read`, `edit`, `bash`, etc.)
- [x] 6.4 Support nested permission rules (tool name → sub-key → action)

## 7. Command and skills options

- [x] 7.1 Create `nix/config/options/command.nix` with command submodule: `template` (required), `description`, `agent`, `model`, `subtask`
- [x] 7.2 Create `nix/config/options/skills.nix` with skills submodule: `paths`, `urls`

## 8. LSP and formatter options

- [x] 8.1 Create `nix/config/options/lsp.nix` supporting `false` literal (disable all) or `attrsOf` server submodule
- [x] 8.2 Define LSP server submodule: `command`, `extensions`, `disabled`, `env`, `initialization` (attrsOf anything)
- [x] 8.3 Create `nix/config/options/formatter.nix` supporting `false` literal or `attrsOf` formatter submodule
- [x] 8.4 Define formatter submodule: `command`, `extensions`, `disabled`, `environment`

## 9. TUI, server, and remaining options

- [x] 9.1 Create `nix/config/options/tui.nix`: `scroll_speed`, `scroll_acceleration.enabled`, `diff_style` (enum)
- [x] 9.2 Create `nix/config/options/server.nix`: `port`, `hostname`, `mdns`, `mdnsDomain`, `cors`
- [x] 9.3 Create `nix/config/options/keybinds.nix` with all 90+ keybind options as optional strings
- [x] 9.4 Create `nix/config/options/watcher.nix`: `ignore` string list
- [x] 9.5 Create `nix/config/options/compaction.nix`: `auto`, `prune`, `reserved`
- [x] 9.6 Create `nix/config/options/enterprise.nix`: `url`
- [x] 9.7 Create `nix/config/options/experimental.nix`: `batch_tool`, `openTelemetry`, `mcp_timeout`, `continue_loop_on_deny`, `primary_tools`, `disable_paste_summary`

## 10. `mkOpenCodeConfig` implementation

- [x] 10.1 Implement `mkOpenCodeConfig` in `nix/config/mk-opencode-config.nix`: accept module list, evaluate with `lib.evalModules`, serialize to JSON via `pkgs.writeText`
- [x] 10.2 Implement null/unset filtering: recursively remove null values, empty attrsets, and unset options from the evaluated config before serialization
- [x] 10.3 Handle special values: preserve `false` for `lsp`/`formatter` disable-all, preserve `timeout = false` for providers, handle `autoupdate` string-or-bool
- [x] 10.4 Verify generated JSON is valid (no trailing commas, no `null` values, no empty objects)

## 11. `wrapOpenCode` implementation

- [x] 11.1 Implement `wrapOpenCode` in `nix/config/wrap-opencode.nix`: accept `{ name, modules, opencode? }`, call `mkOpenCodeConfig` internally
- [x] 11.2 Use `symlinkJoin` + `makeWrapper` to create wrapped derivation with `OPENCODE_CONFIG` env var pointing to generated config store path
- [x] 11.3 Set derivation `pname` and executable name to `name` parameter (`$out/bin/<name>`)
- [x] 11.4 Default `opencode` parameter to the opencode package from nixpkgs or overlay _(tracked in beads)_

## 12. Test suite

- [x] 12.1 Create test infrastructure: Nix derivation that installs opencode-src deps with bun, runs Zod validation against generated JSON
- [x] 12.2 Write test: empty config → valid `{}`
- [x] 12.3 Write test: minimal config with a few root scalars → valid JSON with correct values
- [x] 12.4 Write test: full config exercising all sections (agents, providers, MCP local+remote, LSP, formatters, permissions, commands, keybinds, TUI, server, skills, watcher, compaction, enterprise, experimental) → valid JSON
- [x] 12.5 Write test: `lsp = false` and `formatter = false` → JSON contains literal `false`
- [x] 12.6 Write test: `{env:VAR}` and `{file:path}` templates survive as literal strings in output JSON _(tracked in beads)_
- [x] 12.7 Write test: invalid config (e.g., unknown enum value) → Nix evaluation error _(tracked in beads)_
- [x] 12.8 Wire all tests as `checks.<system>.opencode-config` in flake outputs

## 13. CI workflow

- [x] 13.1 Create `.github/workflows/check.yml` with trigger on push to `main` and all PRs
- [x] 13.2 Add `DeterminateSystems/nix-installer-action` step for Nix installation
- [x] 13.3 Add `cachix/cachix-action` step with cache name and `CACHIX_AUTH_TOKEN` secret
- [x] 13.4 Add `nix flake check` step as the CI gate
- [x] 13.5 Verify workflow YAML is valid (no syntax errors)

## 14. Documentation and integration

- [x] 14.1 Add option descriptions to every `mkOption` covering type, default, and behavior
- [x] 14.2 Document `{env:VAR}` and `{file:path}` passthrough patterns in relevant option descriptions
- [x] 14.3 Verify `nix flake check` passes end-to-end with all tests green
