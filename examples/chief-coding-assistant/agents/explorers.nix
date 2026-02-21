# Codebase exploration and research subagents
_:

{
  opencode.agent = {
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

    git-historian = {
      description = "Expert git historian for repository analysis and code archaeology";
      mode = "subagent";
      model = "{env:OPENCODE_MODEL_EXPLORE}";
      prompt = "{file:agents/git-historian.md}";
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
}
