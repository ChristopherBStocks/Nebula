{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.networking.nftables.firewall;

  ruleSubmodule = types.submodule {
    options = {
      proto = mkOption {
        type = types.enum ["tcp" "udp" "tcp_udp"];
        default = "tcp";
        description = "Protocol to match.";
      };

      port = mkOption {
        type = types.either types.port types.str;
        description = "Port or port range to match (e.g. 22 or \"8000-8080\").";
      };

      source = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Source IPv4 address or CIDR to match. Matches all sources if null.";
      };

      dest = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Destination IPv4 address or CIDR to match. Useful in forward rules to match post-DNAT destinations.";
      };

      interface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Interface to match. Matches all interfaces if null.";
      };

      outInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Outbound interface to match. Matches all interfaces if null.";
      };

      action = mkOption {
        type = types.enum ["accept" "drop" "reject"];
        default = "accept";
        description = "Action to take when the rule matches.";
      };
    };
  };

  mkRules = rule: let
    mkProto = proto: let
      ifaceMatch = lib.optionalString (rule.interface != null) "iifname \"${rule.interface}\" ";
      oifMatch = lib.optionalString (rule.outInterface != null) "oifname \"${rule.outInterface}\" ";
      srcMatch = lib.optionalString (rule.source != null) "ip saddr ${rule.source} ";
      dstMatch = lib.optionalString (rule.dest != null) "ip daddr ${rule.dest} ";
    in "${ifaceMatch}${oifMatch}${srcMatch}${dstMatch}${proto} dport ${toString rule.port} ${rule.action}";
  in
    if rule.proto == "tcp_udp"
    then "${mkProto "tcp"}\n      ${mkProto "udp"}"
    else mkProto rule.proto;

  mkCrowdsecForward = family: set: ''
    chain ${set}-forward {
      type filter hook forward priority filter; policy accept;
      ${family} saddr @${set} drop
    }
  '';
in {
  options.nebula.networking.nftables.firewall = {
    enable = mkEnableOption "nebula nftables firewall";

    checkRuleset = mkOption {
      type = types.bool;
      default = false;
      description = "Run nft --check at build time to validate rules. Requires a Linux build host.";
    };

    trustedInterfaces = mkOption {
      type = types.listOf types.str;
      default = ["lo"];
      description = "Interfaces to unconditionally accept all traffic from.";
    };

    rules = mkOption {
      type = types.listOf ruleSubmodule;
      default = [];
      description = "Input firewall rules.";
    };

    requireForwardRules = mkOption {
      type = types.bool;
      default = false;
      description = "Always create the forward chain with policy drop. When disabled, the forward chain is only created when forwardRules is non-empty.";
    };

    forwardRules = mkOption {
      type = types.listOf ruleSubmodule;
      default = [];
      description = "Forward firewall rules for traffic being routed through this host.";
    };

    crowdsec.checkForwarded = mkOption {
      type = types.bool;
      default = config.services.crowdsec-firewall-bouncer.enable;
      defaultText = lib.literalExpression "config.services.crowdsec-firewall-bouncer.enable";
      description = "Drop forwarded traffic from IPs in the CrowdSec blacklist. Auto-enabled when the CrowdSec firewall bouncer is active.";
    };
  };

  config = mkIf cfg.enable {
    networking.nftables.enable = mkDefault true;
    networking.nftables.checkRuleset = cfg.checkRuleset;

    networking.nftables.tables.nebula-fw = {
      family = "inet";
      content = ''
        chain input {
          type filter hook input priority filter; policy drop;

          ct state invalid drop
          ct state { established, related } accept

          ${lib.concatMapStringsSep "\n      " (iface: "iifname \"${iface}\" accept") cfg.trustedInterfaces}

          icmp type echo-request accept
          icmpv6 type != { nd-redirect, 139 } accept

          ${lib.concatMapStringsSep "\n      " mkRules cfg.rules}
        }

        ${lib.optionalString (cfg.requireForwardRules || cfg.forwardRules != []) ''
          chain forward {
            type filter hook forward priority filter; policy drop;

            ct state invalid drop
            ct state { established, related } accept

            ${lib.concatMapStringsSep "\n      " mkRules cfg.forwardRules}
          }
        ''}
      '';
    };

    networking.nftables.tables.crowdsec.content =
      mkIf cfg.crowdsec.checkForwarded (mkCrowdsecForward "ip" "crowdsec-blacklists");

    networking.nftables.tables.crowdsec6.content =
      mkIf cfg.crowdsec.checkForwarded (mkCrowdsecForward "ip6" "crowdsec6-blacklists");
  };
}
