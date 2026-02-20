{ lib, ... }:

let
  inherit (lib) mkOption types;

  lspServerSubmodule = types.submodule {
    options = {
      command = mkOption {
        type = types.listOf types.str;
        description = "Command to launch the LSP server";
        example = [ "typescript-language-server" "--stdio" ];
      };
      extensions = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "File extensions this LSP handles (required for custom LSPs)";
        example = [ ".ts" ".tsx" ];
      };
      disabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Disable this specific LSP server";
      };
      env = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        description = "Environment variables for the LSP process";
      };
      initialization = mkOption {
        type = types.nullOr (types.attrsOf types.anything);
        default = null;
        description = "LSP initialization options (arbitrary JSON)";
      };
    };
  };
in
{
  options.opencode.lsp = mkOption {
    type = types.nullOr (types.either (types.enum [ false ]) (types.attrsOf lspServerSubmodule));
    default = null;
    description = "LSP server configurations. Set to false to disable all LSP servers.";
  };
}
