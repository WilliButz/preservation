# Preservation

Nix tooling to enable declarative management of non-volatile system state.

Inspired and heavily influenced by [impermanence](https://github.com/nix-community/impermanence) but not
meant to be a drop-in replacement.

## Work in Progress

🚧 still under construction 🚧

Check out [the test](tests/basic.nix) for a usage example 👀

Depends on https://github.com/NixOS/nixpkgs/pull/307528 (merged)

## How does it compare to impermanence

* Preservation does not attempt to be a very generic solution, it tries to fill a specific niche.
  Specifically Preservation does not support non-NixOS systems via home-manager, which is supported
  by impermanence.

* Preservation only creates static configuration for
  [systemd-tmpfiles](https://www.freedesktop.org/software/systemd/man/latest/systemd-tmpfiles.html)
  and systemd [mount units](https://www.freedesktop.org/software/systemd/man/latest/systemd.mount.html).
  This makes Preservation a potential candidate for state management on interpreter-less systems.

  Impermanence makes use of NixOS activation scripts and custom systemd services with bash (at the point
  of writing this), to create and configure files and directories.

* Preservation must be precisely configured, there is no [special runtime logic](https://github.com/nix-community/impermanence/blob/23c1f06316b67cb5dabdfe2973da3785cfe9c34a/mount-file.bash#L31-L42)
  in place. This means that the user must define:
  * when the preservation should be set up: either in the initrd, or after (the default)
  * how the preservation should be set up: either by symlink, or bindmount (the default)
  * whether or not parent directories of the persisted files require special permissions

* Preservation's configuration is based on, and very similar to that of impermanence.

* Preservation uses a global `enable` option, impermanence does not (see https://github.com/nix-community/impermanence/pull/171)

## Why?

This aims to provide a declarative state management solution for NixOS systems without resorting to
interpreters to do the heavy lifting. This should enable impermanence-like state management on
an "interpreter-less" system.

Related:
- https://github.com/NixOS/nixpkgs/issues/265640
- https://github.com/nix-community/projects/blob/main/proposals/nixpkgs-security-phase2.md#boot-chain-security

## License

This project is released under the terms of the MIT License. See [LICENSE](./LICENSE).
