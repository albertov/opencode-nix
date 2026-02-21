# Full Nix port of opencode.sample.jsonc.
# This module, when evaluated via mkOpenCodeConfig, should produce JSON
# that is structurally identical to the sample (modulo key order and
# JSONC comments / commented-out sections).
_:

{
  opencode = {
    "$schema" = "https://opencode.ai/config.json";
    snapshot = false;
    model = "{env:OPENCODE_MODEL_BIG}";
    small_model = "{env:OPENCODE_MODEL_SMALL}";
    share = "disabled";
    plugin = [ "@tarquinen/opencode-dcp@v2.0.2" ];
    compaction.auto = true;
    lsp = false;

    provider = {
      custom-openai = {
        npm = "@ai-sdk/openai-compatible";
        name = "Custom Provider";
        options = {
          baseURL = "https://api.example-provider.com/v1";
          apiKey = "{file:secrets/api.key}";
        };
        models."org/large-language-model" = {
          name = "Large Language Model";
          limit = {
            context = 200000;
            output = 128000;
          };
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
        };
      };
      ollama = {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama";
        options = {
          baseURL = "http://localhost:11434/v1";
        };
        models = {
          "codestral-22b-v0.1" = {
            name = "Codestral 22B";
            tool_call = true;
            limit = {
              context = 200000;
              output = 32768;
            };
          };
          "llava-v1.6-34b" = {
            name = "LLaVA 1.6 34B";
            tool_call = true;
            reasoning = true;
            attachment = true;
            modalities = {
              input = [
                "text"
                "image"
              ];
              output = [ "text" ];
            };
            limit = {
              context = 256000;
              output = 32768;
            };
          };
          "llama-3.3-70b-instruct" = {
            name = "Llama 3.3 70B";
            temperature = true;
            tool_call = true;
            limit = {
              context = 198000;
              output = 64000;
            };
          };
          "llama-3.3-70b-instruct-bf16" = {
            name = "Llama 3.3 70B (bf16)";
            temperature = true;
            tool_call = true;
            limit = {
              context = 64000;
              output = 64000;
            };
          };
        };
      };
      amazon-bedrock = {
        options = {
          region = "us-east-1";
          profile = "default";
        };
      };
    };

    mcp.tilth = {
      type = "local";
      command = [
        "tilth"
        "--mcp"
      ];
      enabled = true;
      timeout = 30000;
    };

    permission = {
      "*" = "deny";
      bash = "allow";
      task = "allow";
      codesearch = "allow";
      lsp = "allow";
      edit = "allow";
      apply_patch = "allow";
      read = "allow";
      skill = "allow";
      prune = "allow";
      distill = "allow";
      todoread = "allow";
      todowrite = "allow";
      external_directory = {
        "/tmp/**" = "allow";
        "/tmp/*" = "allow";
      };
      list = "deny";
      grep = "deny";
      glob = "deny";
      search = "deny";
      tilth_tilth_read = "allow";
      tilth_tilth_files = "allow";
      tilth_tilth_search = "allow";
      tilth_tilth_map = "allow";
    };

    agent = {
      beads-task-agent = {
        disable = true;
      };
      explore = {
        model = "{env:OPENCODE_MODEL_EXPLORE}";
      };
      general = {
        model = "{env:OPENCODE_MODEL_GENERAL}";
      };
      data-processor = {
        model = "ollama/llava-v1.6-34b";
        primary = true;
        prompt = "{file:./prompts/data-processor.md}";
        permission = {
          "*" = "deny";
          skill = {
            data-import-tool = "allow";
          };
          read = "allow";
          bash = "allow";
          glob = "allow";
          prune = "deny";
          distill = "deny";
          external_directory = {
            "/tmp/**" = "allow";
            "/tmp/*" = "allow";
          };
        };
      };
      plan = {
        permission = {
          edit = "deny";
          apply_patch = "deny";
          question = "allow";
          bash = "deny";
        };
      };
      chief = {
        mode = "primary";
        prompt = "{file:./SYSTEM_PROMPT.md}";
        permission = {
          question = "allow";
          external_task = "allow";
        };
      };
      bird = {
        mode = "primary";
        options = {
          compaction = {
            monitorEnabled = true;
            warningThreshold = 0.55;
            criticalThreshold = 0.75;
            forceCompactionEnabled = true;
            cooldownMs = 60000;
          };
        };
        permission = {
          question = "allow";
        };
      };
      bash-expert = {
        description = "Expert bash scripting agent specializing in maintainable, production-quality shell scripts with strict ShellCheck compliance";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_IMPLEMENTER_SMALL}";
        prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/bash-expert.md}";
      };
      code-reviewer = {
        description = "Expert code review specialist. Proactively reviews code for quality, security, and maintainability";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_REVIEW1}";
        prompt = "{file:agents/code-reviewer.md}";
        permission = {
          edit = "deny";
          question = "deny";
          bash = "deny";
        };
      };
      code-reviewer-alonzo = {
        description = "Expert code review specialist. Proactively reviews code for quality, security, and maintainability";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_REVIEW2}";
        prompt = "{file:agents/code-reviewer.md}";
        permission = {
          edit = "deny";
          question = "deny";
          bash = "deny";
        };
      };
      code-reviewer-ada = {
        description = "Expert code review specialist. Proactively reviews code for quality, security, and maintainability";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_REVIEW3}";
        prompt = "{file:agents/code-reviewer.md}";
        permission = {
          edit = "deny";
          question = "deny";
          bash = "deny";
        };
      };
      codebase-analyzer = {
        description = "Analyzes codebase implementation details. Call the codebase-analyzer agent when you need to find detailed information about specific components. As always, the more detailed your request prompt, the better! :)";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_EXPLORE_BIG}";
        prompt = "{file:agents/codebase-analyzer.md}";
      };
      codebase-pattern-finder = {
        description = "Finds similar implementations, usage examples, and patterns to model after. Returns concrete code examples, not just file locations. Use when you need existing patterns as templates.";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_EXPLORE}";
        prompt = "{file:agents/codebase-pattern-finder.md}";
      };
      codebase-scout = {
        description = "Fast scout for exploring codebases. Finds files by feature/topic AND distills structured intel (types, functions, tests). Use for reconnaissance before implementation.";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_EXPLORE}";
        prompt = "{file:agents/codebase-scout.md}";
      };
      cuda-expert = {
        description = "CUDA kernel development, optimization, and Rust integration specialist. Implements high-performance GPU computing solutions.";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_IMPLEMENTER_BIG}";
        prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/cuda-expert.md}";
      };
      git-historian = {
        description = "Expert git historian for repository analysis and code archaeology";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_EXPLORE}";
        prompt = "{file:agents/git-historian.md}";
      };
      haskell-expert = {
        description = "Haskell expert engineer. Efficiently implements features, fixes bugs and refactors Haskell.";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_IMPLEMENTER_SMALL}";
        prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/haskell-expert.md}";
      };
      nix-devops-expert = {
        description = "Nix/NixOS specialist for flakes, devShells, and reproducible builds. Use for flake.nix, dev environments, NixOS modules, or Nix dependency issues.";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_IMPLEMENTER_BIG}";
        prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/nix-devops-expert.md}";
      };
      python-expert = {
        description = "Expert Python development with strong typing, modern tooling (uv, mypy, pytest), and best practices. Use for writing typed Python, refactoring for type safety, implementing algorithms, or setting up Python projects.";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_IMPLEMENTER_SMALL}";
        prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/python-expert.md}";
      };
      rescript-react-expert = {
        description = "ReScript React specialist. Type-safe components, modern patterns (RescriptCore over Belt), eliminates %raw blocks. Use for writing, reviewing, or modernizing ReScript React code.";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_IMPLEMENTER_SMALL}";
        prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/rescript-react-expert.md}";
      };
      rust-expert = {
        description = "Rust expert for clean architecture, idiomatic patterns, and maintainability. Functional patterns, immutable data structures, best practices. Use for creating, refactoring, or reviewing Rust code.";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_IMPLEMENTER_SMALL}";
        prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/rust-expert.md}";
      };
      rust-guru = {
        description = "Rust guru for complex problems. Use ONLY when rust-expert fails";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_IMPLEMENTER_BIG}";
        prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/rust-expert.md}";
      };
      type-precision-analyst = {
        description = "Analyzes algebraic types for precision issues using Prolog-based cardinality analysis. Given a spec (valid states) and optional type, reports precision metrics and suggests improvements.";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_EXPLORE_BIG}";
        prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/type-precision-analyst.md}";
        permission = {
          edit = "deny";
          bash = "allow";
        };
      };
      web-search-researcher = {
        description = "Deep web researcher for finding current information beyond training data. Searches strategically, fetches authoritative sources, and synthesizes findings with citations. Use when you need up-to-date or specialized web information.";
        mode = "subagent";
        model = "{env:OPENCODE_MODEL_WEB}";
        prompt = "{file:agents/web-search-researcher.md}";
        permission = {
          "*" = "deny";
          webfetch = "allow";
          todowrite = "allow";
          todoread = "allow";
          websearch = "allow";
        };
      };
    };
  };
}
