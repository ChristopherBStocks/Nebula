{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.networking.networkManager;
  hasNameservers = cfg.nameservers != [];
  hasInterfaces = cfg.interfaces != {};

  addressOpts = types.submodule {
    options = {
      address = mkOption {
        type = types.str;
        description = "IPv4 address.";
      };
      prefixLength = mkOption {
        type = types.ints.between 0 32;
        description = "IPv4 prefix length.";
      };
    };
  };
in {
  options.nebula.networking.networkManager = {
    enable = mkEnableOption "nebula NetworkManager";

    nameservers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Static nameservers. Disables DHCP when set.";
    };

    defaultGateway = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default gateway.";
    };

    powerSave = mkOption {
      type = types.bool;
      default = false;
      description = "Enables WiFi power saving.";
    };

    interfaces = mkOption {
      type = types.attrsOf (types.submodule {
        options.addresses = mkOption {
          type = types.listOf addressOpts;
          default = [];
          description = "IPv4 addresses for this interface.";
        };
      });
      default = {};
      description = "Static interface configurations, keyed by interface name.";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      networkmanager = {
        enable = true;
        dns = mkIf hasNameservers (mkDefault "none");
        wifi.powersave = mkDefault cfg.powerSave;
      };
      useDHCP = mkIf hasNameservers (mkDefault false);
      dhcpcd.enable = mkIf hasNameservers (mkDefault false);
      nameservers = mkDefault cfg.nameservers;
      defaultGateway = mkIf (cfg.defaultGateway != null) (mkDefault cfg.defaultGateway);
      interfaces = mkIf hasInterfaces (lib.mapAttrs (_: i: {
          ipv4.addresses = i.addresses;
        })
        cfg.interfaces);
    };
  };
}
