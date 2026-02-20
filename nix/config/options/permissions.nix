{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.permission = mkOption {
    type = types.nullOr (types.attrsOf (types.enum [ "allow" "ask" "deny" ]));
    default = null;
    description = ''
      Tool permission rules. Maps tool names to actions.
      Known tools: read, edit, glob, grep, list, bash, task, external_directory,
      todowrite, todoread, question, webfetch, websearch, codesearch, lsp, skill.
      Use "*" as a wildcard key for default permission.
    '';
    example = { bash = "allow"; edit = "ask"; "*" = "deny"; };
  };
}
