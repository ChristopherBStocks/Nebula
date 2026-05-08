{lib, ...}: {
  config.flake.lib = {
    mkUser = import ./mkUser.nix;
    mkSystemUser = import ./mkSystemUser.nix;
  };
}
