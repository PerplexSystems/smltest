{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... } @ inputs:
    let
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);
    in
    {
      apps = forAllSystems (system: 
        let
          pkgs = nixpkgs.legacyPackages.${system};
          mlton = "${pkgs.mlton}/bin/mlton";
          mktemp = "${pkgs.coreutils}/bin/mktemp";
        in {
          test = {
            type = "app";
            program = toString (pkgs.writeShellScript "run-tests" ''
              output=$(${mktemp})
              ${mlton} -output $output tests/tests.mlb && $output
            '');
          };

          build = {
            type = "app";
            program = toString (pkgs.writeShellScript "build-program" ''
              output=$(${mktemp})
              ${mlton} -output $output smltest.mlb && echo "Successfully built!"
            '');
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [{
              packages = with pkgs; [ millet mlton mlkit smlfmt gnumake polyml gcc ];
            }];
          };
        });
    };
}
