# Example: Chief Coding Assistant

A production-grade opencode configuration with multiple AI providers, a roster
of specialized agents, and deny-by-default permissions. This is a real working
setup — use it as a reference for building your own multi-agent workflow or
import it directly and override what you need.

Features:
- **Deny-by-default permissions** with fine-grained tool access
- **Multiple AI providers**: Modal AI, Ollama (local), Amazon Bedrock
- **Primary agents**: `chief` (orchestrator), `bird` (drinking-bird loop), `plan` (planning), `invoicer` (invoice processing)
- **Subagent roster**: Language experts (Rust, Haskell, Python, Nix, CUDA, ReScript), code reviewers, codebase explorers
- **Tilth MCP** for fast code navigation

## Required Environment Variables

| Variable | Purpose |
|----------|---------|
| `OPENCODE_MODEL_BIG` | Primary/architect model (e.g. `anthropic/claude-sonnet-4-5`) |
| `OPENCODE_MODEL_SMALL` | Lightweight tasks (e.g. `anthropic/claude-haiku-4-5`) |
| `OPENCODE_MODEL_EXPLORE` | Exploration scouts (e.g. `anthropic/claude-haiku-4-5`) |
| `OPENCODE_MODEL_EXPLORE_BIG` | Deep analysis (e.g. `anthropic/claude-sonnet-4-5`) |
| `OPENCODE_MODEL_GENERAL` | General-purpose agent |
| `OPENCODE_MODEL_IMPLEMENTER_BIG` | Large implementers (Nix, CUDA, Rust guru) |
| `OPENCODE_MODEL_IMPLEMENTER_SMALL` | Fast implementers (Rust, Haskell, Python) |
| `OPENCODE_MODEL_REVIEW1/2/3` | Three parallel code reviewer instances |
| `OPENCODE_MODEL_WEB` | Web search agent |

## Usage

### Build the config file

```bash
nix build .#examples.chief-coding-assistant
cat result  # opencode.json
```

### Add to your flake

```nix
{
  inputs.ocnix.url = "github:jmatsushita/ocnix";

  outputs = { self, nixpkgs, ocnix, ... }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ ocnix.overlays.default ];
    };
  in {
    packages.x86_64-linux.my-opencode = pkgs.lib.opencode.wrapOpenCode {
      name = "opencode";
      modules = [
        ocnix.examples.chief-coding-assistant
        # Your local overrides:
        { opencode.model = "anthropic/claude-opus-4-5"; }
      ];
    };
  };
}
```

### Extend or override modules

```nix
# Override the primary model for a specific project
pkgs.lib.opencode.mkOpenCodeConfig [
  (import "${ocnix}/examples/chief-coding-assistant")
  { opencode.model = "openai/o3"; }
]
```

## Module Structure

```
chief-coding-assistant/
├── default.nix         — top-level settings (model, share, plugins, lsp, compaction)
├── providers.nix       — Modal AI, Ollama, Amazon Bedrock
├── mcp.nix             — Tilth code navigation MCP server
├── permissions.nix     — deny-by-default permission policy
└── agents/
    ├── primary.nix     — chief, bird, plan, explore, general, invoicer
    ├── implementers.nix — language expert subagents
    ├── reviewers.nix   — code review panel (3 parallel instances)
    └── explorers.nix   — codebase exploration & research agents
```

## Complete Schema Coverage

This example demonstrates full schema parity with the upstream opencode configuration schema.
All previously unsupported field families are now fully modeled:

- **Provider registry metadata** (`npm`, `name`, `models`): Custom OpenAI-compatible providers can specify their npm package, display name, and per-model capability metadata (capabilities, token limits, modalities). See `providers.nix`.
- **Path-scoped permissions** (`external_directory`): The `permission` map now supports nested path-glob rules under `external_directory`, allowing fine-grained filesystem access control. See `permissions.nix`.
- **Per-skill permissions** (`skill`): Skill-level permission maps are supported — each skill name maps independently to `allow`, `ask`, or `deny`. See `permissions.nix`.
- **Agent compatibility flag** (`primary`): The `primary` boolean field is now typed on agents. When `primary = true` and `mode` is unset, the config emitter normalizes to `mode = "primary"`. When `mode` is explicitly set, it takes precedence.
