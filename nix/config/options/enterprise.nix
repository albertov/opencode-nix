{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.enterprise = mkOption {
    type = types.nullOr (
      types.submodule {
        options = {
          url = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Enterprise API base URL for organizations using a self-hosted opencode backend.";
            example = "https://opencode.corp.example.com";
          };
        };
      }
    );
    default = null;
    description = "Enterprise configuration for organizations with self-hosted opencode deployments.";
  };
}
