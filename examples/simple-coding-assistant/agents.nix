# Subagent catalog for the simple coding assistant example.
{ lib, ... }:

let
  defaultModel = "{env:OPENCODE_MODEL}";
in
{
  opencode.agents = {
    # General coordinator for broad research/planning workflows.
    general = {
      mode = "subagent";
      name = "general";
      description = "General-purpose assistant for research, planning, and multi-step tasks";
      model = defaultModel;
      prompt = ''
        You are a practical general coding assistant.
        Help with research, planning, and sequencing multi-step work.
        Start by clarifying goals, constraints, and risks from available context.
        Break work into concrete, verifiable steps with clear ownership.
        Prefer low-risk defaults and call out assumptions explicitly.
        Summarize findings concisely and suggest the next best action.
      '';
      # Allow the orchestration tools needed for planning and handoff.
      permissions = {
        "*" = "deny";
        bash = "allow";
        read = "allow";
        task = "allow";
        todoread = "allow";
        todowrite = "allow";
      };
    };

    # Fast read-only scout for codebase reconnaissance.
    explorer = {
      mode = "subagent";
      name = "explorer";
      description = "Codebase scout for fast reconnaissance — finds files, searches symbols, understands structure";
      model = defaultModel;
      prompt = ''
        You are a fast codebase exploration specialist.
        Locate relevant files quickly and map architecture before implementation.
        Use structural search and targeted reads to answer concrete questions.
        Do not modify files; produce concise evidence with file paths.
        Highlight unknowns and where deeper analysis is needed.
      '';
      # Keep this agent strictly read-only for safe exploration.
      permissions = {
        "*" = "deny";
        read = "allow";
        tilth_tilth_read = "allow";
        tilth_tilth_search = "allow";
        tilth_tilth_files = "allow";
        bash = "allow";
        edit = "deny";
        write = "deny";
      };
    };

    # Implementation agent with file-based prompt for maintainability.
    implementer = {
      mode = "subagent";
      name = "implementer";
      description = "Code writer — implements features and fixes following TDD discipline";
      model = defaultModel;
      prompt = { file = ./skills/implementer-prompt.md; };
      # Grant edit tools but block direct question prompts for deterministic flow.
      permissions = {
        "*" = "deny";
        bash = "allow";
        read = "allow";
        edit = "allow";
        apply_patch = "allow";
        todoread = "allow";
        todowrite = "allow";
        task = "allow";
        question = "deny";
      };
    };

    # Dedicated reviewer for quality checks without write capability.
    reviewer = {
      mode = "subagent";
      name = "reviewer";
      description = "Code reviewer — checks correctness, security, and type safety; never edits";
      model = defaultModel;
      prompt = ''
        You are a rigorous code reviewer.
        Validate correctness against stated behavior and expected edge cases.
        Check for security risks, unsafe assumptions, and privilege issues.
        Prioritize type safety and making invalid states unrepresentable.
        Never modify files; return findings with severity and clear rationale.
      '';
      # Reviewer can inspect and run read-only diagnostics only.
      permissions = {
        "*" = "deny";
        read = "allow";
        bash = "allow";
        edit = "deny";
      };
    };
  };
}
