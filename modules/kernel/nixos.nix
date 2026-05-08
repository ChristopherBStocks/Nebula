{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.kernel;
  kernelPackages = {
    lts = pkgs.linuxPackages;
    hardened = pkgs.linuxPackages_hardened;
    latest = pkgs.linuxPackages_latest;
    latest-hardened = pkgs.linuxPackages_latest_hardened;
  };
in {
  options.nebula.kernel = {
    enable = mkEnableOption "nebula kernel";

    variant = mkOption {
      type = types.enum ["lts" "hardened" "latest" "latest-hardened"];
      default = "lts";
      description = "Kernel variant to use (lts, hardened, latest, ...).";
    };
  };

  config = mkIf cfg.enable {
    boot.kernelPackages = mkDefault kernelPackages.${cfg.variant};
  };
}
