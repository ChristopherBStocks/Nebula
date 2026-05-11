{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.services.crowdsec.bouncers.firewall;
in {
  options.nebula.services.crowdsec.bouncers.firewall = {
    enable = mkEnableOption "nebula CrowdSec firewall bouncer";

    bouncerName = mkOption {
      type = types.str;
      default = "crowdsec-firewall-bouncer";
      description = "Name to register the bouncer as with the local CrowdSec LAPI.";
    };

    apiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to a file containing the bouncer API key for an external LAPI. When null, the bouncer auto-registers with the local CrowdSec instance.";
    };
  };

  config = mkIf cfg.enable {
    services.crowdsec-firewall-bouncer = {
      enable = true;
      registerBouncer = {
        enable = mkDefault (cfg.apiKeyFile == null);
        bouncerName = mkDefault cfg.bouncerName;
      };
      secrets.apiKeyPath = mkIf (cfg.apiKeyFile != null) cfg.apiKeyFile;
    };
  };
}
