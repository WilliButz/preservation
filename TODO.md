* add support for tmpfiles' modifiers?
* maybe add some recommended config that users can opt-in to use in addition
  to preservation?
* with the recent upstream changes the handling of /etc/machine-id changed.
  That requires another change upstream, i.e. the file needs to be created with content
  `uninitialized\n` and on a setup with preservation something like the following needs
  to be done to properly preserve the machine-id across reboots.
  ```nix
  {
    preservation.preserveAt."/state".files = [
      { file = "/etc/machine-id"; inInitrd = true; how = "symlink"; }
    ];

    systemd.services.systemd-machine-id-commit = {
      unitConfig.ConditionPathIsMountPoint = [
        "" "/state/etc/machine-id"
      ];
      serviceConfig.ExecStart = [
        "" "systemd-machine-id-setup --commit --root /state"
      ];
    };
  }
  ```
  see https://github.com/NixOS/nixpkgs/pull/351151#issuecomment-2440122776
