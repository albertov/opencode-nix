{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.tui = mkOption {
    type = types.nullOr (types.submodule {
      options = {
        scroll_speed = mkOption {
          type = types.nullOr types.float;
          default = null;
          description = "Mouse scroll speed multiplier (>= 0.001)";
        };
        scroll_acceleration = mkOption {
          type = types.nullOr (types.submodule {
            options = {
              enabled = mkOption {
                type = types.nullOr types.bool;
                default = null;
                description = "Enable scroll acceleration";
              };
            };
          });
          default = null;
          description = "Scroll acceleration settings";
        };
        diff_style = mkOption {
          type = types.nullOr (types.enum [ "auto" "stacked" ]);
          default = null;
          description = "Diff display style in TUI";
        };
      };
    });
    default = null;
    description = "Terminal UI settings";
  };
}
