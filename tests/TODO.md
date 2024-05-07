* `systemd-tmpfiles-setup.service` is pulled in by `sysinit.target` in initrd
  via `upstreamWants`. This does not really make sense, when tmpfiles is
  ordered after `initrd-fs.target` to operate on the `/sysroot` hierarchy
* currently this is designed to work from first boot, still needs some testing
  to see if this behaves correctly when enabled on an existing/running system
* when defining a file/directory like `/long/path/that/does/not/exist/foobar`,
  then only `foobar` will have the configured ownership and permissions,
  while the rest is created by tmpfiles with root:root 0755 by default.
  tmpfiles prints a warning when this happens:
  > Detected unsafe path transition /home/butz (owned by butz) → /home/butz/.config (owned by root) during canonicalization of home/butz/.config.
  probably fine, but better to have this mentioned somewhere
* add support for tmpfiles' modifiers?
