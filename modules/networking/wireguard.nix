{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkIf mkOption types;
  cfg = config.nebula.networking.wireguard;

  peerSubmodule = types.submodule {
    options = {
      publicKey = mkOption {
        type = types.str;
        description = "Peer's WireGuard public key.";
      };

      allowedIPs = mkOption {
        type = types.listOf types.str;
        description = "IP ranges routed to this peer (e.g. [\"10.100.0.2/32\"]).";
      };

      endpoint = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Peer's endpoint as host:port. Null for peers that only connect inbound.";
      };

      persistentKeepalive = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Send keepalive every N seconds. Recommended for peers behind NAT.";
      };

      presharedKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to a file containing the pre-shared key for this peer (e.g. from agenix). Adds a post-quantum symmetric layer on top of the Curve25519 key exchange.";
      };
    };
  };

  networkSubmodule = types.submodule {
    options = {
      address = mkOption {
        type = types.str;
        description = "This host's IP/prefix on the VPN (e.g. \"10.100.0.1/24\").";
      };

      listenPort = mkOption {
        type = types.port;
        default = 51820;
        description = "UDP port WireGuard listens on.";
      };

      privateKeyFile = mkOption {
        type = types.path;
        description = "Path to the WireGuard private key file (e.g. from agenix).";
      };

      peers = mkOption {
        type = types.listOf peerSubmodule;
        default = [];
        description = "Peers in this WireGuard network.";
      };
    };
  };

  mkChains = name: net: ''
    chain ${name}-input {
      type filter hook input priority filter - 1; policy accept;
      udp dport ${toString net.listenPort} accept
    };
  '';
in {
  options.nebula.networking.wireguard.networks = mkOption {
    type = types.attrsOf networkSubmodule;
    default = {};
    description = "WireGuard networks. Each attribute name is used as the network interface name.";
  };

  config = mkIf (cfg.networks != {}) {
    networking.nftables.enable = mkDefault true;

    networking.wireguard.interfaces =
      lib.mapAttrs (_name: net: {
        ips = [net.address];
        inherit (net) listenPort;
        inherit (net) privateKeyFile;
        peers = map (peer:
          {inherit (peer) publicKey allowedIPs;}
          // lib.optionalAttrs (peer.endpoint != null) {inherit (peer) endpoint;}
          // lib.optionalAttrs (peer.persistentKeepalive != null) {inherit (peer) persistentKeepalive;}
          // lib.optionalAttrs (peer.presharedKeyFile != null) {inherit (peer) presharedKeyFile;})
        net.peers;
      })
      cfg.networks;

    networking.nftables.tables.nebula-wg = {
      family = "inet";
      content = lib.concatStringsSep "\n" (lib.mapAttrsToList mkChains cfg.networks);
    };
  };
}
