_: {
  flake.nixosModules.fail2ban = ./fail2ban.nix;
  flake.nixosModules.crowdsec = ./crowdsec.nix;
  flake.nixosModules.auditd = ./auditd.nix;
  flake.nixosModules.rsyslog = ./rsyslog.nix;
}
