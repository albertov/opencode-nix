# Code reviewer subagents: three parallel review instances
_:

let
  reviewerDescription = "Expert code review specialist. Proactively reviews code for quality, security, and maintainability";
  reviewerPrompt = "{file:agents/code-reviewer.md}";
  reviewerPermission = {
    edit = "deny";
    question = "deny";
    bash = "deny";
  };
in
{
  opencode.agent = {
    code-reviewer = {
      description = reviewerDescription;
      mode = "subagent";
      model = "{env:OPENCODE_MODEL_REVIEW1}";
      prompt = reviewerPrompt;
      permission = reviewerPermission;
    };

    code-reviewer-alonzo = {
      description = reviewerDescription;
      mode = "subagent";
      model = "{env:OPENCODE_MODEL_REVIEW2}";
      prompt = reviewerPrompt;
      permission = reviewerPermission;
    };

    code-reviewer-ada = {
      description = reviewerDescription;
      mode = "subagent";
      model = "{env:OPENCODE_MODEL_REVIEW3}";
      prompt = reviewerPrompt;
      permission = reviewerPermission;
    };
  };
}
