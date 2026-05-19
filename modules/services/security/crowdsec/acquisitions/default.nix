{lib}: let
  inherit (lib) mkOption types;

  type = types.submodule {
    options = {
      source = mkOption {
        type = types.enum ["journalctl" "file" "docker" "syslog" "kinesis" "cloudwatch" "appsec"];
        description = "Log source type.";
      };
      labels = mkOption {
        type = types.attrsOf types.str;
        description = "Labels to apply to acquired logs (e.g. { type = \"syslog\"; }).";
      };
      journalctlFilter = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Journalctl filter expressions. Used when source is journalctl.";
      };
      filenames = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "File paths to monitor. Used when source is file.";
      };
      listenAddr = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Address to listen on. Used when source is appsec (e.g. \"127.0.0.1:7422\").";
      };
      appsecConfig = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "AppSec ruleset to load. Used when source is appsec (e.g. \"crowdsecurity/virtual-patching\").";
      };
    };
  };

  mk = a:
    {
      inherit (a) source labels;
    }
    // lib.optionalAttrs (a.journalctlFilter != []) {journalctl_filter = a.journalctlFilter;}
    // lib.optionalAttrs (a.filenames != []) {inherit (a) filenames;}
    // lib.optionalAttrs (a.listenAddr != null) {listen_addr = a.listenAddr;}
    // lib.optionalAttrs (a.appsecConfig != null) {appsec_config = a.appsecConfig;};
in {inherit type mk;}
