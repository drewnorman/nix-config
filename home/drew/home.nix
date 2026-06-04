{ config, inputs, pkgs, ... }:

let
  airpodsConnect = pkgs.writeShellScriptBin "airpods-connect" ''
    ${pkgs.libnotify}/bin/notify-send -t 3000 "Connecting AirPods Pro 3..."
    ${pkgs.bluez}/bin/bluetoothctl power on && ${pkgs.bluez}/bin/bluetoothctl connect 30:0E:43:42:AF:53 && \
      ${pkgs.libnotify}/bin/notify-send -t 3000 "AirPods Pro 3 connected." || \
      ${pkgs.libnotify}/bin/notify-send -t 3000 "AirPods Pro 3 failed to connect."
  '';

  airpodsDisconnect = pkgs.writeShellScriptBin "airpods-disconnect" ''
    ${pkgs.libnotify}/bin/notify-send -t 3000 "Disconnecting AirPods Pro 3..."
    ${pkgs.bluez}/bin/bluetoothctl disconnect 30:0E:43:42:AF:53 && \
      ${pkgs.libnotify}/bin/notify-send -t 3000 "AirPods Pro 3 disconnected." || \
      ${pkgs.libnotify}/bin/notify-send -t 3000 "AirPods Pro 3 failed to disconnect."
  '';

  lockScreen = pkgs.writeShellScriptBin "lock-screen" ''
    ${pkgs.swaylock-effects}/bin/swaylock \
      --screenshots \
      --clock \
      --indicator \
      --indicator-radius 100 \
      --indicator-thickness 7 \
      --effect-blur 7x5 \
      --effect-vignette 0.5:0.5 \
      --ring-color bb00cc \
      --key-hl-color 880033 \
      --line-color 00000000 \
      --inside-color 00000088 \
      --separator-color 00000000 \
      --grace 2 \
      --fade-in 0.2
  '';

  toggleCapsEscape = pkgs.writeShellScriptBin "toggle-caps-escape" ''
    state_file="/tmp/caps-escape-swap"

    if [ -f "$state_file" ]; then
      ${pkgs.sway}/bin/swaymsg 'input type:keyboard xkb_options ""'
      rm "$state_file"
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Caps/Escape swap disabled."
    else
      ${pkgs.sway}/bin/swaymsg 'input type:keyboard xkb_options caps:swapescape'
      touch "$state_file"
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Caps/Escape swap enabled."
    fi
  '';

in

