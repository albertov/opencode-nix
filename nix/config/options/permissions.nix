{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.permission = mkOption {
    type = types.nullOr (types.attrsOf (types.enum [ "allow" "ask" "deny" ]));
    default = null;
    description = ''
      Global tool permission rules. Maps tool names to an action:
      'allow' — run without prompting; 'ask' — prompt before each use; 'deny' — block entirely.
      Known tools: read, edit, glob, grep, list, bash, task, external_directory,
      todowrite, todoread, question, webfetch, websearch, codesearch, lsp, skill.
      Use "*" as a wildcard key to set the default permission for unlisted tools.
    '';
    example = { bash = "allow"; edit = "ask"; "*" = "deny"; };
  };
}
