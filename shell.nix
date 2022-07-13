{ pkgs ? import <nixpkgs> {}, ... }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    nix
    home-manager
    git
  ];
}
