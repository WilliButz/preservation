{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = inputs: {
    packages.x86_64-linux =
      let
        pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
      in
      {
        optionsManualMD =
          let
            eval = pkgs.lib.evalModules {
              modules = [
                ../options.nix
                (args: {
                  options._module.args = args.lib.mkOption { internal = true; };
                })
              ];
            };
            optionsDoc = pkgs.nixosOptionsDoc {
              inherit (eval) options;
              transformOptions =
                o:
                o
                // {
                  declarations = map (
                    declaration:
                    let
                      flakeOutPath = inputs.self.sourceInfo.outPath;
                      name = pkgs.lib.removePrefix "${flakeOutPath}/" declaration;
                    in
                    if pkgs.lib.hasPrefix "${flakeOutPath}/" declaration then
                      {
                        inherit name;
                        url = "https://github.com/willibutz/preservation/blob/main/${name}";
                      }
                    else
                      declaration
                  ) o.declarations;
                };
            };
          in
          optionsDoc.optionsCommonMark;

        docs = pkgs.stdenv.mkDerivation {
          name = "preservation-docs";
          src = pkgs.lib.cleanSource ../.;
          nativeBuildInputs = [ pkgs.mdbook ];
          patchPhase = ''
            cat ${inputs.self.packages.x86_64-linux.optionsManualMD} > docs/src/configuration-options.md
          '';
          buildPhase = ''
            cd docs
            mdbook build
          '';
          installPhase = "cp -vr book $out";
        };
      };
  };
}
