{
  variant ? "light",
}:

let
  noHash = color: builtins.substring 1 6 color;

  papercolor = {
    light = {
      id = "papercolor-light";
      name = "papercolor";
      variant = "light";
      wallpaper = "papercolor-light.jpg";
      wallpaperColorize = {
        color = "white";
        amount = 70;
      };
      alacrittyOpacity = 0.35;
      background = "#ffffff";
      wofiBackground = "rgba(255, 255, 255, 0.84)";
      wofiSelectionBackground = "rgba(28, 28, 28, 0.88)";
      foreground = "#1c1c1c";
      cursorText = "#ffffff";
      selectionBackground = "#1c1c1c";
      selectionForeground = "#ffffff";
      statusBackground = "#eeeeee";
      tmuxInactivePaneBackground = "#eeeeee";
      panelBackground = "#ffffff";
      mutedBackground = "#e4e4e4";
      subtleBackground = "#c6c6c6";
      mutedForeground = "#878787";
      statusForeground = "#444444";
      border = "#1c1c1c";
      accent = "#007ea2";
      accentAlt = "#005f87";
      accentTint = "rgba(0, 126, 162, 0.1)";
      blue = "#005faf";
      cyan = "#0087af";
      brightCyan = "#00afaf";
      green = "#008700";
      brightGreen = "#5f8700";
      yellow = "#d75f00";
      orange = "#af5f00";
      magenta = "#d70087";
      purple = "#8700af";
      red = "#af0000";
      brightRed = "#d70000";
      white = "#ffffff";
      offWhite = "#fffff0";
      black = "#1c1c1c";
      waybarChromiumBackground = "#1c1b19";
      lockRing = "005f87";
      lockKey = "008700";
      lockInside = "ffffff88";
      lockText = "1c1c1c";
      lockVer = "005f87";
      lockWrong = "af0000";
    };

    dark = {
      id = "papercolor-dark";
      name = "papercolor";
      variant = "dark";
      wallpaper = "papercolor-dark.jpg";
      wallpaperColorize = {
        color = "black";
        amount = 0;
      };
      alacrittyOpacity = 0.75;
      background = "#1c1c1c";
      wofiBackground = "rgba(28, 28, 28, 0.84)";
      wofiSelectionBackground = "rgba(208, 208, 208, 0.88)";
      foreground = "#d0d0d0";
      cursorText = "#1c1c1c";
      selectionBackground = "#d0d0d0";
      selectionForeground = "#1c1c1c";
      statusBackground = "#303030";
      tmuxInactivePaneBackground = "#151515";
      panelBackground = "#1c1c1c";
      mutedBackground = "#3a3a3a";
      subtleBackground = "#585858";
      mutedForeground = "#808080";
      statusForeground = "#d0d0d0";
      border = "#d0d0d0";
      accent = "#5fafd7";
      accentAlt = "#0087af";
      accentTint = "rgba(95, 175, 215, 0.12)";
      blue = "#5fafd7";
      cyan = "#5fd7af";
      brightCyan = "#5fd7d7";
      green = "#afd700";
      brightGreen = "#afdf00";
      yellow = "#d7af5f";
      orange = "#d7875f";
      magenta = "#d75f87";
      purple = "#af87d7";
      red = "#d7005f";
      brightRed = "#df005f";
      white = "#d0d0d0";
      offWhite = "#eeeeee";
      black = "#1c1c1c";
      waybarChromiumBackground = "#303030";
      lockRing = "5fafd7";
      lockKey = "afd700";
      lockInside = "00000088";
      lockText = "f5f5f5";
      lockVer = "5fafd7";
      lockWrong = "d7005f";
    };
  };

  palette = papercolor.${variant};

  waybarStyle = ''
    * {
        border: none;
        border-radius: 0;
        font-family: "Inconsolata Medium", "Symbols Nerd Font Mono", monospace;
        font-size: 14px;
        min-height: 0;
    }

    window#waybar {
        padding: 20px;
        background-color: transparent;
        color: ${palette.foreground};
        transition-property: background-color;
        transition-duration: .5s;
    }

    window#waybar.hidden {
        opacity: 0.2;
    }

    window#waybar.chromium {
        background-color: ${palette.waybarChromiumBackground};
        border: none;
    }

    #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: ${palette.foreground};
    }

    #workspaces button:hover {
        background: ${palette.accentTint};
    }

    #workspaces button.focused {
        background-color: transparent;
        color: ${palette.foreground};
        box-shadow: inset 0 -2px ${palette.accent};
    }

    #workspaces button.urgent {
        background-color: ${palette.red};
        color: ${palette.selectionForeground};
    }

    #mode {
        background-color: ${palette.mutedForeground};
        border-bottom: 3px solid ${palette.border};
    }

    #clock,
    #battery,
    #cpu,
    #memory,
    #disk,
    #temperature,
    #backlight,
    #network,
    #pulseaudio,
    #custom-media,
    #custom-gammastep,
    #tray,
    #mode,
    #idle_inhibitor,
    #mpd {
        padding: 0 10px;
        color: ${palette.foreground};
    }

    #clock {
        color: ${palette.foreground};
    }

    #window,
    #workspaces {
        margin: 0 4px;
    }

    .modules-left > widget:first-child > #workspaces {
        margin-left: 0;
    }

    .modules-right > widget:last-child > #workspaces {
        margin-right: 0;
    }

    @keyframes blink {
        to {
            background-color: ${palette.selectionBackground};
            color: ${palette.waybarChromiumBackground};
        }
    }

    #battery.critical:not(.charging) {
        background-color: ${palette.waybarChromiumBackground};
        color: ${palette.foreground};
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
    }

    label:focus {
        background-color: ${palette.waybarChromiumBackground};
    }

    #network.disconnected {
        background-color: ${palette.red};
        color: ${palette.selectionForeground};
    }

    #custom-media {
        min-width: 100px;
    }

    #temperature.critical {
        background-color: ${palette.red};
        color: ${palette.selectionForeground};
    }

    #mpd.disconnected {
        background-color: ${palette.red};
    }

    #mpd.stopped {
        background-color: ${palette.selectionBackground};
    }

    #mpd.paused {
        background-color: ${palette.green};
    }

    #language {
        padding: 0 5px;
        margin: 0 5px;
        min-width: 16px;
    }
  '';

  wofiStyle = ''
    @define-color theme_fg_color ${palette.foreground};
    @define-color theme_text_color ${palette.foreground};
    @define-color theme_selected_fg_color ${palette.foreground};
    @define-color theme_selected_bg_color transparent;

    * {
      font-family: "Inconsolata Medium", monospace;
      color: ${palette.foreground};
    }

    #entry,
    flowboxchild {
      color: ${palette.foreground};
    }

    #entry:selected,
    #entry:selected:focus,
    #entry:selected:hover,
    flowboxchild:selected,
    flowboxchild:selected:focus,
    flowboxchild:selected:hover {
      background-color: transparent;
      border-left: 3px solid ${palette.accent};
      color: ${palette.foreground} !important;
    }

    #selected,
    #selected #text,
    #selected label,
    #selected *,
    #text:selected,
    #text:focus,
    label,
    label:selected {
      color: ${palette.foreground} !important;
    }

    #input {
      background-color: ${palette.wofiBackground};
      color: ${palette.foreground};
      border: none;
      border-radius: 0px;
    }

    #text {
      margin-left: 1em;
      color: ${palette.foreground} !important;
    }

    window {
      background-color: ${palette.wofiBackground};
      color: ${palette.foreground};
      border-radius: 0px;
    }
  '';

  makoConfig = ''
    width=400
    height=300
    margin=15
    padding=10
    border-color=${noHash palette.accent}FF
    border-size=1
    background-color=${noHash palette.background}FF
    text-color=${noHash palette.foreground}FF
    font=Inconsolata Medium 11
  '';

  tmuxTheme = ''
    # --- colors (${palette.id}) ---

    # pane borders
    set -g pane-border-style "fg=${palette.subtleBackground}"
    set -g pane-active-border-style "fg=${palette.accent}"
    set -g window-style "bg=${palette.tmuxInactivePaneBackground}"
    set -g window-active-style "bg=default"

    # status bar
    set -g status on
    set -g status-position bottom
    set -g status-style "bg=${palette.statusBackground},fg=${palette.statusForeground}"
    set -g status-left-length 30
    set -g status-right-length 50

    set -g status-left "#[bg=${palette.accent},fg=${palette.selectionForeground}] #{session_name} #[bg=${palette.statusBackground},fg=${palette.statusForeground}] "
    set -g status-right "#[fg=${palette.subtleBackground}]| #[fg=${palette.statusForeground}]%Y-%m-%d %H:%M "

    # window list
    setw -g window-status-style "bg=${palette.statusBackground},fg=${palette.subtleBackground}"
    setw -g window-status-format " #I:#W "
    setw -g window-status-current-style "bg=${palette.accent},fg=${palette.selectionForeground}"
    setw -g window-status-current-format " #I:#W "

    # message / command prompt
    set -g message-style "bg=${palette.accent},fg=${palette.selectionForeground}"
  '';

  yaziTheme = ''
    # ${palette.id}-inspired Yazi theme.

    [app]
    overall = { bg = "${palette.background}" }

    [mgr]
    cwd             = { fg = "${palette.accentAlt}", bold = true }
    find_keyword    = { fg = "${palette.green}", bg = "${palette.mutedBackground}" }
    find_position   = { fg = "${palette.orange}", bg = "${palette.mutedBackground}" }
    symlink_target  = { fg = "${palette.mutedForeground}", italic = true }
    marker_copied   = { fg = "${palette.green}", bg = "${palette.mutedBackground}" }
    marker_cut      = { fg = "${palette.red}", bg = "${palette.mutedBackground}" }
    marker_marked   = { fg = "${palette.purple}", bg = "${palette.mutedBackground}" }
    marker_selected = { fg = "${palette.blue}", bg = "${palette.mutedBackground}" }
    count_copied    = { fg = "${palette.green}", bg = "${palette.mutedBackground}" }
    count_cut       = { fg = "${palette.red}", bg = "${palette.mutedBackground}" }
    count_selected  = { fg = "${palette.blue}", bg = "${palette.mutedBackground}" }
    border_symbol   = "|"
    border_style    = { fg = "${palette.accentAlt}" }

    [indicator]
    parent  = { fg = "${palette.accent}", bg = "${palette.mutedBackground}" }
    current = { fg = "${palette.accentAlt}", bg = "${palette.mutedBackground}" }
    preview = { fg = "${palette.accent}", bg = "${palette.mutedBackground}" }
    padding = { open = "█", close = "█" }

    [tabs]
    active    = { fg = "${palette.background}", bg = "${palette.accentAlt}", bold = true }
    inactive  = { fg = "${palette.statusForeground}", bg = "${palette.subtleBackground}" }
    sep_inner = { open = "[", close = "]" }
    sep_outer = { open = "", close = "" }

    [mode]
    normal_main = { fg = "${palette.background}", bg = "${palette.accentAlt}", bold = true }
    normal_alt  = { fg = "${palette.accentAlt}", bg = "${palette.mutedBackground}" }
    select_main = { fg = "${palette.background}", bg = "${palette.green}", bold = true }
    select_alt  = { fg = "${palette.green}", bg = "${palette.mutedBackground}" }
    unset_main  = { fg = "${palette.background}", bg = "${palette.purple}", bold = true }
    unset_alt   = { fg = "${palette.purple}", bg = "${palette.mutedBackground}" }

    [status]
    overall         = { fg = "${palette.statusForeground}", bg = "${palette.statusBackground}" }
    sep_left        = { open = "", close = "" }
    sep_right       = { open = "", close = "" }
    perm_type       = { fg = "${palette.accent}" }
    perm_read       = { fg = "${palette.green}" }
    perm_write      = { fg = "${palette.orange}" }
    perm_exec       = { fg = "${palette.red}" }
    perm_sep        = { fg = "${palette.mutedForeground}" }
    progress_label  = { fg = "${palette.statusForeground}", bold = true }
    progress_normal = { fg = "${palette.accentAlt}", bg = "${palette.subtleBackground}" }
    progress_error  = { fg = "${palette.red}", bg = "${palette.subtleBackground}" }

    [which]
    cols            = 3
    mask            = { bg = "${palette.mutedBackground}" }
    cand            = { fg = "${palette.blue}", bold = true }
    rest            = { fg = "${palette.mutedForeground}" }
    desc            = { fg = "${palette.statusForeground}" }
    separator       = " -> "
    separator_style = { fg = "${palette.mutedForeground}" }

    [confirm]
    border     = { fg = "${palette.accentAlt}" }
    title      = { fg = "${palette.green}", bold = true }
    body       = { fg = "${palette.statusForeground}" }
    list       = { fg = "${palette.statusForeground}" }
    btn_yes    = { fg = "${palette.background}", bg = "${palette.green}", bold = true }
    btn_no     = { fg = "${palette.statusForeground}", bg = "${palette.subtleBackground}" }
    btn_labels = [ " yes ", " no " ]

    [spot]
    border   = { fg = "${palette.accentAlt}" }
    title    = { fg = "${palette.green}", bold = true }
    tbl_col  = { fg = "${palette.blue}", bg = "${palette.mutedBackground}" }
    tbl_cell = { fg = "${palette.statusForeground}", bg = "${palette.mutedBackground}" }

    [notify]
    title_info  = { fg = "${palette.blue}", bold = true }
    title_warn  = { fg = "${palette.orange}", bold = true }
    title_error = { fg = "${palette.red}", bold = true }

    [pick]
    border   = { fg = "${palette.accentAlt}" }
    active   = { fg = "${palette.background}", bg = "${palette.accent}" }
    inactive = { fg = "${palette.statusForeground}" }

    [input]
    border   = { fg = "${palette.accentAlt}" }
    title    = { fg = "${palette.green}", bold = true }
    value    = { fg = "${palette.statusForeground}" }
    selected = { fg = "${palette.background}", bg = "${palette.accent}" }

    [cmp]
    border       = { fg = "${palette.accentAlt}" }
    active       = { fg = "${palette.background}", bg = "${palette.accent}" }
    inactive     = { fg = "${palette.statusForeground}" }
    icon_file    = "f"
    icon_folder  = "d"
    icon_command = "$"

    [tasks]
    border  = { fg = "${palette.accentAlt}" }
    title   = { fg = "${palette.green}", bold = true }
    hovered = { fg = "${palette.background}", bg = "${palette.accent}" }

    [help]
    on         = { fg = "${palette.blue}", bold = true }
    run        = { fg = "${palette.purple}" }
    desc       = { fg = "${palette.statusForeground}" }
    hovered    = { fg = "${palette.background}", bg = "${palette.accent}" }
    footer     = { fg = "${palette.mutedForeground}", bg = "${palette.mutedBackground}" }
    icon_info  = "i"
    icon_warn  = "!"
    icon_error = "x"

    [filetype]
    rules = [
      { mime = "image/*", fg = "${palette.orange}" },
      { mime = "{audio,video}/*", fg = "${palette.purple}" },
      { mime = "application/{zip,tar,gzip,xz,7z,rar}", fg = "${palette.yellow}" },
      { mime = "inode/empty", fg = "${palette.mutedForeground}" },
      { url = "*", is = "orphan", fg = "${palette.red}" },
      { url = "*", is = "exec", fg = "${palette.green}" },
      { url = "*/", fg = "${palette.accent}", bold = true },
      { url = "*", fg = "${palette.statusForeground}" },
    ]
  '';

in
palette
// {
  alacrittyColors = {
    draw_bold_text_with_bright_colors = true;
    bright = {
      black = palette.black;
      blue = palette.accentAlt;
      cyan = palette.brightCyan;
      green = palette.brightGreen;
      magenta = palette.purple;
      red = palette.brightRed;
      white = palette.white;
      yellow = palette.yellow;
    };
    cursor = {
      cursor = palette.accent;
      text = palette.cursorText;
    };
    normal = {
      black = palette.black;
      blue = palette.blue;
      cyan = palette.cyan;
      green = palette.green;
      magenta = palette.magenta;
      red = palette.red;
      white = palette.white;
      yellow = palette.yellow;
    };
    primary = {
      background = palette.background;
      foreground = palette.foreground;
    };
    selection = {
      background = palette.selectionBackground;
      text = palette.selectionForeground;
    };
  };

  inherit
    makoConfig
    tmuxTheme
    waybarStyle
    wofiStyle
    yaziTheme
    ;
}
