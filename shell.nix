{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [ (pkgs.callPackage ./package.nix {}) ];
}
