{
  pkgs ? import <nixpkgs> { },
  ...
}:

pkgs.mkShell {
  packages = with pkgs; [
    git
    home-manager
    nix
    nixfmt
  ];

  shellHook = ''
    git config core.hooksPath .githooks
  '';
}
