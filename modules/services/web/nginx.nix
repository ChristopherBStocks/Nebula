{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.services.nginx;

  zoneName = name: builtins.replaceStrings ["." "-"] ["_" "_"] name;

  firstVhost =
    if cfg.virtualHosts != {}
    then lib.head (builtins.sort (a: b: a < b) (lib.attrNames cfg.virtualHosts))
    else null;

  hasRateLimit = lib.any (v: v.rateLimit != null) (lib.attrValues cfg.virtualHosts);
  hasConnLimit = lib.any (v: v.maxConnections != null) (lib.attrValues cfg.virtualHosts);

  rateLimitSubmodule = types.submodule {
    options = {
      rate = mkOption {
        type = types.str;
        default = "10r/s";
        description = "Request rate (e.g. \"10r/s\", \"100r/m\").";
      };

      burst = mkOption {
        type = types.ints.unsigned;
        default = 20;
        description = "Maximum burst size above the rate limit before requests are rejected.";
      };

      nodelay = mkOption {
        type = types.bool;
        default = true;
        description = "Process burst requests immediately rather than delaying them.";
      };
    };
  };

  virtualHostSubmodule = types.submodule {
    options = {
      upstream = mkOption {
        type = types.str;
        description = "Backend URL to proxy to (e.g. \"http://10.0.0.1:8080\").";
      };

      useACMEHost = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Domain of the ACME cert to use for TLS. Requires a cert issued for this domain.";
      };

      forceSSL = mkOption {
        type = types.bool;
        default = true;
        description = "Redirect HTTP to HTTPS. Requires useACMEHost to be set.";
      };

      proxyWebsockets = mkOption {
        type = types.bool;
        default = false;
        description = "Enable WebSocket proxying.";
      };

      sslVerifyUpstream = mkOption {
        type = types.bool;
        default = true;
        description = "Verify the upstream's TLS certificate. Set false for self-signed upstream certs.";
      };

      clientMaxBodySize = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Maximum allowed size of client request body (e.g. \"100m\"). Null uses nginx's 1MB default.";
      };

      proxyTimeout = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Timeout for proxied requests (e.g. \"120s\"). Applies to read, connect, and send. Null uses nginx's 60s default.";
      };

      proxyBuffering = mkOption {
        type = types.bool;
        default = true;
        description = "Buffer upstream responses. Set false for streaming responses (SSE, chunked transfers).";
      };

      rateLimit = mkOption {
        type = types.nullOr rateLimitSubmodule;
        default = null;
        description = "Rate limiting keyed by client IP. Null disables.";
        example = lib.literalExpression ''
          {
            rate = "10r/s";
            burst = 20;
            nodelay = true;
          }
        '';
      };

      maxConnections = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Maximum concurrent connections per client IP. Null disables connection limiting.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra directives appended to the proxy location block.";
      };
    };
  };
in {
  options.nebula.services.nginx = {
    enable = mkEnableOption "nebula nginx reverse proxy";

    quic = mkOption {
      type = types.bool;
      default = false;
      description = "Enable HTTP/3 (QUIC) for all virtual hosts. Advertises via Alt-Svc header.";
    };

    virtualHosts = mkOption {
      type = types.attrsOf virtualHostSubmodule;
      default = {};
      description = "Virtual hosts to configure. The attribute name is used as the server name.";
      example = lib.literalExpression ''
        {
          "nessus.hydro.group" = {
            upstream = "https://10.0.0.5:8834";
            useACMEHost = "nessus.hydro.group";
            sslVerifyUpstream = false;
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions =
      lib.mapAttrsToList (name: vhost: {
        assertion = !(vhost.forceSSL && vhost.useACMEHost == null);
        message = "nebula.services.nginx.virtualHosts.${name}: forceSSL = true requires useACMEHost to be set.";
      })
      cfg.virtualHosts;

    users.users.nginx.extraGroups =
      lib.optional
      (lib.any (v: v.useACMEHost != null) (lib.attrValues cfg.virtualHosts))
      "acme";

    # nginx's dynamic GID isn't resolvable in the Nix build sandbox
    services.logrotate.checkConfig = false;

    services.nginx = {
      enable = true;
      serverTokens = false;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedBrotliSettings = true;

      appendHttpConfig = lib.concatStringsSep "\n" (
        # Rate limiting zones and log level
        lib.mapAttrsToList (
          name: vhost:
            lib.optionalString (vhost.rateLimit != null)
            "limit_req_zone $binary_remote_addr zone=${zoneName name}:10m rate=${vhost.rateLimit.rate};"
        )
        cfg.virtualHosts
        ++ lib.optional hasRateLimit "limit_req_log_level warn;"
        # Connection limiting zones and log level
        ++ lib.mapAttrsToList (
          name: vhost:
            lib.optionalString (vhost.maxConnections != null)
            "limit_conn_zone $binary_remote_addr zone=conn_${zoneName name}:10m;"
        )
        cfg.virtualHosts
        ++ lib.optional hasConnLimit "limit_conn_log_level warn;"
        # Catch-all default server — silently drops requests for unknown hosts
        ++ [
          ''
            server {
              listen 80 default_server;
              listen [::]:80 default_server;
              return 444;
            }
            server {
              listen 443 ssl default_server;
              listen [::]:443 ssl default_server;
              ssl_reject_handshake on;
            }
          ''
        ]
      );

      virtualHosts = lib.mapAttrs (name: vhost:
        {
          forceSSL = mkDefault vhost.forceSSL;
          extraConfig = lib.concatStringsSep "\n" (
            lib.optional (vhost.clientMaxBodySize != null)
            "client_max_body_size ${vhost.clientMaxBodySize};"
            ++ lib.optional cfg.quic
            "add_header Alt-Svc 'h3=\":443\"; ma=86400' always;"
          );
          locations."/" = {
            proxyPass = mkDefault vhost.upstream;
            proxyWebsockets = mkDefault vhost.proxyWebsockets;
            extraConfig = lib.concatStringsSep "\n" (
              lib.optional (lib.hasPrefix "https://" vhost.upstream) "proxy_ssl_server_name on;"
              ++ lib.optional (!vhost.sslVerifyUpstream) "proxy_ssl_verify off;"
              ++ lib.optionals (vhost.proxyTimeout != null) [
                "proxy_read_timeout ${vhost.proxyTimeout};"
                "proxy_connect_timeout ${vhost.proxyTimeout};"
                "proxy_send_timeout ${vhost.proxyTimeout};"
              ]
              ++ lib.optional (!vhost.proxyBuffering) "proxy_buffering off;"
              ++ lib.optionals (vhost.rateLimit != null) [
                "limit_req zone=${zoneName name} burst=${toString vhost.rateLimit.burst}${lib.optionalString vhost.rateLimit.nodelay " nodelay"};"
                "limit_req_status 429;"
              ]
              ++ lib.optionals (vhost.maxConnections != null) [
                "limit_conn conn_${zoneName name} ${toString vhost.maxConnections};"
                "limit_conn_status 429;"
              ]
              ++ ["proxy_hide_header Server;" "proxy_hide_header X-Powered-By;"]
              ++ lib.optional (vhost.extraConfig != "") vhost.extraConfig
            );
          };
        }
        // lib.optionalAttrs (vhost.useACMEHost != null) {
          useACMEHost = mkDefault vhost.useACMEHost;
        }
        // lib.optionalAttrs cfg.quic {
          http3 = true;
          quic = true;
          reuseport = name == firstVhost;
        })
      cfg.virtualHosts;
    };
  };
}
