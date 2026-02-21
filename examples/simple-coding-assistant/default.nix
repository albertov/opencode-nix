# Simple Coding Assistant example.
# This is a minimal NixOS service-module pattern; for a production-grade setup,
# see examples/chief-coding-assistant.
{ pkgs, ... }:

{
  services.opencode.instances.my-project = {
    # Keep the project worktree outside the module so operators can point each
    # deployment at the correct repository path.
    directory = "/srv/projects/my-project";

    listen.port = 8787;

    # Non-secret runtime settings can be declared inline.
    environment.OPENCODE_LOG_LEVEL = "info";

    # Secrets should come from a runtime file (for example via sops-nix), never
    # from Nix literals that would end up in the store.
    environmentFile = "/run/secrets/opencode-my-project";

    # Add common coding-assistant CLI dependencies to PATH.
    path = [
      pkgs.git
      pkgs.ripgrep
    ];

    # Compose opencode.json from focused modules.
    opencodeCfg = [
      ./agents.nix
      ./permissions.nix
      ./skills
    ];
  };
}
