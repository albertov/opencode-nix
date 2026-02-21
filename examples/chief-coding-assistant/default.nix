# Chief Coding Assistant — root module
# Imports all sub-modules and declares top-level options.
#
# Required env vars:
#   OPENCODE_MODEL_BIG           — primary/architect model
#   OPENCODE_MODEL_SMALL         — lightweight task model
#   OPENCODE_MODEL_EXPLORE       — exploration/scout model
#   OPENCODE_MODEL_EXPLORE_BIG   — deep analysis model
#   OPENCODE_MODEL_GENERAL       — general-purpose model
#   OPENCODE_MODEL_IMPLEMENTER_BIG   — large implementer model
#   OPENCODE_MODEL_IMPLEMENTER_SMALL — fast implementer model
#   OPENCODE_MODEL_REVIEW1/2/3   — code reviewer models
#   OPENCODE_MODEL_WEB           — web search model
{ ... }:

{
  imports = [
    ./providers.nix
    ./mcp.nix
    ./permissions.nix
    ./agents/primary.nix
    ./agents/implementers.nix
    ./agents/reviewers.nix
    ./agents/explorers.nix
  ];

  opencode = {
    snapshot = false;
    model = "{env:OPENCODE_MODEL_BIG}";
    small_model = "{env:OPENCODE_MODEL_SMALL}";
    share = "disabled";
    plugin = [ "@tarquinen/opencode-dcp@v2.0.2" ];
    lsp = false;
    compaction = {
      auto = true;
    };
  };
}
