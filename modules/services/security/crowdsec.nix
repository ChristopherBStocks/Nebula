{config, lib, ...}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.services.crowdsec;
  acquisition = import ./crowdsec/acquisition.nix {inherit lib;};
in {
  options.nebula.services.crowdsec = {
    enable = mkEnableOption "nebula CrowdSec";

    name = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Machine name when registering with the CrowdSec API. Defaults to hostname.";
    };

    user = mkOption {
      type = types.str;
      default = "crowdsec";
      description = "User to run the CrowdSec service as.";
    };

    group = mkOption {
      type = types.str;
      default = "crowdsec";
      description = "Group to run the CrowdSec service as.";
    };

    autoUpdate = mkOption {
      type = types.bool;
      default = true;
      description = "Enable daily hub updates via cscli.";
    };

    hub = {
      collections = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Hub collections to install (e.g. crowdsecurity/linux).";
      };
      parsers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Hub parsers to install.";
      };
      scenarios = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Hub scenarios to install.";
      };
    };

    acquisitions = mkOption {
      type = types.listOf acquisition.type;
      default = [];
      description = "Log sources to monitor.";
    };

    capiCredentialsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to CAPI credentials file (online_api_credentials.yaml).";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.crowdsec-bootstrap = let
      rawExecStart = config.systemd.services.crowdsec.serviceConfig.ExecStart;
      execStart =
        if lib.isList rawExecStart
        then lib.last (lib.filter (s: s != "" && s != " ") rawExecStart)
        else rawExecStart;
      configMatch = builtins.match ".* -c ([^ ]+).*" execStart;
      configFile =
        if configMatch != null
        then builtins.head configMatch
        else throw "nebula: could not extract CrowdSec config path from ExecStart: ${execStart}";
    in {
      description = "Bootstrap CrowdSec local API credentials";
      before = ["crowdsec.service"];
      wantedBy = ["crowdsec.service"];
      unitConfig.ConditionPathExists = "!/var/lib/crowdsec/local_api_credentials.yaml";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        StateDirectory = "crowdsec";
        ExecStart = "${config.services.crowdsec.package}/bin/cscli -c ${configFile} machines add --auto --file /var/lib/crowdsec/local_api_credentials.yaml";
      };
    };

    services.crowdsec =
      {
        enable = true;
        autoUpdateService = mkDefault cfg.autoUpdate;
        hub = {
          collections = mkDefault cfg.hub.collections;
          parsers = mkDefault cfg.hub.parsers;
          scenarios = mkDefault cfg.hub.scenarios;
        };
        localConfig.acquisitions = map acquisition.mk cfg.acquisitions;
      }
      // lib.optionalAttrs (cfg.name != null) {name = mkDefault cfg.name;}
      // {
        user = mkDefault cfg.user;
        group = mkDefault cfg.group;
      }
      // {
        settings.lapi.credentialsFile = mkDefault "/var/lib/crowdsec/local_api_credentials.yaml";
        settings.general.api.server.enable = true;
      }
      // lib.optionalAttrs (cfg.capiCredentialsFile != null) {
        settings.capi.credentialsFile = cfg.capiCredentialsFile;
      };
  };
}
