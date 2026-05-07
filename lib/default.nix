{lib, ...}: {
  options.flake.darwinModules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.deferredModuleWith {});
    default = {};
    description = "nix-darwin modules provided by this flake.";
  };

  options.flake.homeManagerModules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.deferredModuleWith {});
    default = {};
    description = "Home Manager modules provided by this flake.";
  };
}
