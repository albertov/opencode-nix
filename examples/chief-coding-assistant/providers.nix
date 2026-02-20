# Provider configurations: Custom OpenAI-compatible, Ollama (local), Amazon Bedrock
{ ... }:

{
  opencode.provider = {
    # Custom OpenAI-compatible provider
    # npm and name provide provider registry metadata for the model picker UI.
    custom-openai = {
      npm = "@ai-sdk/openai";
      name = "Custom Provider";
      options = {
        baseURL = "https://api.example-provider.com/v1";
        apiKey = "{file:secrets/api.key}";
      };
      # Per-model metadata: capabilities, token limits, and supported modalities.
      # Required for OpenAI-compatible providers that are not in the upstream registry.
      models."my-org/custom-model-v1" = {
        name = "Custom Model v1";
        attachment = true;
        reasoning = true;
        tool_call = true;
        temperature = true;
        limit = { context = 200000; output = 64000; };
        modalities = { input = [ "text" "image" ]; output = [ "text" ]; };
      };
    };

    # Ollama — local model server
    ollama.options = {
      baseURL = "http://localhost:11434/v1";
    };

    # Amazon Bedrock — provider-specific options passed through to the SDK
    amazon-bedrock = {};
  };
}
