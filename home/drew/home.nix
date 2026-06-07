{
  config,
  inputs,
  pkgs,
  ...
}:

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

  waybarGammastepStatus = pkgs.writeShellScriptBin "waybar-gammastep-status" ''
    status="$(${pkgs.gammastep}/bin/gammastep -p -c "$HOME/.config/gammastep/config.ini" 2>&1 || true)"

    if systemctl --user is-active --quiet gammastep.service; then
      running="Running"
      class="unknown"
    else
      running="Stopped"
      class="stopped"
    fi

    period="$(printf '%s\n' "$status" | ${pkgs.gnused}/bin/sed -n 's/^.*Period:[[:space:]]*//p' | ${pkgs.coreutils}/bin/head -n1)"
    temperature="$(printf '%s\n' "$status" | ${pkgs.gnused}/bin/sed -n 's/^.*Color temperature:[[:space:]]*//p' | ${pkgs.coreutils}/bin/head -n1)"
    brightness="$(printf '%s\n' "$status" | ${pkgs.gnused}/bin/sed -n 's/^.*Brightness:[[:space:]]*//p' | ${pkgs.coreutils}/bin/head -n1)"

    [ -n "$period" ] || period="Unknown"
    [ -n "$temperature" ] || temperature="Unknown"
    [ -n "$brightness" ] || brightness="Unknown"

    if [ "$running" = "Running" ]; then
      case "$period" in
        Daytime) class="daytime" ;;
        Night) class="night" ;;
        Transition) class="transition" ;;
        *) class="unknown" ;;
      esac
    fi

    case "$class" in
      daytime) icon="󰖙" ;;
      night) icon="󰖔" ;;
      transition) icon="󰖚" ;;
      *) icon="󰔎" ;;
    esac

    tooltip="Gammastep: $running
