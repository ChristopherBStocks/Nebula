{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
  cfg = config.nebula.services.openssh;
in {
  options.nebula.services.openssh = {
    enable = mkEnableOption "nebula OpenSSH";

    ports = mkOption {
      type = types.listOf types.port;
      default = [22];
      description = "Ports to listen on.";
    };

    permitRootLogin = mkOption {
      type = types.enum ["yes" "no" "prohibit-password" "forced-commands-only"];
      default = "no";
      description = "Whether and how root can log in via SSH.";
    };

    passwordAuthentication = mkOption {
      type = types.bool;
      default = false;
      description = "Allow password authentication.";
    };

    permitEmptyPasswords = mkOption {
      type = types.bool;
      default = false;
      description = "Allow login with empty passwords.";
    };

    allowedUsers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Users allowed to log in. Empty allows all.";
    };

    allowedGroups = mkOption {
      type = types.listOf types.str;
      default = ["wheel"];
      description = "Groups allowed to log in.";
    };

    maxAuthTries = mkOption {
      type = types.ints.positive;
      default = 3;
      description = "Maximum authentication attempts per connection.";
    };

    loginGraceTime = mkOption {
      type = types.str;
      default = "30s";
      description = "Time allowed for successful authentication.";
    };

    clientAliveCountMax = mkOption {
      type = types.ints.unsigned;
      default = 3;
      description = "Maximum unanswered keepalives before disconnecting.";
    };

    clientAliveInterval = mkOption {
      type = types.ints.unsigned;
      default = 60;
      description = "Seconds between keepalive messages.";
    };

    maxSessions = mkOption {
      type = types.ints.positive;
      default = 5;
      description = "Maximum concurrent sessions per connection.";
    };

    maxStartups = mkOption {
      type = types.str;
      default = "10:30:60";
      description = "Unauthenticated connection throttle (start:rate:full).";
    };

    allowTcpForwarding = mkOption {
      type = types.bool;
      default = false;
      description = "Allow TCP forwarding.";
    };

    allowAgentForwarding = mkOption {
      type = types.bool;
      default = false;
      description = "Allow SSH agent forwarding.";
    };

    x11Forwarding = mkOption {
      type = types.bool;
      default = false;
      description = "Allow X11 forwarding.";
    };

    printLastLog = mkOption {
      type = types.bool;
      default = true;
      description = "Print last login information on login.";
    };

    banner = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to banner file shown before authentication.";
    };

    logLevel = mkOption {
      type = types.enum ["QUIET" "FATAL" "ERROR" "INFO" "VERBOSE" "DEBUG" "DEBUG1" "DEBUG2" "DEBUG3"];
      default = "VERBOSE";
      description = "Logging verbosity level.";
    };

    strictModes = mkOption {
      type = types.bool;
      default = true;
      description = "Check file permissions on authorized_keys and home directory before login.";
    };

    hostbasedAuthentication = mkOption {
      type = types.bool;
      default = false;
      description = "Allow host-based authentication.";
    };

  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = mkDefault cfg.ports;
      settings =
        {
          PermitRootLogin = mkDefault cfg.permitRootLogin;
          PasswordAuthentication = mkDefault cfg.passwordAuthentication;
          PermitEmptyPasswords = mkDefault cfg.permitEmptyPasswords;
          MaxAuthTries = mkDefault cfg.maxAuthTries;
          LoginGraceTime = mkDefault cfg.loginGraceTime;
          ClientAliveCountMax = mkDefault cfg.clientAliveCountMax;
          ClientAliveInterval = mkDefault cfg.clientAliveInterval;
          MaxSessions = mkDefault cfg.maxSessions;
          MaxStartups = mkDefault cfg.maxStartups;
          AllowTcpForwarding = mkDefault (if cfg.allowTcpForwarding then "yes" else "no");
          AllowAgentForwarding = mkDefault cfg.allowAgentForwarding;
          X11Forwarding = mkDefault cfg.x11Forwarding;
          PrintLastLog = mkDefault cfg.printLastLog;
          LogLevel = mkDefault cfg.logLevel;
          StrictModes = mkDefault cfg.strictModes;
          HostbasedAuthentication = mkDefault cfg.hostbasedAuthentication;
        }
        // lib.optionalAttrs (cfg.allowedUsers != []) {
          AllowUsers = mkDefault cfg.allowedUsers;
        }
        // lib.optionalAttrs (cfg.allowedGroups != []) {
          AllowGroups = mkDefault cfg.allowedGroups;
        }
        // lib.optionalAttrs (cfg.banner != null) {
          Banner = mkDefault cfg.banner;
        };
    };
  };
}
