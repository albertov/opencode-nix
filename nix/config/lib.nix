{ pkgs, lib }:

let
  moduleSystem = import ./default.nix;

  # Recursively strip null values and resulting empty objects from a config value.
  # Nested attrsets (e.g. permission.external_directory = { "/tmp/**" = "allow"; })
  # are preserved as-is — only null values and empty {} results are elided.
  cleanConfig =
    value:
    if builtins.isAttrs value then
      let
        stripped = lib.mapAttrs (_n: cleanConfig) (lib.filterAttrs (_n: v: v != null) value);
        noEmpty = lib.filterAttrs (_n: v: !(builtins.isAttrs v && v == { })) stripped;
      in
      noEmpty
    else if builtins.isList value then
      map cleanConfig value
    else
      value;

  # Apply mode/primary precedence rules to a single agent attrset.
  # Precedence:
  #   1. mode is set     → mode is authoritative; primary is preserved for schema compat.
  #   2. mode unset, primary = true → emit mode = "primary" for runtime semantics.
  #   3. both null       → cleanConfig will strip them; no action needed.
  normalizeAgent =
    agent:
    if agent ? mode && agent.mode != null then
      # mode is authoritative — preserve both fields.
      # Warn when primary=true conflicts with a non-primary mode.
      let
        warned =
          if agent ? primary && builtins.elem (agent.primary or null) [ true ] && agent.mode != "primary" then
            builtins.trace "opencode-nix: warning: agent has primary=true but mode=\"${agent.mode}\"; mode takes precedence" agent
          else
            agent;
      in
      warned
    else if agent ? primary && builtins.elem (agent.primary or null) [ true ] then
      # primary=true with no mode → inject mode="primary" for runtime clarity
      agent // { mode = "primary"; }
    else
      agent;

  # Apply agent normalization across all agents in the config (if any).
  normalizeConfig =
    config:
    if config ? agent && config.agent != null then
      config // { agent = lib.mapAttrs (_: normalizeAgent) config.agent; }
    else
      config;

  mkOpenCodeConfig =
    modules:
    let
      evaluated = lib.evalModules {
        modules = [ moduleSystem ] ++ modules;
      };
      normalized = normalizeConfig evaluated.config.opencode;
      cleaned = cleanConfig normalized;
      configJSON = builtins.toJSON cleaned;
    in
    pkgs.writeText "opencode.json" configJSON;

  wrapOpenCode =
    {
      name ? "opencode",
      modules,
      opencode ?
        pkgs.opencode
          or (throw "wrapOpenCode: 'opencode' argument not provided and pkgs.opencode is unavailable"),
    }:
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
      ''
      + lib.optionalString (name != "opencode") ''
        mv $out/bin/opencode $out/bin/${name}
      '';
    };

in
{
  inherit mkOpenCodeConfig wrapOpenCode;
}
