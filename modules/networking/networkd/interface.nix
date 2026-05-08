{lib}: let
  inherit (lib) mkOption types;
  address = import ./address.nix {inherit lib;};
  route = import ./route.nix {inherit lib;};
  rule = import ./rule.nix {inherit lib;};

  type = types.submodule {
    options = {
      matchBy = mkOption {
        type = types.enum ["name" "mac"];
        default = "name";
        description = "Match interface by name or MAC address.";
      };
      mac = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "MAC address. Required when matchBy is \"mac\".";
      };
      addresses = mkOption {
        type = types.listOf address.type;
        default = [];
        description = "Static IPv4 addresses.";
      };
      gateway = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default gateway.";
      };
      nameservers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "DNS nameservers.";
      };
      dhcp = mkOption {
        type = types.enum ["no" "yes" "ipv4" "ipv6"];
        default = "no";
        description = "DHCP mode.";
      };
      routes = mkOption {
        type = types.listOf route.type;
        default = [];
        description = "Additional routes. Use with table for policy routing.";
      };
      rules = mkOption {
        type = types.listOf rule.type;
        default = [];
        description = "Policy routing rules for source-based routing.";
      };
    };
  };

  mk = name: i: {
    matchConfig =
      if i.matchBy == "mac"
      then {MACAddress = i.mac;}
      else {Name = name;};
    networkConfig =
      {DHCP = i.dhcp;}
      // lib.optionalAttrs (i.gateway != null) {Gateway = i.gateway;}
      // lib.optionalAttrs (i.nameservers != []) {DNS = lib.concatStringsSep " " i.nameservers;};
    addresses = map address.mk i.addresses;
    routes = map route.mk i.routes;
    routingPolicyRules = map rule.mk i.rules;
  };
in {inherit type mk;}
