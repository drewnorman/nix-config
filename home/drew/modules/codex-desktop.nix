{
  inputs,
  ...
}:

{
  imports = [
    inputs.codex-desktop-linux.homeManagerModules.default
  ];

  programs.codexDesktopLinux = {
    # Keep the app server paired with the desktop build for startup policy reads.
    enable = true;
  };

  home.persistence."/persist".directories = [
    ".config/codex-desktop"
  ];
}
