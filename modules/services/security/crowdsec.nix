{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.services.crowdsec;
  acquisition = import ./crowdsec/acquisitions {inherit lib;};
  bootstrap = import ./crowdsec/bootstrap.nix;
  capiRegister = import ./crowdsec/capi-register.nix;
  consoleEnroll = import ./crowdsec/console-enroll.nix;
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

    capi = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Register with CrowdSec Central API for threat intel sharing. Disabling also disables console enrollment.";
      };

      consoleEnrollKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing the CrowdSec Console enrollment key.";
      };
    };
  };

  config = mkIf cfg.enable (let
    rawExecStart = config.systemd.services.crowdsec.serviceConfig.ExecStart;
    execStart =
      if lib.isList rawExecStart
      then lib.last (lib.filter (s: s != "" && s != " ") rawExecStart)
      else rawExecStart;
    configMatch = builtins.match ".* -c ([^ ]+).*" execStart;
    cscliConfigFile =
      if configMatch != null
      then builtins.head configMatch
      else throw "nebula: could not extract CrowdSec config path from ExecStart: ${execStart}";
    cscli = "${config.services.crowdsec.package}/bin/cscli -c ${cscliConfigFile}";
    capiCredentialsPath = "/var/lib/crowdsec/online_api_credentials.yaml";
  in {
    systemd.services = {
      crowdsec.serviceConfig = {
        SupplementaryGroups = ["systemd-journal"];
        PrivateUsers = lib.mkForce false;
      };
      crowdsec-bootstrap = bootstrap {inherit cfg cscli;};
      crowdsec-capi-register =
        mkIf cfg.capi.enable
        (capiRegister {inherit cfg cscli capiCredentialsPath;});
      crowdsec-console-enroll =
        mkIf (cfg.capi.enable && cfg.capi.consoleEnrollKeyFile != null)
        (consoleEnroll {inherit cfg cscli pkgs;});
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
        user = mkDefault cfg.user;
        group = mkDefault cfg.group;
        settings = {
          lapi.credentialsFile = mkDefault "/var/lib/crowdsec/local_api_credentials.yaml";
          capi.credentialsFile = capiCredentialsPath;
          general = {
            api.server.enable = true;
            api.server.console_path = "/var/lib/crowdsec/console.yaml";
          };
        };
      }
      // lib.optionalAttrs (cfg.name != null) {name = mkDefault cfg.name;};
  });
}
