# Permission model: deny-by-default with specific tool allowances.
# Supports nested maps for path-scoped and sub-tool-scoped rules.
_:

{
  opencode.permission = {
    "*" = "deny";
    bash = "allow";
    task = "allow";
    codesearch = "allow";
    lsp = "allow";
    edit = "allow";
    apply_patch = "allow";
    read = "allow";
    prune = "allow";
    distill = "allow";
    todoread = "allow";
    todowrite = "allow";
    # Path-scoped external directory access
    external_directory = {
      "/tmp/**" = "allow";
    };
    # Per-skill permissions
    skill = {
      commit = "allow";
      data-import-tool = "allow";
      tilth-tools-efficiency = "allow";
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
}