Period: $period
Temperature: $temperature
Brightness: $brightness"

      ${pkgs.jq}/bin/jq -cn \
        --arg text "$icon" \
        --arg tooltip "$tooltip" \
        --arg class "$class" \
        '{text: $text, tooltip: $tooltip, class: $class}'
  '';

  waybarGammastepToggle = pkgs.writeShellScriptBin "waybar-gammastep-toggle" ''
    if systemctl --user is-active --quiet gammastep.service; then
      ${pkgs.libnotify}/bin/notify-send -t 5000 "Gammastep disabling..."
      systemctl --user stop gammastep.service
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Gammastep disabled."
    else
      ${pkgs.libnotify}/bin/notify-send -t 5000 "Gammastep enabling..."
      systemctl --user start gammastep.service
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Gammastep enabled."
    fi

    ${pkgs.coreutils}/bin/sleep 0.5
    ${pkgs.procps}/bin/pkill -RTMIN+1 waybar >/dev/null 2>&1 || true
  '';

  hiddenDesktopEntry = name: ''
    [Desktop Entry]
    Type=Application
    Name=${name}
    Hidden=true
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
      waybarGammastepStatus
      waybarGammastepToggle
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
        ".config/chromium"
        ".config/Bitwarden CLI"
        ".config/calibre"
        ".config/configstore"
        ".config/filezilla"
        ".config/gcloud"
        ".config/gh"
        ".config/lazygit"
        ".config/pulse"
        ".cache/chromium"
        ".cache/mozilla"
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

  home.file.".gnupg/scdaemon.conf".text = ''
    disable-ccid
  '';

  programs.home-manager.enable = true;

  programs.chromium.enable = true;

  home.pointerCursor = {
    enable = true;
    package = pkgs.vanilla-dmz;
    name = "DMZ-Black";
    size = 20;
    gtk.enable = true;
    x11.enable = true;
  };

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
    };
    interactiveShellInit = ''
      set -g fish_greeting
      set -x GPG_TTY (tty)

      bind tab accept-autosuggestion or complete

      if test -f $__fish_config_dir/local.fish
        source $__fish_config_dir/local.fish
      end

      if test -z "$TMUX"
        tmux new-session -A -s default
      end
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status\n$character";
      right_format = "$status$cmd_duration$jobs$direnv$aws$gcloud$kubernetes$docker_context$nix_shell$package$nodejs$python$rust$golang$time";

      character = {
        success_symbol = "[>](green)";
        error_symbol = "[>](red)";
        vimcmd_symbol = "[<](green)";
        vimcmd_replace_one_symbol = "[>](purple)";
        vimcmd_replace_symbol = "[>](purple)";
        vimcmd_visual_symbol = "[>](yellow)";
      };

      git_branch = {
        format = "on [$branch(:$remote_branch)]($style) ";
        style = "purple";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "red";
        conflicted = "~";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        stashed = "*";
        staged = "+";
        modified = "!";
        renamed = ">";
        deleted = "x";
        untracked = "?";
      };

      status = {
        disabled = false;
        format = "[$status]($style) ";
      };

      cmd_duration = {
        min_time = 3000;
        format = "took [$duration]($style) ";
      };

      time = {
        disabled = false;
        format = "at [$time]($style) ";
        time_format = "%T";
      };
    };
  };

  programs.tmux = {
    enable = true;
    extraConfig = builtins.replaceStrings [ "/usr/bin/fish" ] [ "${pkgs.fish}/bin/fish" ] (
      builtins.readFile ./config/tmux/tmux.conf
    );
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

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.lazygit.enable = true;

  programs.waybar = {
    enable = true;
    style = builtins.readFile ./config/waybar/style.css;
    settings = {
      mainBar = {
        height = 30;
        modules-left = [
          "sway/workspaces"
          "sway/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "custom/gammastep"
          "backlight"
          "network"
          "cpu"
          "memory"
          "temperature"
          "battery"
        ];

        "sway/window".max-length = 70;

        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format = "{:%a %b %d %H:%M:%S}";
          interval = 1;
        };

        cpu = {
          format = "󰻠";
          tooltip-format = "{usage}% CPU";
        };

        memory = {
          format = "󰍛";
          tooltip-format = "{percentage}% memory";
        };

        temperature = {
          critical-threshold = 80;
          format = "{icon}";
          format-icons = [
            "󰔏"
            "󱃂"
            "󰈸"
          ];
          tooltip-format = "{temperatureC}°C";
        };

        battery = {
          bat = "BAT0";
          adapter = "AC";
          bat-compatibility = true;
          interval = 30;
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}";
          format-charging = "󰂄";
          format-plugged = "󰚥";
          format-icons = [
            "󰁺"
            "󰁼"
            "󰁾"
            "󰂀"
            "󰁹"
          ];
          tooltip-format = "{capacity}%";
          tooltip-format-discharging = "{capacity}%\n{time} remaining";
          tooltip-format-charging = "{capacity}%\n{time} to full";
        };

        backlight = {
          device = "intel_backlight";
          format = "{icon}";
          format-icons = [
            "󰃞"
            "󰃟"
            "󰃠"
          ];
          scroll-step = 5;
          tooltip-format = "{percent}% brightness";
        };

        "custom/gammastep" = {
          exec = "${waybarGammastepStatus}/bin/waybar-gammastep-status";
          return-type = "json";
          format = "{}";
          interval = 10;
          on-click = "${waybarGammastepToggle}/bin/waybar-gammastep-toggle";
          signal = 1;
        };

        network = {
          interval = 30;
          format-wifi = "󰤨";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          format-ethernet = "󰈀";
          tooltip-format-ethernet = "{ifname}: {ipaddr}/{cidr}";
          format-linked = "(No IP) 󰈀";
          tooltip-format-linked = "{ifname} (No IP)";
          format-disconnected = "󰤭";
          tooltip-format-disconnected = "Disconnected";
        };

        pulseaudio = {
          format = "{icon}";
          format-bluetooth = "{icon}󰂯";
          format-bluetooth-muted = "󰖁 {icon}󰂯";
          format-muted = "󰖁 ";
          format-source = "󰍬";
          format-source-muted = "󰍭";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋎";
            headset = "󰋎";
            phone = "󰏲";
            portable = "󰏲";
            car = "󰄋";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          tooltip-format = "{desc}: {volume}%";
          tooltip-format-muted = "{desc}: muted";
          on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        };
      };
    };
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "yy";
  };

  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = "40.1";
    longitude = "-108.3";
    temperature = {
      day = 5200;
      night = 4400;
    };
    settings = {
      general = {
        brightness-day = 1.0;
        brightness-night = 0.8;
        gamma = 0.9;
        fade = 1;
        adjustment-method = "wayland";
      };
    };
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = false;
      setSessionVariables = true;
      documents = "${config.home.homeDirectory}/documents";
      download = "${config.home.homeDirectory}/downloads";
      pictures = "${config.home.homeDirectory}/pictures";
    };
    configFile = {
      "htop/htoprc".source = ./config/htop/htoprc;
      "mako/config".source = ./config/mako/config;
      "sway/config".source = ./config/sway/config;
      "sway/config.local".source = ./config/sway/config.local;
      "wofi/config".source = ./config/wofi/config;
      "wofi/style.css".source = ./config/wofi/style.css;
      "yazi/keymap.toml".source = ./config/yazi/keymap.toml;
      "yazi/theme.toml".source = ./config/yazi/theme.toml;
      "yazi/yazi.toml".source = ./config/yazi/yazi.toml;
    };
    dataFile = {
      "applications/htop.desktop".text = hiddenDesktopEntry "Htop";
      "applications/lftp.desktop".text = hiddenDesktopEntry "lftp";
      "applications/nvim.desktop".text = hiddenDesktopEntry "nvim";
      "applications/yazi.desktop".text = hiddenDesktopEntry "Yazi";
      "wallpapers/white.jpg".source = ./assets/wallpapers/white.jpg;
    };
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
