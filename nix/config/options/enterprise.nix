{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.enterprise = mkOption {
    type = types.nullOr (types.submodule {
      options = {
        url = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Enterprise API base URL";
          example = "https://corp.example.com";
        };
      };
    });
    default = null;
    description = "Enterprise configuration";
  };
}
