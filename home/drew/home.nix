{
  config,
  inputs,
  pkgs,
  ...
}:

let
  theme = import ./themes.nix { variant = "light"; };
  papercolorLightTheme = import ./themes.nix { variant = "light"; };
  papercolorDarkTheme = import ./themes.nix { variant = "dark"; };
  wallpaperFallback = ./assets/wallpapers/white.jpg;
  papercolorLightWallpaper = ./assets/wallpapers/papercolor-light.jpg;
  papercolorDarkWallpaper = ./assets/wallpapers/papercolor-dark.jpg;
  wallpaperSource = path: if builtins.pathExists path then path else wallpaperFallback;
  wallpaperSlices =
    pkgs.runCommand "papercolor-wallpaper-slices" { nativeBuildInputs = [ pkgs.imagemagick ]; }
      ''
        mkdir -p "$out/papercolor-light" "$out/papercolor-dark"

        magick "${wallpaperSource papercolorLightWallpaper}" \
          -resize 5760x1200^ \
          -gravity center \
          -extent 5760x1200 \
          -fill ${papercolorLightTheme.wallpaperColorize.color} \
          -colorize ${toString papercolorLightTheme.wallpaperColorize.amount}% \
          "$TMPDIR/papercolor-light-canvas.jpg"

        magick "${wallpaperSource papercolorDarkWallpaper}" \
          -resize 5760x1200 \
          -background black \
          -gravity north \
          -extent 5760x1200 \
          -fill ${papercolorDarkTheme.wallpaperColorize.color} \
          -colorize ${toString papercolorDarkTheme.wallpaperColorize.amount}% \
          "$TMPDIR/papercolor-dark-canvas.jpg"

        for theme in papercolor-light papercolor-dark; do
          magick "$TMPDIR/$theme-canvas.jpg" -crop 1920x1200+0+0 "$out/$theme/eDP-1.jpg"
          magick "$TMPDIR/$theme-canvas.jpg" -crop 1920x1080+1920+0 "$out/$theme/HDMI-A-1.jpg"
          magick "$TMPDIR/$theme-canvas.jpg" -crop 1920x1080+3840+0 "$out/$theme/DP-2.jpg"
        done
      '';
  swayWallpaperConfig = ''
    output eDP-1 bg $HOME/.local/share/wallpapers/${theme.id}/eDP-1.jpg fill
    output HDMI-A-1 bg $HOME/.local/share/wallpapers/${theme.id}/HDMI-A-1.jpg fill
    output DP-2 bg $HOME/.local/share/wallpapers/${theme.id}/DP-2.jpg fill
  '';

  airpodsConnect = pkgs.writeShellScriptBin "airpods-connect" ''
    ${pkgs.libnotify}/bin/notify-send -t 3000 "Connecting AirPods Pro 3..."
    if ${pkgs.bluez}/bin/bluetoothctl power on && ${pkgs.bluez}/bin/bluetoothctl connect 30:0E:43:42:AF:53; then
      sleep 1
      sink="$(${pkgs.pulseaudio}/bin/pactl list short sinks | ${pkgs.gawk}/bin/awk '/bluez_output\.30_0E_43_42_AF_53/ { print $2; exit }')"
      if [ -n "$sink" ]; then
        ${pkgs.pulseaudio}/bin/pactl set-default-sink "$sink" || true
      fi
      ${pkgs.libnotify}/bin/notify-send -t 3000 "AirPods Pro 3 connected."
    else
      ${pkgs.libnotify}/bin/notify-send -t 3000 "AirPods Pro 3 failed to connect."
    fi
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
      --ring-color ${theme.lockRing} \
      --key-hl-color ${theme.lockKey} \
      --line-color 00000000 \
      --inside-color ${theme.lockInside} \
      --separator-color 00000000 \
      --text-color ${theme.lockText} \
      --text-clear-color ${theme.lockText} \
      --text-caps-lock-color ${theme.lockText} \
      --text-ver-color ${theme.lockVer} \
      --text-wrong-color ${theme.lockWrong} \
      --layout-text-color ${theme.lockText} \
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
          daytime) icon="󱩎" ;;
          night) icon="󱩍" ;;
          transition) icon="󱩏" ;;
          *) icon="󱩐" ;;
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

  ensureLocalProxyNetwork = pkgs.writeShellScript "ensure-local-proxy-network" ''
    ${pkgs.podman}/bin/podman network exists local-proxy || \
      ${pkgs.podman}/bin/podman network create local-proxy
  '';

  removeLocalProxyContainer = pkgs.writeShellScript "remove-local-proxy-container" ''
    ${pkgs.podman}/bin/podman rm -f traefik-local-proxy >/dev/null 2>&1 || true
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
    sessionVariables = {
      DREW_THEME = theme.id;
      DREW_THEME_NAME = theme.name;
      DREW_THEME_VARIANT = theme.variant;
    };
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

  home.file.".claude/settings.json".text =
    builtins.toJSON {
      "$schema" = "https://json.schemastore.org/claude-code-settings.json";
      attribution.commit = "";
      includeCoAuthoredBy = false;
    }
    + "\n";

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

  home.file.".mozilla/firefox/o9eR8D7X.Profile 1/user.js".text = ''
    // Preserve site sessions, including Slack, across Firefox restarts.
    user_pref("privacy.clearOnShutdown.cookies", false);
    user_pref("privacy.clearOnShutdown.offlineApps", false);
    user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
    user_pref("privacy.sanitize.pending", "[]");
  '';

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
      colors = theme.alacrittyColors;
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
      window = {
        decorations = "none";
        opacity = theme.alacrittyOpacity;
        padding = {
          x = 8;
          y = 8;
        };
      };
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
    includes = [
      {
        condition = "gitdir:~/code/foxfuel/";
        contents.user = {
          name = "Drew Norman";
          email = "drewnorman@foxfuelcreative.com";
        };
      }
    ];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "~/.ssh/config.local" ];
    matchBlocks = {
      "github.com" = config.lib.dag.entryBefore [ "wildcardIdentity" ] {
        user = "git";
        identityFile = "~/.ssh/git@github.com";
        identitiesOnly = true;
      };

      "bitbucket.org" = config.lib.dag.entryBefore [ "wildcardIdentity" ] {
        user = "git";
        identityFile = "~/.ssh/git@bitbucket.org";
        identitiesOnly = true;
      };

      wildcardIdentity =
        config.lib.dag.entryAfter
          [
            "github.com"
            "bitbucket.org"
          ]
          {
            host = "* !*.sftp.wpengine.com !lab-core !lab-core-ts";
            identityFile = "~/.ssh/%r@%h";
          };
    };
  };
  home.file.".ssh/config".force = true;

  home.activation.writeMutableSshConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    ssh_dir="${config.home.homeDirectory}/.ssh"
    ssh_config="$ssh_dir/config"

    run ${pkgs.coreutils}/bin/install -d -m 700 "$ssh_dir"
    if [ -e "$ssh_config" ]; then
      if [[ -v DRY_RUN ]]; then
        echo "${pkgs.coreutils}/bin/install -m 600 -T $ssh_config <temporary file>"
        echo "${pkgs.coreutils}/bin/mv <temporary file> $ssh_config"
      else
        config_tmp="$(${pkgs.coreutils}/bin/mktemp "$ssh_dir/config.XXXXXX")"
        ${pkgs.coreutils}/bin/install -m 600 -T "$ssh_config" "$config_tmp"
        ${pkgs.coreutils}/bin/mv -f "$config_tmp" "$ssh_config"
      fi
    fi
    run ${pkgs.coreutils}/bin/chmod 700 "$ssh_dir"
    if [ -e "$ssh_config" ]; then
      run ${pkgs.coreutils}/bin/chmod 600 "$ssh_config"
    fi
  '';

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

      if status --is-login; and test (tty) = /dev/tty1; and test -z "$WAYLAND_DISPLAY"; and test -z "$DISPLAY"
        set -l systemd_jobs (${pkgs.systemd}/bin/systemctl list-jobs --no-legend 2>/dev/null)
        if not string match -qr '(^|[[:space:]])(shutdown|poweroff|reboot|halt|kexec)\.target[[:space:]]+start([[:space:]]|$)' -- $systemd_jobs
          ${pkgs.coreutils}/bin/sleep 5
          exec ${pkgs.systemd}/bin/systemd-cat -t sway sway
        end
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
    extraConfig =
      builtins.replaceStrings [ "/usr/bin/fish" ] [ "${pkgs.fish}/bin/fish" ] (
        builtins.readFile ./config/tmux/tmux.conf
      )
      + "\n"
      + theme.tmuxTheme;
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

  systemd.user.sockets.podman = {
    Unit.Description = "Podman API socket";
    Socket = {
      ListenStream = "%t/podman/podman.sock";
      SocketMode = "0660";
    };
    Install.WantedBy = [ "sockets.target" ];
  };

  systemd.user.services.podman = {
    Unit.Description = "Podman API service";
    Service = {
      ExecStart = "${pkgs.podman}/bin/podman system service --time=0 unix://%t/podman/podman.sock";
      Type = "exec";
    };
  };

  systemd.user.services.traefik-local-proxy = {
    Unit = {
      Description = "Rootless Traefik local development proxy";
      After = [ "podman.socket" ];
      Requires = [ "podman.socket" ];
    };
    Service = {
      ExecStartPre = [
        "${ensureLocalProxyNetwork}"
        "${removeLocalProxyContainer}"
      ];
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name traefik-local-proxy \
          --network local-proxy \
          --publish 127.0.0.1:80:80 \
          --volume %t/podman/podman.sock:/var/run/docker.sock \
          docker.io/library/traefik:v3 \
          --entrypoints.web.address=:80 \
          --providers.docker=true \
          --providers.docker.endpoint=unix:///var/run/docker.sock \
          --providers.docker.exposedbydefault=false \
          --providers.docker.network=local-proxy \
          --log.level=INFO
      '';
      ExecStopPost = "${removeLocalProxyContainer}";
      Restart = "on-failure";
      RestartSec = "2s";
    };
    Install.WantedBy = [ "default.target" ];
  };

  programs.lazygit.enable = true;

  programs.waybar = {
    enable = true;
    style = theme.waybarStyle;
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
          "idle_inhibitor"
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

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
          tooltip-format-activated = "Idle inhibitor active";
          tooltip-format-deactivated = "Idle inhibitor inactive";
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
      "mako/config".text = theme.makoConfig;
      "sway/config".text =
        builtins.replaceStrings
          [
            "output * bg $HOME/.local/share/wallpapers/white.jpg fill"
            "include $HOME/.config/sway/config.local"
          ]
          [
            "# Wallpaper is applied after config.local so output geometry is already set."
            "include $HOME/.config/sway/config.local\n${swayWallpaperConfig}"
          ]
          (builtins.readFile ./config/sway/config);
      "sway/config.local".source = ./config/sway/config.local;
      "wofi/config".source = ./config/wofi/config;
      "wofi/style.css".text = theme.wofiStyle;
      "yazi/keymap.toml".source = ./config/yazi/keymap.toml;
      "yazi/theme.toml".text = theme.yaziTheme;
      "yazi/yazi.toml".source = ./config/yazi/yazi.toml;
    };
    dataFile = {
      "applications/htop.desktop".text = hiddenDesktopEntry "Htop";
      "applications/lftp.desktop".text = hiddenDesktopEntry "lftp";
      "applications/nvim.desktop".text = hiddenDesktopEntry "nvim";
      "applications/yazi.desktop".text = hiddenDesktopEntry "Yazi";
      "wallpapers/white.jpg".source = ./assets/wallpapers/white.jpg;
      "wallpapers/papercolor-light.jpg".source = wallpaperSource papercolorLightWallpaper;
      "wallpapers/papercolor-dark.jpg".source = wallpaperSource papercolorDarkWallpaper;
      "wallpapers/papercolor-light".source = "${wallpaperSlices}/papercolor-light";
      "wallpapers/papercolor-dark".source = "${wallpaperSlices}/papercolor-dark";
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
