{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.services.acme;

  certSubmodule = types.submodule {
    options = {
      domain = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Primary domain. Defaults to the attribute name.";
      };

      extraDomainNames = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional SANs to include in the certificate.";
      };

      email = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override contact email for this certificate.";
      };

      server = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override ACME server URL (e.g. Let's Encrypt staging).";
      };

      dnsProvider = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "DNS provider for DNS-01 challenge (e.g. \"cloudflare\"). Inherits default if null.";
      };

      credentialFiles = mkOption {
        type = types.attrsOf types.path;
        default = {};
        description = "Credential files passed as systemd credentials for the DNS provider.";
      };

      webroot = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Webroot path for HTTP-01 challenge. Leave null when using DNS-01.";
      };

      dnsPropagationCheck = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Override DNS propagation check for this certificate. Inherits default if null.";
      };

      keyType = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override key type for this certificate (e.g. \"EC256\", \"RSA2048\"). Inherits default if null.";
      };

      reloadServices = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Services to reload after this certificate is renewed.";
      };

      group = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Group that owns the certificate files. Inherits default if null.";
      };
    };
  };
in {
  options.nebula.services.acme = {
    enable = mkEnableOption "nebula ACME certificate management";

    acceptTerms = mkOption {
      type = types.bool;
      default = false;
      description = "Accept the CA's Terms of Service. Must be true to obtain certificates.";
    };

    email = mkOption {
      type = types.str;
      description = "Default contact email for ACME account registration and renewal notices.";
    };

    server = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default ACME server URL. Null uses Let's Encrypt production.";
    };

    dnsProvider = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default DNS provider for DNS-01 challenges (e.g. \"cloudflare\", \"route53\").";
    };

    credentialFiles = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Default credential files passed as systemd credentials for the DNS provider.";
    };

    dnsPropagationCheck = mkOption {
      type = types.bool;
      default = true;
      description = "Wait for DNS propagation to complete before requesting certificates.";
    };

    keyType = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default key type for all certificates (e.g. \"EC256\", \"EC384\", \"RSA2048\", \"RSA4096\"). Null uses the ACME client default.";
    };

    group = mkOption {
      type = types.str;
      default = "acme";
      description = "Default group that owns certificate files.";
    };

    reloadServices = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Default services to reload after any certificate renewal.";
    };

    certs = mkOption {
      type = types.attrsOf certSubmodule;
      default = {};
      description = "Certificates to obtain. The attribute name is used as the primary domain when domain is not set.";
      example = lib.literalExpression ''
        {
          "example.com" = {
            extraDomainNames = [ "www.example.com" ];
            reloadServices = [ "nginx" ];
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    security.acme = {
      acceptTerms = mkDefault cfg.acceptTerms;

      defaults =
        {
          email = mkDefault cfg.email;
          dnsPropagationCheck = mkDefault cfg.dnsPropagationCheck;
          group = mkDefault cfg.group;
        }
        // lib.optionalAttrs (cfg.server != null) {server = mkDefault cfg.server;}
        // lib.optionalAttrs (cfg.dnsProvider != null) {dnsProvider = mkDefault cfg.dnsProvider;}
        // lib.optionalAttrs (cfg.credentialFiles != {}) {credentialFiles = mkDefault cfg.credentialFiles;}
        // lib.optionalAttrs (cfg.keyType != null) {keyType = mkDefault cfg.keyType;}
        // lib.optionalAttrs (cfg.reloadServices != []) {reloadServices = mkDefault cfg.reloadServices;};

      certs = lib.mapAttrs (name: cert:
        {
          domain = mkDefault (
            if cert.domain != null
            then cert.domain
            else name
          );
        }
        // lib.optionalAttrs (cert.extraDomainNames != []) {extraDomainNames = mkDefault cert.extraDomainNames;}
        // lib.optionalAttrs (cert.email != null) {email = mkDefault cert.email;}
        // lib.optionalAttrs (cert.server != null) {server = mkDefault cert.server;}
        // lib.optionalAttrs (cert.dnsProvider != null) {dnsProvider = mkDefault cert.dnsProvider;}
        // lib.optionalAttrs (cert.credentialFiles != {}) {credentialFiles = mkDefault cert.credentialFiles;}
        // lib.optionalAttrs (cert.webroot != null) {webroot = mkDefault cert.webroot;}
        // lib.optionalAttrs (cert.dnsPropagationCheck != null) {dnsPropagationCheck = mkDefault cert.dnsPropagationCheck;}
        // lib.optionalAttrs (cert.keyType != null) {keyType = mkDefault cert.keyType;}
        // lib.optionalAttrs (cert.reloadServices != []) {reloadServices = mkDefault cert.reloadServices;}
        // lib.optionalAttrs (cert.group != null) {group = mkDefault cert.group;})
      cfg.certs;
    };
  };
}
