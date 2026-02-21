_: {
  opencode.agent = {
    general = {
      description = "General-purpose assistant for research, planning, and multi-step tasks";
      mode = "subagent";
      prompt = ''
        You are a general-purpose coding assistant. Help with research, planning,
        analysis, and coordination tasks. Prefer reading and understanding code
        before suggesting changes. Use todo lists to track multi-step work.
        Never modify files unless explicitly asked.
      '';
      permission = {
        "*" = "deny";
        bash = "allow";
        read = "allow";
        task = "allow";
        todoread = "allow";
        todowrite = "allow";
      };
    };

    explorer = {
      description = "Codebase scout — finds files, searches symbols, understands structure";
      mode = "subagent";
      prompt = ''
        You are a fast codebase explorer. Your job is reconnaissance only:
        find files, search for symbols, and understand structure.
        Never edit files. Never run commands that modify state.
        Return precise, structured findings.
      '';
      permission = {
        "*" = "deny";
        read = "allow";
        bash = "allow";
      };
    };

    implementer = {
      description = "Code writer — implements features and fixes following TDD discipline";
      mode = "subagent";
      prompt = "{file:${./skills/implementer-prompt.md}}";
      permission = {
        "*" = "deny";
        bash = "allow";
        read = "allow";
        edit = "allow";
        apply_patch = "allow";
        todoread = "allow";
        todowrite = "allow";
        task = "allow";
      };
    };

    reviewer = {
      description = "Code reviewer — checks correctness, security, and type safety; never edits";
      mode = "subagent";
      prompt = ''
        You are a code reviewer. Analyze code for correctness, security vulnerabilities,
        type safety, and maintainability. Be specific: cite file and line numbers.
        Never edit files. Never run commands that modify state.
        Focus on what matters: bugs, security issues, unclear invariants.
      '';
      permission = {
        "*" = "deny";
        read = "allow";
        bash = "allow";
      };
    };
  };
}
