{ lib, ... }:

let
  inherit (lib) mkOption types;

  lspServerSubmodule = types.submodule {
    options = {
      command = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Command and arguments to launch the LSP server process. The server must communicate via stdio. Required for custom LSP servers; omit when disabling a built-in LSP.";
        example = [
          "typescript-language-server"
          "--stdio"
        ];
      };
      extensions = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "File extensions this LSP handles. Required for custom LSP servers to associate file types.";
        example = [
          ".ts"
          ".tsx"
        ];
      };
      disabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "When true, disables this specific LSP server without removing its configuration.";
      };
      env = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        description = "Environment variables passed to the LSP server process.";
      };
      initialization = mkOption {
        type = types.nullOr (types.attrsOf types.anything);
        default = null;
        description = "LSP initialization options sent during the initialize handshake. Accepts arbitrary JSON matching the server's expected initializationOptions.";
      };
    };
  };
in
{
  options.opencode.lsp = mkOption {
    type = types.nullOr (types.either (types.enum [ false ]) (types.attrsOf lspServerSubmodule));
    default = null;
    description = ''
      LSP server configurations keyed by language name.
      Set to false to disable all LSP servers entirely.
    '';
  };
}
