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
          description = "Mouse scroll speed multiplier. Must be >= 0.001. Higher values scroll faster.";
        };
        scroll_acceleration = mkOption {
          type = types.nullOr (types.submodule {
            options = {
              enabled = mkOption {
                type = types.nullOr types.bool;
                default = null;
                description = "When true, scroll speed increases with faster mouse wheel movement.";
              };
            };
          });
          default = null;
          description = "Scroll acceleration settings for the TUI message view.";
        };
        diff_style = mkOption {
          type = types.nullOr (types.enum [ "auto" "stacked" ]);
          default = null;
          description = ''
            Diff display layout. 'auto' picks the best layout for the terminal width;
            'stacked' always shows old and new content vertically.
          '';
        };
      };
    });
    default = null;
    description = "Terminal UI display and interaction settings.";
  };
}
