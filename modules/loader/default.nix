_: {
  flake.nixosModules = {
    loader-grub = ./grub.nix;
    loader-systemd = ./systemd.nix;
  };
}
