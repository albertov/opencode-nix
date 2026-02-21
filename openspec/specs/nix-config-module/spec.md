# nix-config-module

Typed Nix module options mirroring the full opencode.json schema.

## ADDED Requirements

### Requirement: Root scalar options

Every root-level scalar field in the opencode schema has a corresponding `mkOption`.

#### Scenario: Set theme and log level

WHEN a module sets:
```nix
{ theme = "catppuccin"; logLevel = "debug"; }
```
THEN the JSON output contains `{"theme":"catppuccin","logLevel":"debug"}`.

#### Scenario: Boolean and enum fields

WHEN a module sets:
```nix
{ snapshot = true; share = "auto"; autoupdate = "notify"; }
```
THEN the JSON contains `{"snapshot":true,"share":"auto","autoupdate":"notify"}`.

#### Scenario: String list fields

WHEN a module sets:
```nix
{ instructions = [ "./prompts/*.md" ]; plugin = [ "some-plugin" ]; disabled_providers = [ "anthropic" ]; }
```
THEN the JSON contains those as JSON arrays of strings.

#### Scenario: Omitted options produce no JSON key

WHEN a module does not set `theme`
THEN the key `"theme"` is absent from the JSON output (not `null`, not empty string).

---

### Requirement: Agent configuration

Agent configs are keyed by name with typed sub-options.

#### Scenario: Configure a named agent

WHEN a module sets:
```nix
{ agent.plan = { model = "anthropic/claude-sonnet-4-20250514"; steps = 50; temperature = 0.7; }; }
```
THEN the JSON contains `{"agent":{"plan":{"model":"anthropic/claude-sonnet-4-20250514","steps":50,"temperature":0.7}}}`.

#### Scenario: Agent with color and visibility

WHEN a module sets:
```nix
{ agent.my-agent = { color = "#FF5500"; hidden = true; mode = "subagent"; }; }
```
THEN the JSON agent entry has all three fields.

#### Scenario: Agent with per-agent permissions

WHEN a module sets:
```nix
{ agent.build.permission = { bash = "allow"; edit = "ask"; }; }
```
THEN the JSON nests `permission` inside the agent config.

#### Scenario: Arbitrary agent names

WHEN a module sets:
```nix
{ agent.my-custom-agent = { model = "openai/gpt-4o"; }; }
```
THEN the JSON contains `"my-custom-agent"` as a key under `"agent"`.

#### Scenario: Agent primary flag is configurable

WHEN a module sets:
```nix
{ agent.invoicer = { primary = true; }; }
```
THEN the JSON contains `{"agent":{"invoicer":{"primary":true}}}`.

#### Scenario: Explicit mode overrides derived primary behavior

WHEN a module sets:
```nix
{ agent.foo = { primary = true; mode = "subagent"; }; }
```
THEN the JSON preserves explicit `mode = "subagent"` and does not rewrite it to `primary`.

#### Scenario: primary=true without mode remains primary-compatible

WHEN a module sets:
```nix
{ agent.chief = { primary = true; }; }
```
THEN the generated JSON passes upstream schema validation and is treated as a primary agent configuration.

---

### Requirement: Provider configuration

Provider configs support API keys, base URLs, timeouts, model overrides, and whitelists/blacklists.

#### Scenario: Provider with API key using env template

WHEN a module sets:
```nix
{ provider.anthropic = { options.apiKey = "{env:ANTHROPIC_API_KEY}"; }; }
```
THEN the JSON contains the literal string `"{env:ANTHROPIC_API_KEY}"` (not resolved).

#### Scenario: Provider with model whitelist

WHEN a module sets:
```nix
{ provider.openai = { whitelist = [ "gpt-4o" "o1" ]; }; }
```
THEN the JSON contains `{"provider":{"openai":{"whitelist":["gpt-4o","o1"]}}}`.

#### Scenario: Provider timeout disabled

WHEN a module sets:
```nix
{ provider.anthropic = { options.timeout = false; }; }
```
THEN the JSON contains `"timeout":false` (not `0`, not `null`).

