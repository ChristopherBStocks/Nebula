{
  cfg,
  cscli,
  capiCredentialsPath,
}: {
  description = "Register CrowdSec with Central API";
  after = ["crowdsec.service" "network-online.target"];
  wants = ["network-online.target"];
  wantedBy = ["multi-user.target"];
  unitConfig.ConditionPathExists = "!/var/lib/crowdsec/online_api_credentials.yaml";
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    User = cfg.user;
    ExecStart = "${cscli} capi register --file ${capiCredentialsPath}";
  };
}
