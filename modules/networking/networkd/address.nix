{lib}: let
  inherit (lib) mkOption types;
  type = types.submodule {
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
  mk = a: {Address = "${a.address}/${toString a.prefixLength}";};
in {inherit type mk;}