#### Scenario: Provider metadata is emitted to JSON

WHEN a module sets:
```nix
{ provider.modal = { npm = "@anthropic-ai/claude-code"; name = "claude-code"; }; }
```
THEN generated `opencode.json` includes those fields unchanged under `provider.modal`.

#### Scenario: Model metadata round-trips

WHEN a module sets:
```nix
{ provider.modal.models.claude = {
    name = "claude-3-5-sonnet-20241022";
    tools = true;
    tool_call = true;
    reasoning = true;
    attachment = true;
    temperature = 1.0;
    limit.context = 200000;
    limit.output = 8192;
    modalities.input = [ "text" "image" ];
    modalities.output = [ "text" ];
  };
}
```
THEN generated `opencode.json` preserves each configured value at the expected model path.

#### Scenario: Non-core provider options are preserved

WHEN a module sets:
```nix
{ provider.amazon-bedrock = { options.region = "us-east-1"; options.profile = "default"; }; }
```
THEN generated `opencode.json` contains those keys and values under `provider.amazon-bedrock.options`.

---

### Requirement: MCP server configuration

MCP entries are discriminated by `type` field — local (command-based) or remote (URL-based).

#### Scenario: Local MCP server

WHEN a module sets:
```nix
{ mcp.my-tool = { type = "local"; command = [ "npx" "my-tool" ]; environment.API_KEY = "{env:TOOL_KEY}"; }; }
```
THEN the JSON contains the local MCP config with `type`, `command`, and `environment`.

#### Scenario: Remote MCP server

WHEN a module sets:
```nix
{ mcp.remote-tool = { type = "remote"; url = "https://mcp.example.com"; headers.Authorization = "Bearer {env:TOKEN}"; }; }
```
THEN the JSON contains the remote MCP config with `type`, `url`, and `headers`.

#### Scenario: MCP toggle without full config

WHEN a module sets:
```nix
{ mcp.some-tool = { enabled = false; }; }
```
THEN the JSON contains `{"some-tool":{"enabled":false}}`.

#### Scenario: Local MCP with timeout

WHEN a module sets:
```nix
{ mcp.slow-tool = { type = "local"; command = [ "slow-tool" ]; timeout = 60000; }; }
```
THEN the JSON contains `"timeout":60000`.

---

### Requirement: Permission configuration

Permissions map tool names to allow/ask/deny actions, supporting both root-level and per-agent.

#### Scenario: Root permissions

WHEN a module sets:
```nix
{ permission = { bash = "allow"; edit = "ask"; external_directory = "deny"; }; }
```
THEN the JSON contains the permission object at root level.

#### Scenario: Wildcard permission

WHEN a module sets:
```nix
{ permission."*" = "ask"; }
```
THEN the JSON contains `{"permission":{"*":"ask"}}`.

#### Scenario: Flat and nested permissions coexist

WHEN a module sets:
```nix
{ permission = {
    "*" = "deny";
    bash = "allow";
    skill = {
      facturas-compras-holded = "allow";
    };
  };
}
```
THEN generated `opencode.json` includes both flat and nested permission entries without shape loss.

#### Scenario: external_directory map emits correctly

WHEN a module sets:
```nix
{ permission.external_directory."/tmp/**" = "allow"; }
```
THEN generated `opencode.json` contains a nested `external_directory` object with the key and action.

#### Scenario: Skill permission scope emits correctly

WHEN a module sets:
```nix
{ permission.skill.facturas-compras-holded = "allow"; }
```
THEN generated `opencode.json` contains `permission.skill.facturas-compras-holded` with action `allow`.

---

### Requirement: Command configuration

Custom slash commands with templates, optional agent/model bindings.

#### Scenario: Simple command

WHEN a module sets:
```nix
{ command.test = { template = "Run the test suite"; description = "Run tests"; }; }
```
THEN the JSON contains the command entry with `template` and `description`.

