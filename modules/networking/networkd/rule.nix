{lib}: let
  inherit (lib) mkOption types;
  address = import ./address.nix {inherit lib;};

  type = types.submodule {
    options = {
      from = mkOption {
        type = address.type;
        description = "Source address/prefix to match.";
      };
      table = mkOption {
        type = types.ints.positive;
        description = "Routing table ID to use for matched traffic.";
      };
      priority = mkOption {
        type = types.ints.positive;
        default = 1000;
        description = "Rule priority. Lower values take precedence.";
      };
    };
  };

  mk = r: {
    routingPolicyRuleConfig = {
      From = "${r.from.address}/${toString r.from.prefixLength}";
      Table = r.table;
      Priority = r.priority;
    };
  };
in {inherit type mk;}
