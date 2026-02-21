# Adapter module for NixOS service submodule use.
# Lifts opencode.* option declarations to the top level so users write:
#   config.model = "sonnet"  (not config.opencode.model)
{ lib, ... }:
let
  configOptions =
    (lib.evalModules {
      modules = [ ./default.nix ];
    }).options.opencode;
in
{
  options = configOptions;
}
