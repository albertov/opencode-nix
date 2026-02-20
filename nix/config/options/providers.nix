{ lib, ... }:

let
  inherit (lib) mkOption types;

  providerSubmodule = types.submodule {
    options = {
      whitelist = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Model IDs to exclusively show from this provider. When set, only these models appear in the picker.";
        example = [ "claude-sonnet-4-20250514" "claude-haiku-4-5-20250514" ];
      };
      blacklist = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Model IDs to hide from this provider. These models are removed from the picker.";
        example = [ "claude-3-opus-20240229" ];
      };
      options = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            apiKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                API key for authenticating with this provider. Supports '{env:VAR}' syntax
                to read the key from an environment variable at runtime, avoiding secrets in config files.
              '';
              example = "{env:ANTHROPIC_API_KEY}";
            };
            baseURL = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Override the default base URL for API requests (e.g. for proxies or self-hosted instances).";
              example = "https://api.corp-proxy.example.com/v1";
            };
            enterpriseUrl = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Enterprise API endpoint URL. Used with enterprise provider configurations.";
            };
            timeout = mkOption {
              type = types.nullOr (types.either (types.enum [ false ]) types.number);
              default = null;
              description = "Request timeout in milliseconds. Set to false to disable timeouts entirely.";
            };
          };
        });
        default = null;
        description = "Provider-specific connection and authentication options.";
      };
    };
  };
in
{
  options.opencode.provider = mkOption {
    type = types.nullOr (types.attrsOf providerSubmodule);
    default = null;
    description = ''
      Provider configurations keyed by provider ID (e.g. 'anthropic', 'openai', 'google').
      Each provider can have its own authentication, model filtering, and connection settings.
    '';
  };
}
