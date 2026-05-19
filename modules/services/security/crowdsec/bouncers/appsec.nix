{lib, ...}: let
  inherit (lib) mkEnableOption mkOption types;
in {
  options.nebula.services.crowdsec.bouncers.appsec = {
    enable = mkEnableOption "CrowdSec AppSec bouncer auto-registration";

    bouncerName = mkOption {
      type = types.str;
      default = "nginx-appsec";
      description = "Name to register the bouncer as with the local CrowdSec LAPI.";
    };
  };
}
