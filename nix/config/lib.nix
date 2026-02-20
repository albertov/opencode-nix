{ pkgs, lib }:

let
  moduleSystem = import ./default.nix;

  # Recursively strip null values from an attrset
  cleanConfig = value:
    if builtins.isAttrs value then
      let
        stripped = lib.mapAttrs (n: v: cleanConfig v)
                     (lib.filterAttrs (n: v: v != null) value);
        noEmpty = lib.filterAttrs (n: v:
          !(builtins.isAttrs v && v == {})) stripped;
      in noEmpty
    else if builtins.isList value then
      map cleanConfig value
    else
      value;

in
{
  mkOpenCodeConfig = modules:
    let
      evaluated = lib.evalModules {
        modules = [ moduleSystem ] ++ modules;
      };
      cleaned = cleanConfig evaluated.config.opencode;
      configJSON = builtins.toJSON cleaned;
    in
    pkgs.writeText "opencode.json" configJSON;
}
