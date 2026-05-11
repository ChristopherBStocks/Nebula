{
  cfg,
  cscli,
}: {
  description = "Bootstrap CrowdSec local API credentials";
  before = ["crowdsec.service"];
  wantedBy = ["crowdsec.service"];
  unitConfig.ConditionPathExists = "!/var/lib/crowdsec/local_api_credentials.yaml";
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    User = cfg.user;
    StateDirectory = "crowdsec";
    ExecStart = "${cscli} machines add --auto --file /var/lib/crowdsec/local_api_credentials.yaml";
  };
}
