{ lib, ... }:

let
  inherit (lib) mkOption types;

  # Modality values supported by the upstream schema.
  modalityType = types.enum [
    "text"
    "audio"
    "image"
    "video"
    "pdf"
  ];

  # Per-model metadata matching ModelsDev.Model fields used by OpenAI-compatible providers.
  modelSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Human-readable display name for this model as returned by the provider registry.";
        example = "GPT-4o";
      };
      attachment = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether this model supports file/image attachments in prompts.";
      };
      reasoning = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether this model supports explicit reasoning/thinking steps.";
      };
      tool_call = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether this model supports structured tool/function calling.";
      };
      temperature = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether this model accepts a temperature sampling parameter.";
      };
      limit = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              context = mkOption {
                type = types.nullOr types.ints.positive;
                default = null;
                description = "Maximum context window size in tokens.";
                example = 128000;
              };
              output = mkOption {
                type = types.nullOr types.ints.positive;
                default = null;
                description = "Maximum output length in tokens.";
                example = 16384;
              };
            };
          }
        );
        default = null;
        description = "Token limit metadata for this model.";
      };
      modalities = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              input = mkOption {
                type = types.nullOr (types.listOf modalityType);
                default = null;
                description = "Input modalities this model accepts (e.g. text, image).";
                example = [
                  "text"
                  "image"
                ];
              };
              output = mkOption {
                type = types.nullOr (types.listOf modalityType);
                default = null;
                description = "Output modalities this model can produce.";
                example = [ "text" ];
              };
            };
          }
        );
        default = null;
        description = "Supported input and output modalities for this model.";
      };
    };
  };

  providerSubmodule = types.submodule {
    options = {
      npm = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          NPM package identifier for this provider, as used in the upstream provider registry
          (e.g. "@ai-sdk/openai"). Required for custom OpenAI-compatible providers.
        '';
        example = "@ai-sdk/openai";
      };
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Human-readable display name for this provider shown in the UI.";
        example = "Modal AI";
      };
      whitelist = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Model IDs to exclusively show from this provider. When set, only these models appear in the picker.";
        example = [
          "claude-sonnet-4-20250514"
          "claude-haiku-4-5-20250514"
        ];
      };
      blacklist = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Model IDs to hide from this provider. These models are removed from the picker.";
        example = [ "claude-3-opus-20240229" ];
      };
      models = mkOption {
        type = types.nullOr (types.attrsOf modelSubmodule);
        default = null;
        description = ''
          Per-model metadata registry for this provider. Useful for OpenAI-compatible providers
          where model capabilities are not automatically discovered from the provider registry.
          Keys are model IDs; values are ModelDev-compatible metadata objects.
        '';
        example = lib.literalExpression ''
          {
            "gpt-4o" = {
              name = "GPT-4o";
              attachment = true;
              reasoning = false;
              tool_call = true;
              temperature = true;
              limit = { context = 128000; output = 16384; };
              modalities = { input = [ "text" "image" ]; output = [ "text" ]; };
            };
          }
        '';
      };
      options = mkOption {
        type = types.nullOr (types.attrsOf types.anything);
        default = null;
        description = ''
          Provider-specific connection and authentication options.
          Common keys: apiKey, baseURL, enterpriseUrl, setCacheKey, timeout.
          Accepts any provider-specific keys (e.g. region, profile for Amazon Bedrock)
          since the upstream schema uses a catchall for unknown option keys.

          The apiKey field supports '{env:VAR}' syntax to read secrets from environment
          variables at runtime.
        '';
        example = {
          apiKey = "{env:ANTHROPIC_API_KEY}";
          baseURL = "https://api.corp-proxy.example.com/v1";
        };
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
      Each provider can have its own authentication, model filtering, connection settings,
      display metadata (npm, name), and a per-model registry for capability metadata.
    '';
  };
}
