{
  username,
  description ? username,
  uid ? null,
  home ? null,
  createHome ? home != null,
  shell ? null,
  extraGroups ? [],
}: {
  lib,
  pkgs,
  ...
}: {
  users = {
    users.${username} =
      {
        isSystemUser = true;
        group = username;
        inherit description extraGroups createHome;
        shell =
          if shell != null
          then shell
          else pkgs.shadow;
      }
      // lib.optionalAttrs (uid != null) {inherit uid;}
      // lib.optionalAttrs (home != null) {inherit home;};

    groups.${username} = lib.optionalAttrs (uid != null) {gid = uid;};
  };
}
