# Simple Coding Assistant example.
# This is a minimal NixOS service-module pattern; for a production-grade setup,
# see examples/chief-coding-assistant.
{ pkgs, ... }:

let
  ocLib =
    if pkgs ? lib && pkgs.lib ? opencode then
      pkgs.lib.opencode
    else
      import ../../nix/config/lib.nix {
        inherit pkgs;
        inherit (pkgs) lib;
      };
in

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
    configFile = ocLib.mkOpenCodeConfig [
      ./agents.nix
      ./permissions.nix
      ./skills
    ];
  };
}
