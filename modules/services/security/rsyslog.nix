{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.nebula.services.rsyslog;
in {
  options.nebula.services.rsyslog = {
    enable = mkEnableOption "nebula rsyslog";

    rules = mkOption {
      type = types.lines;
      default = "";
      example = '':programname, isequal, "sshd" /var/log/sshd.log'';
      description = "rsyslog filter rules appended to the configuration.";
    };
  };

  config = mkIf cfg.enable {
    services.journald.extraConfig = "ForwardToSyslog=yes";
    services.rsyslogd = {
      enable = true;
      extraConfig = ''
        $ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
        ${cfg.rules}
      '';
    };
  };
}
