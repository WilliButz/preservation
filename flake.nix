{
  outputs = inputs: {
    lib = import ./lib.nix; # need to pass '{ lib, ... }'
    nixosModules = {
      default = inputs.self.nixosModules.preservation;
      preservation = import ./module.nix;
    };
  };
}
