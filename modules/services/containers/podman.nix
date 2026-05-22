{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.nebula.services.podman;
in {
  options.nebula.services.podman = {
    enable = mkEnableOption "nebula Podman container runtime";

    dockerCompat = mkOption {
      type = types.bool;
      default = false;
      description = "Install a docker-compatible wrapper so tools that call the docker binary use Podman instead.";
    };

    socket = {
      enable = mkEnableOption "the Podman API socket at /run/podman/podman.sock";
    };

    compose = {
      enable = mkEnableOption "podman-compose";
    };

    autoPrune = {
      enable = mkEnableOption "periodic Podman system prune" // {default = true;};

      dates = mkOption {
        type = types.str;
        default = "weekly";
        description = "Systemd calendar expression for the auto-prune timer (e.g. \"weekly\", \"daily\", \"Mon *-*-* 03:00:00\").";
      };

      flags = mkOption {
        type = types.listOf types.str;
        default = ["--all"];
        description = "Extra flags passed to podman system prune. nixpkgs always appends --force.";
        example = ["--all" "--volumes"];
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = lib.optional cfg.compose.enable pkgs.podman-compose;

    virtualisation.podman = {
      enable = true;
      dockerCompat = cfg.dockerCompat;
      dockerSocket.enable = cfg.socket.enable;

      autoPrune = {
        enable = cfg.autoPrune.enable;
        dates = cfg.autoPrune.dates;
        flags = cfg.autoPrune.flags;
      };
    };
  };
}
