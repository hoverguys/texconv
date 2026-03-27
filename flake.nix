{
  inputs = {
    nixpkgs.url = "nixpkgs";
    zig.url = "github:silversquirl/zig-flake";
    zig.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      zig,
      ...
    }:
    let
      forAllSystems =
        f:
        builtins.mapAttrs (system: pkgs: f pkgs zig.packages.${system}.zig_0_15_1) nixpkgs.legacyPackages;
    in
    {
      devShells = forAllSystems (
        pkgs: zig: {
          default = pkgs.mkShellNoCC {
            packages = [
              zig
              zig.zls
            ];
          };
        }
      );

      packages = forAllSystems (
        pkgs: zig: {
          default = zig.makePackage {
            pname = "texconv";
            version = "0.1.0";
            src = ./.;
            zigReleaseMode = "fast";
            # depsHash = "<replace this with the hash Nix provides in its error message>"
          };
        }
      );
    };
}
