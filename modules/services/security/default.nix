{ inputs, ... }: {
  flake.nixosModules.fail2ban = ./fail2ban.nix;
  flake.nixosModules.crowdsec = {pkgs, ...}: {
    imports = [./crowdsec.nix];
    _module.args.pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.${pkgs.system};
  };
  flake.nixosModules.auditd = ./auditd.nix;
  flake.nixosModules.rsyslog = ./rsyslog.nix;
}
