{
  username,
  description ? username,
  hashedPasswordFile ? null,
  uid ? null,
  home ? "/home/${username}",
  shell ? null,
  authorizedKeys ? [],
  extraGroups ? [],
  passwordlessSudo ? false,
}: {lib, ...}: {
  users = {
    users.${username} =
      {
        isNormalUser = true;
        group = username;
        inherit description home;
        openssh.authorizedKeys.keys = authorizedKeys;
        inherit extraGroups;
      }
      // lib.optionalAttrs (hashedPasswordFile != null) {inherit hashedPasswordFile;}
      // lib.optionalAttrs (uid != null) {inherit uid;}
      // lib.optionalAttrs (shell != null) {inherit shell;};

    groups.${username} = lib.optionalAttrs (uid != null) {gid = uid;};
  };

  security.sudo.extraRules = lib.mkIf passwordlessSudo [
    {
      users = [username];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
