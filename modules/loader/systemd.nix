{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.loader.systemd;
in {
  options.nebula.loader.systemd = {
    enable = mkEnableOption "nebula systemd-boot loader";

    configurationLimit = mkOption {
      type = types.ints.positive;
      default = 10;
      description = "Maximum number of generations shown in the boot menu.";
    };

    editor = mkOption {
      type = types.bool;
      default = false;
      description = "Allow editing kernel parameters at boot.";
    };
  };

  config = mkIf cfg.enable {
    boot.loader = {
      systemd-boot = {
        enable = mkDefault true;
        inherit (cfg) configurationLimit editor;
      };
      efi.canTouchEfiVariables = mkDefault true;
    };
  };
}
