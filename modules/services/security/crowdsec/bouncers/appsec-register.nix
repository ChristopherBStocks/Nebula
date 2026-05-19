{
  cfg,
  cscli,
  pkgs,
}: {
  description = "Register CrowdSec AppSec bouncer";
  after = ["crowdsec.service"];
  requires = ["crowdsec.service"];
  wantedBy = ["crowdsec.service"];
  unitConfig.ConditionPathExists = "!/var/lib/crowdsec/appsec-bouncer.key";
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    User = cfg.user;
    Group = cfg.group;
    StateDirectory = "crowdsec";
    ExecStart = pkgs.writeShellScript "crowdsec-appsec-bouncer-register" ''
      ${cscli} bouncers delete ${cfg.bouncers.appsec.bouncerName} 2>/dev/null || true
      key=$(${pkgs.openssl}/bin/openssl rand -hex 32)
      ${cscli} bouncers add ${cfg.bouncers.appsec.bouncerName} --key "$key"
      printf '%s' "$key" > /var/lib/crowdsec/appsec-bouncer.key
      chmod 640 /var/lib/crowdsec/appsec-bouncer.key
    '';
  };
}
