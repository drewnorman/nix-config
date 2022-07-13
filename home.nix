{ config, pkgs, inputs, ... }: {
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  programs.home-manager.enable = true;

  programs.alacritty.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.firefox.enable = true;

  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    aliases = {
      graph = "log --decorate --oneline --graph";
    };
    userName = "Drew Norman";
    userEmail = "drewnorman739@gmail.com";
    extraConfig = {
      init.defaultBranch = "master";
    };
    lfs = { enable = true; };
    ignores = [ ".direnv" "result" ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;
    shellAliases = {
      cat = "bat";
      q = "exit";
      e = "nvim";
      ls = "exa";
      lsa = "exa -la";
    };
    history = {
      size = 10000;
      path = "/persist/home/drew/.zsh_history";
    };
    plugins = [
      {
	name = "powerlevel10k";
	src = pkgs.zsh-powerlevel10k;
	file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
	name = "powerlevel10k-config";
	src = ./home/drew/p10k-config;
	file = "p10k.zsh";
      }
    ];
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "docker-compose" ];
      theme = "agnoster";
    };
    loginExtra = ''
      if [[ -z $DISPLAY && $TTY = /dev/tty1 ]]; then
        exec sway
      fi
    '';
  };

  wayland.windowManager.sway =
  let
    modifier = "Mod1";
  in
  {
    enable = true;
    config = {
      inherit modifier;
      input = {
        "type:keyboard" = {
	  xkb_options = "caps:swapescape";
	};
      };
      fonts = {
      	names = [ "Inconsolata" ]; size = 12.0;
      };
      gaps = {
        inner = 8;
	outer = 8;
      };
      terminal = "${pkgs.alacritty}/bin/alacritty";
    };
  };

  fonts.fontconfig.enable = true;

  home = {
    stateVersion = "22.05";

    username = "drew";
    homeDirectory = "/home/drew";

    persistence."/persist/home/drew" = {
      directories = [
	".dotfiles"
	".local/share/direnv"
	".local/share/zoxide"
	".cache/oh-my-zsh"
	".ssh"
	"downloads"
	"documents"
	"pictures"
	"videos"
      ];
      files = [
	".cache/p10k-dump-drew.zsh"
	".cache/p10k-dump-drew.zsh.zwc"
      ];
      allowOther = true;
    };

    packages = with pkgs; [
      bat
      bottom
      exa
      fd
      imv
      inconsolata
      jq
      lazygit
      light
      mpv
      ranger
      ripgrep
      pulseaudio
      sway
      swayidle
      swaylock-effects
      waybar
      wayland
      wl-clipboard
    ];

    sessionVariables = {
      MOZ_ENABLE_WAYLAND = true;
    };
  };

  systemd.user.startServices = "sd-switch";
}

