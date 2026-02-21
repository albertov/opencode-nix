# Skill definitions for the simple coding assistant example.
{ ... }:

{
  opencode.skills = [
    {
      name = "commit";
      description = "Generate clean conventional commit messages following project conventions";
      # Inline prompt — good for short, self-contained skills.
      prompt = ''
        You are a git commit message expert. Follow conventional commits format:
        <type>(<scope>): <description>

        Types: feat, fix, docs, refactor, test, chore
        Rules:
        - Imperative mood ("add" not "added")
        - Max 72 chars in subject line
        - Reference issue numbers when relevant
        Trigger: when user says "commit" or asks to create a commit.
      '';
    }
    {
      name = "code-review";
      description = "Structured code review checklist for correctness, security, and maintainability";
      # File-based prompt — good for longer prompts shared across teams.
      prompt = { file = ./code-review.md; };
    }
  ];
}
