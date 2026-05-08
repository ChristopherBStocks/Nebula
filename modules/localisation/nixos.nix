{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.localisation;
in {
  options.nebula.localisation = {
    enable = mkEnableOption "nebula localisation";

    timeZone = mkOption {
      type = types.str;
      default = "Europe/London";
      description = "Time zone.";
    };

    defaultLocale = mkOption {
      type = types.str;
      default = "en_GB.UTF-8";
      description = "Default locale, applied to all LC_* categories.";
    };

    xkbLayout = mkOption {
      type = types.str;
      default = "gb";
      description = "X keyboard layout (e.g. gb, us).";
    };

    xkbOptions = mkOption {
      type = types.str;
      default = "";
      description = "X keyboard options (e.g. eurosign:e,caps:escape). Empty string disables.";
    };

    consoleKeyMap = mkOption {
      type = types.str;
      default = "uk";
      description = "Console keymap. Ignored when useXkbConfig is true.";
    };

    consoleFont = mkOption {
      type = types.str;
      default = "";
      description = "Console font (e.g. Lat2-Terminus16). Empty string uses the system default.";
    };

    useXkbConfig = mkOption {
      type = types.bool;
      default = false;
      description = "Derive the console keymap from the XKB layout instead of consoleKeyMap.";
    };
  };

  config = mkIf cfg.enable {
    time.timeZone = mkDefault cfg.timeZone;
    i18n = {
      defaultLocale = mkDefault cfg.defaultLocale;
      extraLocaleSettings = {
        LC_ADDRESS = cfg.defaultLocale;
        LC_IDENTIFICATION = cfg.defaultLocale;
        LC_MEASUREMENT = cfg.defaultLocale;
        LC_MONETARY = cfg.defaultLocale;
        LC_NAME = cfg.defaultLocale;
        LC_NUMERIC = cfg.defaultLocale;
        LC_PAPER = cfg.defaultLocale;
        LC_TELEPHONE = cfg.defaultLocale;
        LC_TIME = cfg.defaultLocale;
      };
    };
    services.xserver.xkb = {
      layout = mkDefault cfg.xkbLayout;
      options = mkIf (cfg.xkbOptions != "") (mkDefault cfg.xkbOptions);
    };
    console = {
      keyMap = mkIf (!cfg.useXkbConfig) (mkDefault cfg.consoleKeyMap);
      useXkbConfig = mkDefault cfg.useXkbConfig;
      font = mkIf (cfg.consoleFont != "") (mkDefault cfg.consoleFont);
    };
  };
}
