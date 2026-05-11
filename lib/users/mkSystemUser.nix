{
  username,
  description ? username,
  uid ? null,
  home ? null,
  createHome ? home != null,
  shell ? null,
  extraGroups ? [],
}: {lib, ...}: {
  users = {
    users.${username} =
      {
        isSystemUser = true;
        group = username;
        inherit description extraGroups createHome;
      }
      // lib.optionalAttrs (shell != null) {inherit shell;}
      // lib.optionalAttrs (uid != null) {inherit uid;}
      // lib.optionalAttrs (home != null) {inherit home;};

    groups.${username} = lib.optionalAttrs (uid != null) {gid = uid;};
  };
}
