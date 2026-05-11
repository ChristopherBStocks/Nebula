{lib}: let
  inherit (lib) mkOption types;

  type = types.submodule {
    options = {
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable this jail.";
      };
      backend = mkOption {
        type = types.enum ["auto" "systemd" "pyinotify" "gamin" "polling"];
        default = "auto";
        description = "Log backend to use.";
      };
      port = mkOption {
        type = types.str;
        description = "Port or port name to ban on.";
      };
      filter = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Filter name to use. Defaults to the jail name when null.";
      };
      mode = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Filter mode (e.g. aggressive).";
      };
      logPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to log file. Required when backend is not systemd.";
      };
      maxRetry = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Override global maxRetry for this jail.";
      };
      banTime = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override global banTime for this jail.";
      };
      findTime = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override global findTime for this jail.";
      };
    };
  };

  mk = j: {
    settings =
      {inherit (j) enabled backend port;}
      // lib.optionalAttrs (j.filter != null) {inherit (j) filter;}
      // lib.optionalAttrs (j.mode != null) {inherit (j) mode;}
      // lib.optionalAttrs (j.logPath != null) {logpath = j.logPath;}
      // lib.optionalAttrs (j.maxRetry != null) {maxretry = j.maxRetry;}
      // lib.optionalAttrs (j.banTime != null) {bantime = j.banTime;}
      // lib.optionalAttrs (j.findTime != null) {findtime = j.findTime;};
  };
in {inherit type mk;}
