{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.nebula.networking.networkd;
  interface = import ./networkd/interface.nix {inherit lib;};
in {
  options.nebula.networking.networkd = {
    enable = mkEnableOption "nebula systemd-networkd";

    interfaces = mkOption {
      type = types.attrsOf interface.type;
      default = {};
      description = "Network interface configurations, keyed by interface name.";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      useNetworkd = true;
      dhcpcd.enable = false;
    };
    services.resolved.enable = true;
    systemd.network = {
      enable = true;
      networks = lib.mapAttrs' (name: i:
        lib.nameValuePair "10-${name}" (interface.mk name i))
      cfg.interfaces;
    };
  };
}
