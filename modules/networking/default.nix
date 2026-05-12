_: {
  flake.nixosModules.networkManager = ./networkManager.nix;
  flake.nixosModules.networkd = ./networkd.nix;
  flake.nixosModules.nftables-nat = ./nftables/nat.nix;
  flake.nixosModules.nftables-firewall = ./nftables/firewall.nix;
  flake.nixosModules.wireguard = ./wireguard.nix;
}
