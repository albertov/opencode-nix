# Language expert subagents: bash, CUDA, Haskell, Nix, Python, ReScript, Rust
{ ... }:

{
  opencode.agent = {
    bash-expert = {
      description = "Expert bash scripting agent specializing in maintainable, production-quality shell scripts with strict ShellCheck compliance";
      mode = "subagent";
      model = "{env:OPENCODE_MODEL_IMPLEMENTER_SMALL}";
      prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/bash-expert.md}";
    };

    cuda-expert = {
      description = "CUDA kernel development, optimization, and Rust integration specialist. Implements high-performance GPU computing solutions.";
      mode = "subagent";
      model = "{env:OPENCODE_MODEL_IMPLEMENTER_BIG}";
      prompt = "{file:./SYSTEM_PROMPT.md}\n{file:agents/cuda-expert.md}";
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
  };
}
