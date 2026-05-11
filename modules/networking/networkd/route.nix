{lib}: let
  inherit (lib) mkOption types;
  address = import ./address.nix {inherit lib;};

  type = types.submodule {
    options = {
      destination = mkOption {
        inherit (address) type;
        default = {
          address = "0.0.0.0";
          prefixLength = 0;
        };
        description = "Route destination.";
      };
      gateway = mkOption {
        type = types.str;
        description = "Next hop gateway.";
      };
      table = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Routing table ID.";
      };
    };
  };

  mk = r: {
    routeConfig =
      {
        Destination = "${r.destination.address}/${toString r.destination.prefixLength}";
        Gateway = r.gateway;
      }
      // lib.optionalAttrs (r.table != null) {Table = r.table;};
  };
in {inherit type mk;}