{
  imports = [
    ./modules/neovim.nix
  ];

  home = {
    username = "drew";
    homeDirectory = "/home/drew";
    stateVersion = "25.11";
    packages = with pkgs; [
      airpodsConnect
      airpodsDisconnect
      bat
      bitwarden-cli
      calibre
      claude-code
      codex
      eza
      fd
      filezilla
      foliate
      fzf
      gh
      jq
      lazygit
      lockScreen
      nodejs
      notmuch
      ripgrep
      pandoc
      php
      phpPackages.composer
      taskwarrior3
      toggleCapsEscape
      yarn
      yazi
      zoxide
      imv
    ];

    persistence."/persist" = {
      directories = [
        ".cache/nix"
        ".cargo"
        ".claude"
        ".codex"
        ".config/Bitwarden CLI"
        ".config/calibre"
        ".config/configstore"
        ".config/filezilla"
        ".config/gcloud"
        ".config/gh"
        ".config/google-chrome"
        ".config/lazygit"
        ".config/pulse"
        ".gnupg"
        ".local/share/Bitwarden CLI"
        ".local/share/calibre"
        ".local/share/containers"
        ".local/share/gnupg"
        ".local/share/direnv"
        ".local/share/fish"
        ".local/share/password-store"
        ".local/share/zoxide"
        ".local/state"
        ".mozilla"
        ".npm"
        ".password-store"
        ".sbw"
        ".ssh"
        ".wallpapers"
        "documents"
        "downloads"
        "pictures"
        "code"
      ];
      files = [
        ".bash_history"
        ".boto"
        ".claude.json"
        ".config/fish/local.fish"
        ".gitconfig.local"
        ".mbsyncrc"
        ".node_repl_history"
        ".notmuch-config"
        ".npmrc"
        ".pam-gnupg"
        ".python_history"
        ".wget-hsts"
        ".yarnrc"
        ".z"
      ];
    };
  };

  home.file.".gitignore".text = ''
    .rgignore
    /.config/nvim/.nvimlog
    /.cache
    /.local/share/containers
    /.local/share/docker
    /bin
    /docker
    /downloads
    /pictures
    /target
    /notes
    /.zshrc.local

    # AI tooling
    **/AGENTS.md
    **/.claude/settings.local.json
    /.codex
  '';

  programs.home-manager.enable = true;

  programs.alacritty = {
    enable = true;
    settings = {
      colors = {
        draw_bold_text_with_bright_colors = true;
        bright = {
          black = "#1c1c1c";
          blue = "#005f87";
          cyan = "#00afaf";
          green = "#5f8700";
          magenta = "#8700af";
          red = "#d70000";
          white = "#ffffff";
          yellow = "#d75f00";
        };
        cursor = {
          cursor = "#1c1c1c";
          text = "#ffffff";
        };
        normal = {
          black = "#1c1c1c";
          blue = "#005faf";
          cyan = "#0087af";
          green = "#008700";
          magenta = "#d70087";
          red = "#af0000";
          white = "#ffffff";
          yellow = "#d75f00";
        };
        primary = {
          background = "#ffffff";
          foreground = "#1c1c1c";
        };
        selection = {
          background = "#1c1c1c";
          text = "#ffffff";
        };
      };
      font = {
        size = 11;
        bold = {
          family = "Inconsolata Medium";
          style = "Bold";
        };
        bold_italic = {
          family = "Inconsolata Medium";
          style = "Bold Italic";
        };
        italic = {
          family = "Inconsolata Medium";
          style = "Italic";
        };
        normal = {
          family = "Inconsolata Medium";
          style = "Regular";
        };
      };
      window.decorations = "none";
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      core = {
        editor = "nvim";
        excludesFile = "~/.gitignore";
      };
      credential.helper = "cache";
      include.path = "~/.gitconfig.local";
      includeIf."gitdir:~/code/foxfuel/".path = "~/code/foxfuel/.gitconfig";
      init.defaultBranch = "master";
      merge.tool = "vimdiff";
      mergetool."vimdiff".path = "nvim";
      pull.rebase = true;
      user = {
        name = "Drew Norman";
        email = "drewnorman739@gmail.com";
        useConfigOnly = true;
      };
    };
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      e = "nvim";
      ls = "eza";
      lsa = "eza -la";
      q = "exit";
    };
    interactiveShellInit = ''
      set -x GPG_TTY (tty)

      if test -f $__fish_config_dir/local.fish
        source $__fish_config_dir/local.fish
      end

      if test -z "$TMUX"
        tmux new-session -A -s main
      end
    '';
  };

  programs.starship.enable = true;

  programs.tmux = {
    enable = true;
    extraConfig = builtins.replaceStrings
      [ "/usr/bin/fish" ]
      [ "${pkgs.fish}/bin/fish" ]
      (builtins.readFile ./config/tmux/tmux.conf);
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.bat = {
    enable = true;
    config.theme = "base16";
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.gh.enable = true;

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.lazygit.enable = true;

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "yy";
  };

  xdg = {
    enable = true;
    configFile = {
      "gammastep/config.ini".source = ./config/gammastep/config.ini;
      "htop/htoprc".source = ./config/htop/htoprc;
      "mako/config".source = ./config/mako/config;
      "sway/config".source = ./config/sway/config;
      "sway/config.local".source = ./config/sway/config.local;
      "waybar/config".source = ./config/waybar/config;
      "waybar/style.css".source = ./config/waybar/style.css;
      "wofi/config".source = ./config/wofi/config;
      "wofi/style.css".source = ./config/wofi/style.css;
      "yazi/keymap.toml".source = ./config/yazi/keymap.toml;
      "yazi/theme.toml".source = ./config/yazi/theme.toml;
      "yazi/yazi.toml".source = ./config/yazi/yazi.toml;
    };
    dataFile."wallpapers/white.jpg".source = ./assets/wallpapers/white.jpg;
    mimeApps = {
      enable = true;
      associations.added = {
        "application/x-extension-htm" = [ "firefox.desktop" ];
        "application/x-extension-html" = [ "firefox.desktop" ];
        "application/x-extension-shtml" = [ "firefox.desktop" ];
        "application/x-extension-xht" = [ "firefox.desktop" ];
        "application/x-extension-xhtml" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        "text/csv" = [ "firefox.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "x-scheme-handler/chrome" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
      };
      defaultApplications = {
        "application/x-extension-htm" = [ "firefox.desktop" ];
        "application/x-extension-html" = [ "firefox.desktop" ];
        "application/x-extension-shtml" = [ "firefox.desktop" ];
        "application/x-extension-xht" = [ "firefox.desktop" ];
        "application/x-extension-xhtml" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "x-scheme-handler/chrome" = [ "firefox.desktop" ];
        "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
      };
    };
  };
}
