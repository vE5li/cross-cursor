{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = {nixpkgs, ...}: let
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    for-all-systems = function: nixpkgs.lib.genAttrs systems (system: function nixpkgs.legacyPackages.${system});
  in {
    formatter = for-all-systems (pkgs: pkgs.alejandra);

    devShells = for-all-systems (pkgs: {
      default = pkgs.callPackage ./default.nix {};
    });

    packages = for-all-systems (pkgs: rec {
      default = cross-cursor;
      cross-cursor = pkgs.callPackage ./default.nix {};
    });
  };
}
