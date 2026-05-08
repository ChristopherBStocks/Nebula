{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.users;
in {
  options.nebula.users = {
    enable = mkEnableOption "nebula users";

    mutableUsers = mkOption {
      type = types.bool;
      default = false;
      description = "Allow users and groups to be managed imperatively.";
    };
  };

  config = mkIf cfg.enable {
    users.mutableUsers = mkDefault cfg.mutableUsers;
  };
}
