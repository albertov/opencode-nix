{ lib, ... }:

let
  inherit (lib) mkOption types;

  providerSubmodule = types.submodule {
    options = {
      whitelist = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Model IDs to show from this provider";
      };
      blacklist = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Model IDs to hide from this provider";
      };
      options = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            apiKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "API key. Can use '{env:VAR}' syntax";
            };
            baseURL = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Override base URL for API requests";
            };
            enterpriseUrl = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Enterprise API URL";
            };
            timeout = mkOption {
              type = types.nullOr (types.either (types.enum [ false ]) types.number);
              default = null;
              description = "Request timeout in ms, or false to disable";
            };
          };
        });
        default = null;
        description = "Provider-specific connection options";
      };
    };
  };
in
{
  options.opencode.provider = mkOption {
    type = types.nullOr (types.attrsOf providerSubmodule);
    default = null;
    description = "Provider configurations keyed by provider ID (e.g. 'anthropic', 'openai')";
  };
}