#### Scenario: Command bound to agent

WHEN a module sets:
```nix
{ command.review = { template = "Review this PR"; agent = "plan"; subtask = true; }; }
```
THEN the JSON contains `agent`, `subtask` in the command entry.

---

### Requirement: LSP configuration

LSP servers can be configured per-language or disabled entirely.

#### Scenario: Configure a language server

WHEN a module sets:
```nix
{
  lsp.typescript = {
    command = [ "typescript-language-server" "--stdio" ];
    extensions = [ ".ts" ".tsx" ];
  };
}
```
THEN the JSON contains the LSP entry with `command` and `extensions`.

#### Scenario: Disable all LSP

WHEN a module sets:
```nix
{ lsp = false; }
```
THEN the JSON contains `"lsp":false` (boolean, not object).

#### Scenario: Disable single LSP server

WHEN a module sets:
```nix
{ lsp.python = { disabled = true; }; }
```
THEN the JSON contains `{"lsp":{"python":{"disabled":true}}}`.

---

### Requirement: Formatter configuration

Formatters can be configured per-language or disabled entirely.

#### Scenario: Configure a formatter

WHEN a module sets:
```nix
{
  formatter.nix = {
    command = [ "nixfmt" ];
    extensions = [ ".nix" ];
  };
}
```
THEN the JSON contains the formatter entry.

#### Scenario: Disable all formatters

WHEN a module sets:
```nix
{ formatter = false; }
```
THEN the JSON contains `"formatter":false`.

---

### Requirement: TUI configuration

Terminal UI options for scroll behavior and diff display.

#### Scenario: Configure scroll speed

WHEN a module sets:
```nix
{ tui = { scroll_speed = 5.0; scroll_acceleration.enabled = true; diff_style = "stacked"; }; }
```
THEN the JSON contains the TUI config with all three fields.

---

### Requirement: Server configuration

HTTP server settings for port, hostname, mDNS, and CORS.

#### Scenario: Configure server

WHEN a module sets:
```nix
{ server = { port = 8080; hostname = "localhost"; mdns = true; cors = [ "http://localhost:3000" ]; }; }
```
THEN the JSON contains the server config.

---

### Requirement: Keybinds configuration

All 90+ keybind keys are available as options.

#### Scenario: Override keybinds

WHEN a module sets:
```nix
{ keybinds = { app = "?"; session = "s"; }; }
```
THEN the JSON contains `{"keybinds":{"app":"?","session":"s"}}`.

---

### Requirement: Skills configuration

Skill paths and URLs for loading custom skills.

#### Scenario: Configure skills

WHEN a module sets:
```nix
{ skills = { paths = [ "./my-skills" ]; urls = [ "https://skills.example.com/pack.json" ]; }; }
```
THEN the JSON contains the skills config.

---

### Requirement: Watcher configuration

File watcher ignore patterns.

#### Scenario: Configure watcher ignores

WHEN a module sets:
```nix
{ watcher.ignore = [ "*.log" "tmp/" ]; }
```
THEN the JSON contains `{"watcher":{"ignore":["*.log","tmp/"]}}`.

---

### Requirement: Compaction configuration

Auto-compaction settings for context management.

#### Scenario: Configure compaction

WHEN a module sets:
```nix
{ compaction = { auto = false; prune = true; reserved = 4096; }; }
```
THEN the JSON contains the compaction config.

---

### Requirement: Enterprise configuration

Enterprise URL setting.

#### Scenario: Set enterprise URL

WHEN a module sets:
```nix
{ enterprise.url = "https://corp.example.com"; }
```
THEN the JSON contains `{"enterprise":{"url":"https://corp.example.com"}}`.

---

### Requirement: Experimental configuration

Feature flags for experimental functionality.

#### Scenario: Enable experimental features

WHEN a module sets:
```nix
{
  experimental = {
    batch_tool = true;
    openTelemetry = true;
    mcp_timeout = 120000;
    primary_tools = [ "read" "edit" ];
  };
}
```
THEN the JSON contains the experimental config.

