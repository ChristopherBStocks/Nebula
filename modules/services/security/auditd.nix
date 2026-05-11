{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.nebula.services.auditd;
in {
  options.nebula.services.auditd = {
    enable = mkEnableOption "nebula auditd";

    rules = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["-a exit,always -F arch=b64 -S execve"];
      description = "Audit rules to load. See auditctl(8) for syntax.";
    };

    syslogPlugin = mkOption {
      type = types.bool;
      default = true;
      description = "Forward audit events to syslog/journald via audisp-syslog. Required for journalctl-based log acquisition.";
    };
  };

  config = mkIf cfg.enable {
    security.auditd = {
      enable = true;
      plugins.syslog.active = lib.mkIf cfg.syslogPlugin true;
    };
    security.audit = {
      enable = true;
      inherit (cfg) rules;
    };
  };
}
