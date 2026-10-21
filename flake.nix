{
  description = "Installable CodeGraph CLI and native extraction kernel";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      overlays.default = final: _prev: {
        codegraph-kernel = final.callPackage ./codegraph-kernel/package.nix { };
        codegraph = final.callPackage ./package.nix {
          codegraphKernel = final.codegraph-kernel;
        };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          codegraph-kernel = pkgs.callPackage ./codegraph-kernel/package.nix { };
          codegraph = pkgs.callPackage ./package.nix {
            codegraphKernel = self.packages.${system}.codegraph-kernel;
          };
          default = self.packages.${system}.codegraph;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];
            packages = [
              pkgs.nodejs_24
              pkgs.importNpmLock.hooks.linkNodeModulesHook
              pkgs.cargo
              pkgs.rustc
              pkgs.rustfmt
              pkgs.clippy
            ];
            npmDeps = pkgs.importNpmLock.buildNodeModules {
              npmRoot = ./.;
              nodejs = pkgs.nodejs_24;
            };
            env.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
          };
        }
      );

      checks = forAllSystems (system: {
        build = self.packages.${system}.default;
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
