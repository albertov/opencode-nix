{ pkgs, lib }:

let
  moduleSystem = import ./default.nix;

  # Recursively strip null values and resulting empty objects from a config value.
  # Nested attrsets (e.g. permission.external_directory = { "/tmp/**" = "allow"; })
  # are preserved as-is — only null values and empty {} results are elided.
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

  # Apply mode/primary precedence rules to a single agent attrset.
  # Precedence:
  #   1. mode is set     → mode is authoritative; primary is preserved for schema compat.
  #   2. mode unset, primary = true → emit mode = "primary" for runtime semantics.
  #   3. both null       → cleanConfig will strip them; no action needed.
  normalizeAgent = agent:
    if agent ? mode && agent.mode != null then
      # mode is authoritative — preserve both fields
      agent
    else if agent ? primary && agent.primary == true then
      # primary=true with no mode → inject mode="primary" for runtime clarity
      agent // { mode = "primary"; }
    else
      agent;

  # Apply agent normalization across all agents in the config (if any).
  normalizeConfig = config:
    if config ? agent && config.agent != null then
      config // { agent = lib.mapAttrs (_: normalizeAgent) config.agent; }
    else
      config;

  mkOpenCodeConfig = modules:
    let
      evaluated = lib.evalModules {
        modules = [ moduleSystem ] ++ modules;
      };
      normalized = normalizeConfig evaluated.config.opencode;
      cleaned = cleanConfig normalized;
      configJSON = builtins.toJSON cleaned;
    in
    pkgs.writeText "opencode.json" configJSON;

  wrapOpenCode = { name ? "opencode", modules, opencode }:
    let
      configDrv = mkOpenCodeConfig modules;
    in
    pkgs.symlinkJoin {
      inherit name;
      paths = [ opencode ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/opencode \
          --set OPENCODE_CONFIG "${configDrv}"
      '' + lib.optionalString (name != "opencode") ''
        mv $out/bin/opencode $out/bin/${name}
      '';
    };

in
{
  inherit mkOpenCodeConfig wrapOpenCode;
}
