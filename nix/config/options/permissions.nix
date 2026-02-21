{ lib, ... }:

let
  inherit (lib) mkOption types;

  # Matches upstream PermissionAction: the three allowed actions for a tool.
  permissionAction = types.enum [
    "allow"
    "ask"
    "deny"
  ];

  # Matches upstream PermissionRule = PermissionAction | PermissionObject.
  # A rule is either a simple action or a nested map (path/glob → action).
  # Examples:
  #   bash = "allow"                          — simple action
  #   external_directory = { "/tmp/**" = "allow"; "/home/*" = "deny"; }
  #   skill = { facturas-compras-holded = "allow"; }
  permissionRule = types.either permissionAction (types.attrsOf permissionAction);

in
{
  options.opencode.permission = mkOption {
    type = types.nullOr (types.attrsOf permissionRule);
    default = null;
    description = ''
      Global tool permission rules. Maps tool names to either a simple action or a nested
      map of sub-paths/sub-tools to actions.

      Simple action (applies to the whole tool):
        bash = "allow"
        edit = "ask"
        "*" = "deny"   # wildcard default for unlisted tools

      Nested map (path-scoped or sub-tool-scoped):
        external_directory = { "/tmp/**" = "allow"; "/home/*" = "deny"; }
        skill = { facturas-compras-holded = "allow"; }

      Known tools: read, edit, glob, grep, list, bash, task, external_directory,
      todowrite, todoread, question, webfetch, websearch, codesearch, lsp, skill.
      Use "*" as a wildcard key to set the default permission for unlisted tools.
    '';
    example = {
      "*" = "deny";
      bash = "allow";
      edit = "allow";
      external_directory = {
        "/tmp/**" = "allow";
      };
      skill = {
        facturas-compras-holded = "allow";
      };
    };
  };
}
