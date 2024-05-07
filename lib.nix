{ lib, ... }:

rec {
  # converts a list of `mountOption` to a comma-separated string that is passed to the mount unit
  toOptionsString = mountOptions:
    builtins.concatStringsSep "," (map
      (option:
        if option.value == null then option.name else "${option.name}=${option.value}"
      )
      mountOptions);

  # concatenates two paths
  # inserts a "/" in between if there is none, removes one if there are two
  concatTwoPaths = parent: child: with lib.strings;
    if hasSuffix "/" parent
    then
      if hasPrefix "/" child
      # "/parent/" "/child"
      then parent + (removePrefix "/" child)
      # "/parent/" "child"
      else parent + child
    else
      if hasPrefix "/" child
      # "/parent" "/child"
      then parent + child
      # "/parent" "child"
      else parent + "/" + child;

  # concatenates a list of paths using `concatTwoPaths`
  concatPaths = builtins.foldl' concatTwoPaths "";

  # retrieves all directories configured in a `preserveAtSubmodule`
  getAllDirectories = stateConfig: stateConfig.directories
    ++ (builtins.concatLists (getUserDirectories stateConfig.users));
  # retrieves all files configured in a `preserveAtSubmodule`
  getAllFiles = stateConfig: stateConfig.files
    ++ (builtins.concatLists (getUserFiles stateConfig.users));
  # retrieves the list of directories for all users in a `preserveAtSubmodule`
  getUserDirectories = lib.mapAttrsToList (_: userConfig: userConfig.directories);
  # retrieves the list of files for all users in a `preserveAtSubmodule`
  getUserFiles = lib.mapAttrsToList (_: userConfig: userConfig.files);
  # filters a list of files or directories, returns only bindmounts
  onlyBindMounts = forInitrd: builtins.filter (conf: conf.how == "bindmount" && conf.inInitrd == forInitrd);
  # filters a list of files or directories, returns only symlinks
  onlySymLinks = forInitrd: builtins.filter (conf: conf.how == "symlink" && conf.inInitrd == forInitrd);

  # creates tmpfiles.d rules for the `settings` option of the tmpfiles module from a `preserveAtSubmodule`
  mkTmpfilesRules = forInitrd: preserveAt: stateConfig:
    let
      allDirectories = getAllDirectories stateConfig;
      allFiles = getAllFiles stateConfig;
      mountedDirectories = onlyBindMounts forInitrd allDirectories;
      mountedFiles = onlyBindMounts forInitrd allFiles;
      symlinkedDirectories = onlySymLinks forInitrd allDirectories;
      symlinkedFiles = onlySymLinks forInitrd allFiles;

      prefix = if forInitrd then "/sysroot" else "/";

      mountedDirRules = map
        (dirConfig: {
          # directory on persistent storage
          "${concatPaths [ prefix stateConfig.persistentStoragePath dirConfig.directory ]}".d =
            { inherit (dirConfig) user group mode; };
          # directory on volatile storage
          "${concatPaths [ prefix dirConfig.directory ]}".d =
            { inherit (dirConfig) user group mode; };
        })
        mountedDirectories;

      mountedFileRules = map
        (fileConfig: {
          # file on persistent storage
          "${concatPaths [ prefix stateConfig.persistentStoragePath fileConfig.file ]}".f =
            { inherit (fileConfig) user group mode; };
          # file on volatile storage
          "${concatPaths [ prefix fileConfig.file ]}".f =
            { inherit (fileConfig) user group mode; };
        })
        mountedFiles;

      symlinkedDirRules = map
        (dirConfig: {
          # directory on persistent storage
          "${concatPaths [ prefix stateConfig.persistentStoragePath dirConfig.directory ]}".d =
            { inherit (dirConfig) user group mode; };
          # symlink on volatile storage
          "${concatPaths [ prefix dirConfig.directory ]}".L =
            {
              inherit (dirConfig) user group mode;
              argument = concatPaths [ stateConfig.persistentStoragePath dirConfig.directory ];
            };
        })
        symlinkedDirectories;

      symlinkedFileRules = map
        (fileConfig: {
          # file on persistent storage
          "${concatPaths [ prefix stateConfig.persistentStoragePath fileConfig.file ]}".f =
            { inherit (fileConfig) user group mode; };
          # symlink on volatile storage
          "${concatPaths [ prefix fileConfig.file ]}".L =
            {
              inherit (fileConfig) user group mode;
              argument = concatPaths [ stateConfig.persistentStoragePath fileConfig.file ];
            };
        })
        symlinkedFiles;

      rules = mountedDirRules ++ symlinkedDirRules ++ mountedFileRules ++ symlinkedFileRules;
    in
    rules;

  # creates systemd mount unit configurations from a `preserveAtSubmodule`
  mkMountUnits = forInitrd: preserveAt: stateConfig:
    let
      allDirectories = getAllDirectories stateConfig;
      allFiles = getAllFiles stateConfig;
      mountedDirectories = onlyBindMounts forInitrd allDirectories;
      mountedFiles = onlyBindMounts forInitrd allFiles;

      prefix = if forInitrd then "/sysroot" else "/";

      directoryMounts = map
        (directoryConfig: {
          options = toOptionsString (directoryConfig.mountOptions ++ (
            lib.optional forInitrd { name = "x-initrd.mount"; value = null; }
          ));
          where = concatPaths [
            prefix
            directoryConfig.directory
          ];
          what = concatPaths [
            prefix
            stateConfig.persistentStoragePath
            directoryConfig.directory
          ];
          unitConfig = {
            DefaultDependencies = "no";
            ConditionPathExists = concatPaths [
              prefix
              stateConfig.persistentStoragePath
              directoryConfig.directory
            ];
            ConditionPathIsDirectory = concatPaths [
              prefix
              stateConfig.persistentStoragePath
              directoryConfig.directory
            ];
          };
          conflicts = [ "unmount.target" ];
          after = [ "systemd-tmpfiles-setup.service" ];
          wantedBy =
            if forInitrd then [
              "initrd-preservation.target"
            ] else [
              "preservation.target"
            ];
          before =
            if forInitrd then [
              "initrd-preservation.target"
            ] else [
              "preservation.target"
            ];
        })
        mountedDirectories;

      fileMounts = map
        (fileConfig: {
          options = toOptionsString (fileConfig.mountOptions ++ (
            lib.optional forInitrd { name = "x-initrd.mount"; value = null; }
          ));
          where = concatPaths [
            prefix
            fileConfig.file
          ];
          what = concatPaths [
            prefix
            stateConfig.persistentStoragePath
            fileConfig.file
          ];
          unitConfig = {
            DefaultDependencies = "no";
            ConditionPathExists = concatPaths [
              prefix
              stateConfig.persistentStoragePath
              fileConfig.file
            ];
          };
          conflicts = [ "unmount.target" ];
          after = [ "systemd-tmpfiles-setup.service" ];
          wantedBy =
            if forInitrd then [
              "initrd-preservation.target"
            ] else [
              "preservation.target"
            ];
          before =
            if forInitrd then [
              "initrd-preservation.target"
            ] else [
              "preservation.target"
            ];
        })
        mountedFiles;

      mountUnits = directoryMounts ++ fileMounts;
    in
    mountUnits;

  # aliases to avoid the use of a nameless bool outside this lib
  mkRegularMountUnits = mkMountUnits false;
  mkInitrdMountUnits = mkMountUnits true;
  mkRegularTmpfilesRules = mkTmpfilesRules false;
  mkInitrdTmpfilesRules = mkTmpfilesRules true;
}
