{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.opencode.server = mkOption {
    type = types.nullOr (types.submodule {
      options = {
        port = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = "HTTP server port number";
        };
        hostname = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "HTTP server hostname to bind to";
        };
        mdns = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Enable mDNS service discovery";
        };
        mdnsDomain = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "mDNS domain name";
        };
        cors = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "CORS allowed origin domains";
        };
      };
    });
    default = null;
    description = "HTTP server settings";
  };
}
