{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.networking.nftables.nat;

  mkRule = fwd: proto: let
    isRange = builtins.isString fwd.port;
    portSuffix =
      if fwd.destPort != null
      then ":${toString fwd.destPort}"
      else if !isRange
      then ":${toString fwd.port}"
      else "";
    addrMatch = lib.optionalString (fwd.address != null) "ip daddr ${fwd.address} ";
  in "iif \"${fwd.interface}\" ${addrMatch}${proto} dport ${toString fwd.port} dnat to ${fwd.dest}${portSuffix}";

  mkRules = fwd:
    if fwd.proto == "tcp_udp"
    then "${mkRule fwd "tcp"}\n      ${mkRule fwd "udp"}"
    else mkRule fwd fwd.proto;

  masqueradeRules =
    lib.concatMapStringsSep "\n      "
    (iface: "oif \"${iface}\" masquerade")
    (lib.unique (
      cfg.masqueradeInterfaces
      ++ map (fwd:
        if fwd.masqInterface != null
        then fwd.masqInterface
        else fwd.interface)
      cfg.forwards
    ));
in {
  options.nebula.networking.nftables.nat = {
    enable = mkEnableOption "nebula NAT port forwarding";

    checkRuleset = mkOption {
      type = types.bool;
      default = false;
      description = "Run nft --check at build time to validate rules. Requires a Linux build host.";
    };

    masqueradeInterfaces = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Interfaces to masquerade outbound traffic on, without requiring port forwarding rules.";
    };

    forwards = mkOption {
      default = [];
      description = "Port forwarding rules.";
      type = types.listOf (types.submodule {
        options = {
          interface = mkOption {
            type = types.str;
            description = "External interface traffic arrives on.";
          };

          proto = mkOption {
            type = types.enum ["tcp" "udp" "tcp_udp"];
            default = "tcp";
            description = "Protocol to forward.";
          };

          address = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "External IP to match. Useful when the interface has multiple IPs. Matches all if null.";
          };

          port = mkOption {
            type = types.either types.port types.str;
            description = "External port or port range (e.g. 25565 or \"19132-19133\").";
          };

          dest = mkOption {
            type = types.str;
            description = "Destination IP address.";
          };

          destPort = mkOption {
            type = types.nullOr (types.either types.port types.str);
            default = null;
            description = "Destination port or range. Defaults to source port.";
          };

          masqInterface = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Interface to masquerade on. Defaults to the input interface if null.";
          };
        };
      });
    };
  };

  config = mkIf cfg.enable {
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    networking.nftables.enable = mkDefault true;
    networking.nftables.checkRuleset = cfg.checkRuleset;
    networking.nftables.tables.nebula-nat = {
      family = "ip";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          ${lib.concatMapStringsSep "\n      " mkRules cfg.forwards}
        }

        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          ${masqueradeRules}
        }
      '';
    };
  };
}
