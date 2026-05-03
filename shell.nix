{ pkgs ? import <nixpkgs> { }, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    git
    home-manager
    nix
    nixpkgs-fmt
  ];
}
