{ pkgs, ... }:

{
  home = {
    username = "drew";
    homeDirectory = "/home/drew";
    stateVersion = "25.11";
    packages = with pkgs; [
      bat
      eza
      fd
      jq
      lazygit
      zoxide
    ];
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Drew Norman";
    userEmail = "drewnorman739@gmail.com";
    extraConfig = {
      init.defaultBranch = "master";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      e = "nvim";
      ls = "eza";
      lsa = "eza -la";
      q = "exit";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
