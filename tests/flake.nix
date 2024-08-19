{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    # depends on https://github.com/NixOS/nixpkgs/pull/307528 (merged)
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake
      { inherit inputs; }
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem = { pkgs, ... }:
          {
            checks = {
              default = pkgs.nixosTest (import ./basic.nix pkgs);
            };
          };
      };
}
