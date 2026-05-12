_: {
  flake.nixosModules.networkManager = ./networkManager.nix;
  flake.nixosModules.networkd = ./networkd.nix;
  flake.nixosModules.nftables-nat = ./nftables/nat.nix;
}
