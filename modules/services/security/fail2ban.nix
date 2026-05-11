{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.services.fail2ban;
  jail = import ./fail2ban/jail.nix {inherit lib;};
in {
  options.nebula.services.fail2ban = {
    enable = mkEnableOption "nebula fail2ban";

    maxRetry = mkOption {
      type = types.ints.positive;
      default = 3;
      description = "Number of failures before banning.";
    };

    banTime = mkOption {
      type = types.str;
      default = "24h";
      description = "Duration of ban.";
    };

    ignoreIPs = mkOption {
      type = types.listOf types.str;
      default = ["127.0.0.1/8" "::1"];
      description = "IPs and subnets to never ban.";
    };

    banTimeIncrement = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Progressively increase ban time on repeat offenders.";
      };
      multipliers = mkOption {
        type = types.str;
        default = "1 2 4 8 16 32 64";
        description = "Space-separated ban time multipliers.";
      };
      maxTime = mkOption {
        type = types.str;
        default = "168h";
        description = "Maximum ban time when incrementing.";
      };
    };

    jails = mkOption {
      type = types.attrsOf jail.type;
      default = {};
      description = "Extra jail configurations, keyed by jail name.";
    };
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      maxretry = mkDefault cfg.maxRetry;
      bantime = mkDefault cfg.banTime;
      ignoreIP = mkDefault cfg.ignoreIPs;
      bantime-increment = {
        enable = mkDefault cfg.banTimeIncrement.enable;
        multipliers = mkDefault cfg.banTimeIncrement.multipliers;
        maxtime = mkDefault cfg.banTimeIncrement.maxTime;
      };
      jails = lib.mapAttrs (_: j: jail.mk j) cfg.jails;
    };
  };
}