---

### Requirement: Env and file template passthrough

Strings containing `{env:...}` and `{file:...}` are written verbatim to JSON — they are opencode runtime templates, not Nix expressions.

#### Scenario: Env template in provider API key

WHEN a module sets:
```nix
{ provider.anthropic.options.apiKey = "{env:ANTHROPIC_API_KEY}"; }
```
THEN the JSON contains the literal string `{env:ANTHROPIC_API_KEY}`.

#### Scenario: File template with Nix interpolation

WHEN a module sets:
```nix
{ agent.plan.prompt = "{file:${./prompts/plan.md}}"; }
```
THEN the Nix interpolation resolves the path to a store path, and the JSON contains e.g. `{file:/nix/store/...-plan.md}`.

#### Scenario: File template with relative path

WHEN a module sets:
```nix
{ agent.plan.prompt = "{file:./instructions.md}"; }
```
THEN the JSON contains the literal string `{file:./instructions.md}`.

---

### Requirement: Module merging

Multiple modules can be composed and their configs are merged following Nix module system semantics.

#### Scenario: Two modules merged

WHEN module A sets `{ theme = "dark"; agent.plan.steps = 50; }` and module B sets `{ logLevel = "debug"; agent.plan.model = "anthropic/claude-sonnet-4-20250514"; }`
THEN the resulting JSON contains all four settings merged.

#### Scenario: List concatenation

WHEN module A sets `{ instructions = [ "a.md" ]; }` and module B sets `{ instructions = [ "b.md" ]; }`
THEN the JSON contains `{"instructions":["a.md","b.md"]}` (concatenated via `mkMerge`).

#### Scenario: Conflict produces error

WHEN module A sets `{ theme = "dark"; }` and module B sets `{ theme = "light"; }`
THEN evaluation fails with a Nix module system conflict error (not silent override).

---

### Requirement: NixOS service integration compatibility

The typed config module MUST be consumable by the NixOS opencode service module through the existing opencode.json generation machinery for per-instance configuration generation.

#### Scenario: Instance configuration compiles to opencode config

- **WHEN** a NixOS instance declares opencode configuration options through the typed module interface
- **THEN** the service integration produces a valid opencode configuration artifact consumed by the instance runtime.

#### Scenario: Existing opencode.json pipeline is reused

- **WHEN** the NixOS service module renders per-instance opencode configuration
- **THEN** it uses the existing opencode.json generation path
- **AND** does not introduce a second independent renderer with divergent behavior.

#### Scenario: Generated config is materialized at HOME config path

- **WHEN** an instance starts with default HOME/stateDir behavior
- **THEN** generated config is exposed at `$HOME/.config/opencode/opencode.json` via symlink to the generated artifact.

### Requirement: Declarative extension integration

Service integration MUST allow declarative extension content (for example skills) to be referenced through generated opencode configuration without replacing module-managed HOME layout.

#### Scenario: Declarative extension references coexist with generated config symlink

- **WHEN** operator declares extension paths (for example `opencode.skills.paths`) in instance config modules
- **THEN** generated `opencode.json` contains those extension references for runtime use
- **AND** generated `opencode.json` symlink at `$HOME/.config/opencode/opencode.json` remains intact.

### Requirement: Multi-instance config generation isolation

Configuration generation MUST be instance-scoped so one instance's config options do not leak into another instance's generated config.

#### Scenario: Two instances with conflicting themes

- **WHEN** instance `a` sets `theme = "dark"` and instance `b` sets `theme = "catppuccin"`
- **THEN** generated configs remain separate and each instance receives only its own value.

### Requirement: Secret-safe integration with runtime environment injection

Service integration MUST support secrets delivered through runtime environment files without requiring secret plaintext in generated static config.

#### Scenario: Secret supplied through environment file

- **WHEN** API credentials are provided via NixOS `environmentFile`
- **THEN** generated static opencode configuration does not embed those secret values and runtime resolves them from environment.

