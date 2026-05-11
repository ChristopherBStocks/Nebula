{lib}: let
  inherit (lib) mkOption types;

  type = types.submodule {
    options = {
      source = mkOption {
        type = types.enum ["journalctl" "file" "docker" "syslog" "kinesis" "cloudwatch"];
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
    };
  };

  mk = a:
    {
      inherit (a) source labels;
    }
    // lib.optionalAttrs (a.journalctlFilter != []) {journalctl_filter = a.journalctlFilter;}
    // lib.optionalAttrs (a.filenames != []) {inherit (a) filenames;};
in {inherit type mk;}
