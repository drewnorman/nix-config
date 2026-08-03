{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.codex-desktop-linux.homeManagerModules.default
  ];

  programs.codexDesktopLinux = {
    enable = true;
    cliPackage = pkgs.codex;
  };

  home.persistence."/persist".directories = [
    ".config/codex-desktop"
  ];
}
