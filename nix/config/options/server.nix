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
          description = "TCP port number for the opencode HTTP server to listen on.";
          example = 8080;
        };
        hostname = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Hostname or IP address for the HTTP server to bind to.";
          example = "127.0.0.1";
        };
        mdns = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "When true, advertises the server via mDNS for local network discovery.";
        };
        mdnsDomain = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Domain name used for mDNS service advertisement.";
        };
        cors = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "List of allowed CORS origins. Each entry is an origin URL permitted to make cross-origin requests.";
          example = [ "http://localhost:3000" ];
        };
      };
    });
    default = null;
    description = "HTTP server settings for the opencode web interface and API.";
  };
}
