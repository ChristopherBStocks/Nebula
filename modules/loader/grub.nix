{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.loader.grub;
in {
  options.nebula.loader.grub = {
    enable = mkEnableOption "nebula grub loader";

    devices = mkOption {
      type = types.listOf types.str;
      default = ["/dev/sda"];
      description = "Grub devices";
    };

    efiSupport = mkOption {
      type = types.bool;
      default = false;
      description = "Enable EFI support for GRUB.";
    };

    useOSProber = mkOption {
      type = types.bool;
      default = false;
      description = "Detect other installed operating systems for the boot menu.";
    };

    configurationLimit = mkOption {
      type = types.ints.positive;
      default = 10;
      description = "Maximum number of generations shown in the boot menu.";
    };
  };

  config = mkIf cfg.enable {
    boot.loader.grub = {
      enable = mkDefault true;
      devices = mkDefault cfg.devices;
      inherit (cfg) efiSupport useOSProber configurationLimit;
    };
  };
}
