{
  cfg,
  cscli,
  pkgs,
}: {
  description = "Enroll CrowdSec instance in the CrowdSec Console";
  after = ["crowdsec.service" "network-online.target"];
  wants = ["network-online.target"];
  wantedBy = ["multi-user.target"];
  unitConfig.ConditionPathExists = "!/var/lib/crowdsec/.console-enrolled";
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    User = cfg.user;
    ExecStart = pkgs.writeShellScript "crowdsec-console-enroll" ''
      ${cscli} console enroll "$(< ${cfg.capi.consoleEnrollKeyFile})"
    '';
    ExecStartPost = "${pkgs.coreutils}/bin/touch /var/lib/crowdsec/.console-enrolled";
  };
}
