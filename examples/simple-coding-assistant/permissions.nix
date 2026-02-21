# Global permission baseline for the simple coding assistant example.
_:

{
  # Baseline policy: allow common tools globally, then tighten per-agent with
  # each agent's own permission block.
  opencode.permission = {
    "*" = "deny";
    read = "allow";
    bash = "allow";
    edit = "allow";
    apply_patch = "allow";
    task = "allow";
    todoread = "allow";
    todowrite = "allow";
  };
}
