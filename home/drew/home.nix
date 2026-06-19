{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  variant = import ./theme-variant.nix;
  theme = import ./themes.nix { inherit variant; };
  isDark = theme.variant == "dark";
  gtkColorScheme = if isDark then "prefer-dark" else "default";
  gtkThemeName = if isDark then "Adwaita-dark" else "Adwaita";
  gtkThemeEnv = if isDark then "Adwaita:dark" else "Adwaita";
  firefoxDarkMode = if isDark then 1 else 0;
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
  agsConfig = pkgs.runCommand "drew-ags-config" { } ''
    mkdir -p "$out"
    cp ${./config/ags/app.tsx} "$out/app.tsx"
    cp ${./config/ags/Bar.tsx} "$out/Bar.tsx"
    cp ${pkgs.writeText "drew-ags-style.scss" theme.agsStyle} "$out/style.scss"
  '';
  swayWorkspaceState = pkgs.writeShellApplication {
    name = "sway-workspace-state";
    runtimeInputs = with pkgs; [
      jq
      sway
    ];
    text = ''
      output="''${1:-}"

      case "$output" in
        eDP-1) slots="1 4 7 10" ;;
        HDMI-A-1) slots="2 5 8" ;;
        DP-2) slots="3 6 9" ;;
        *)
          printf '[]\n'
          exit 0
          ;;
      esac

      last_state=""

      emit() {
        outputs="$(swaymsg -t get_outputs 2>/dev/null || printf '[]')"
        workspaces="$(swaymsg -t get_workspaces 2>/dev/null || printf '[]')"

        state="$(jq -cn \
          --arg output "$output" \
          --arg slots "$slots" \
          --argjson outputs "$outputs" \
          --argjson workspaces "$workspaces" \
          '
          def slot_output($num):
            if ($num == 1 or $num == 4 or $num == 7 or $num == 10) then "eDP-1"
            elif ($num == 2 or $num == 5 or $num == 8) then "HDMI-A-1"
            else "DP-2"
            end;

          def slotnums: $slots | split(" ") | map(tonumber);
          def active_outputs: $outputs | map(select(.active // false) | .name);
          def first_active_output: active_outputs | .[0] // $output;

          [
            ((slotnums + [1,2,3,4,5,6,7,8,9,10]) | unique[]) as $num |
            (slot_output($num)) as $slot_output |
            (active_outputs | index($slot_output) != null) as $slot_output_active |
            select($slot_output == $output or (($slot_output_active | not) and $output == first_active_output)) |
            ($workspaces | map(select(.num == $num and (.output == $output or .output == $slot_output))) | .[0] // null) as $ws |
            (($ws != null) and ($ws.visible // false)) as $active |
            (($ws != null) and (($ws.representation // "") != "")) as $non_empty |
            select($active or $non_empty) |
            {
              num: $num,
              name: ($ws.name // ($num | tostring)),
              active: $active,
              visible: ($ws.visible // false),
              focused: ($ws.focused // false),
              urgent: ($ws.urgent // false),
              current_workspace: $active,
              non_empty: $non_empty
            }
          ]
          '
        )"

        if [ "$state" != "$last_state" ]; then
          printf '%s\n' "$state"
          last_state="$state"
        fi
      }

      emit

      swaymsg -m -t subscribe '["workspace","window","output"]' 2>/dev/null | while IFS= read -r _event; do
        emit
      done &
      subscriber_pid="$!"

      trap 'kill "$subscriber_pid" 2>/dev/null || true' EXIT

      while true; do
        sleep 0.5
        emit
      done
    '';
  };
  swayWallpaperConfig = ''
    output eDP-1 bg $HOME/.local/share/wallpapers/${theme.id}/eDP-1.jpg fill
    output HDMI-A-1 bg $HOME/.local/share/wallpapers/${theme.id}/HDMI-A-1.jpg fill
    output DP-2 bg $HOME/.local/share/wallpapers/${theme.id}/DP-2.jpg fill
  '';
  refreshThemeSession = pkgs.writeShellApplication {
    name = "drew-refresh-theme-session";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      dbus
      glib
      procps
      sway
      systemd
      tmux
      util-linux
    ];
    text = ''
      set -u

      variant="${theme.variant}"
      theme_id="${theme.id}"
      theme_name="${theme.name}"
      refresh_signature="$variant:$theme_id:5"
      gtk_theme="${gtkThemeName}"
      gtk_color_scheme="${gtkColorScheme}"
      gtk_theme_env="${gtkThemeEnv}"

      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
      export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
      export DREW_THEME="$theme_id"
      export DREW_THEME_NAME="$theme_name"
      export DREW_THEME_VARIANT="$variant"
      export GTK_THEME="$gtk_theme_env"

      state_dir="$HOME/.local/state"
      state_file="$state_dir/drew-theme"
      session_state_file="$state_dir/drew-theme-session"
      old_variant=""
      old_refresh_signature=""

      if [ -r "$state_file" ]; then
        old_variant="$(${pkgs.coreutils}/bin/cat "$state_file" 2>/dev/null || true)"
      fi
      if [ -r "$session_state_file" ]; then
        old_refresh_signature="$(${pkgs.coreutils}/bin/cat "$session_state_file" 2>/dev/null || true)"
      elif [ -n "$old_variant" ]; then
        old_refresh_signature="$old_variant"
      fi

      ${pkgs.coreutils}/bin/mkdir -p "$state_dir"
      ${pkgs.coreutils}/bin/printf '%s\n' "$variant" > "$state_file"
      ${pkgs.coreutils}/bin/printf '%s\n' "$refresh_signature" > "$session_state_file"

      if [ -z "''${SWAYSOCK:-}" ]; then
        for candidate in "$XDG_RUNTIME_DIR"/sway-ipc.*.sock; do
          if [ -S "$candidate" ]; then
            export SWAYSOCK="$candidate"
            break
          fi
        done
      fi

      has_user_bus=0
      if [ -S "$XDG_RUNTIME_DIR/bus" ]; then
        has_user_bus=1
      fi

      has_sway=0
      if [ -n "''${SWAYSOCK:-}" ] && ${pkgs.sway}/bin/swaymsg -t get_version >/dev/null 2>&1; then
        has_sway=1
      fi

      if [ "$has_user_bus" -eq 1 ]; then
        ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
          DREW_THEME DREW_THEME_NAME DREW_THEME_VARIANT GTK_THEME \
          XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
          WAYLAND_DISPLAY SWAYSOCK DISPLAY DBUS_SESSION_BUS_ADDRESS \
          >/dev/null 2>&1 || true

        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme "$gtk_color_scheme" >/dev/null 2>&1 || true
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" >/dev/null 2>&1 || true
      fi

      if [ "$has_sway" -eq 1 ]; then
        ${pkgs.sway}/bin/swaymsg reload >/dev/null 2>&1 || true
        ${pkgs.sway}/bin/swaymsg exec "${pkgs.tmux}/bin/tmux source-file '$HOME/.config/tmux/tmux.conf'" >/dev/null 2>&1 || true
      fi

      if ${pkgs.tmux}/bin/tmux has-session >/dev/null 2>&1; then
        ${pkgs.tmux}/bin/tmux source-file "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1 || true
      fi

      if [ "$old_refresh_signature" = "$refresh_signature" ]; then
        exit 0
      fi

      user_systemctl() {
        if [ "$has_user_bus" -eq 1 ]; then
          ${pkgs.systemd}/bin/systemctl --user "$@" >/dev/null 2>&1 || true
        fi
      }

      delayed_user_unit() {
        unit="$1"
        command="$2"

        if [ "$has_user_bus" -ne 1 ]; then
          return 0
        fi

        env_args=(
          "--setenv=XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
          "--setenv=DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
          "--setenv=GTK_THEME=$GTK_THEME"
          "--setenv=DREW_THEME=$DREW_THEME"
          "--setenv=DREW_THEME_NAME=$DREW_THEME_NAME"
          "--setenv=DREW_THEME_VARIANT=$DREW_THEME_VARIANT"
        )

        if [ -n "''${SWAYSOCK:-}" ]; then
          env_args+=("--setenv=SWAYSOCK=$SWAYSOCK")
        fi
        if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
          env_args+=("--setenv=WAYLAND_DISPLAY=$WAYLAND_DISPLAY")
        fi
        if [ -n "''${DISPLAY:-}" ]; then
          env_args+=("--setenv=DISPLAY=$DISPLAY")
        fi

        ${pkgs.systemd}/bin/systemd-run --user --collect --quiet \
          --unit="$unit" \
          "''${env_args[@]}" \
          ${pkgs.bash}/bin/bash -lc "$command" \
          >/dev/null 2>&1 || true
      }

      async_command() {
        unit="$1"
        command="$2"

        if [ "$has_user_bus" -eq 1 ]; then
          delayed_user_unit "$unit" "$command"
        else
          ${pkgs.util-linux}/bin/setsid -f ${pkgs.bash}/bin/bash -lc "$command" >/dev/null 2>&1 || true
        fi
      }

      user_systemctl try-restart ags.service
      user_systemctl try-restart xdg-desktop-portal.service
      user_systemctl try-restart xdg-desktop-portal-gtk.service
      user_systemctl try-restart xdg-desktop-portal-wlr.service

      if ${pkgs.procps}/bin/pgrep -x mako >/dev/null 2>&1; then
        ${pkgs.procps}/bin/pkill -TERM -x mako >/dev/null 2>&1 || true
        if [ "$has_sway" -eq 1 ]; then
          ${pkgs.sway}/bin/swaymsg exec ${pkgs.mako}/bin/mako >/dev/null 2>&1 || true
        else
          ${pkgs.util-linux}/bin/setsid -f ${pkgs.mako}/bin/mako >/dev/null 2>&1 || true
        fi
      fi

      stamp="$(${pkgs.coreutils}/bin/date +%s)"

      if [ "$has_sway" -eq 1 ] && ${pkgs.procps}/bin/pgrep -x firefox >/dev/null 2>&1; then
        async_command "drew-theme-restart-firefox-$stamp" \
          '${pkgs.procps}/bin/pkill -TERM -x firefox >/dev/null 2>&1 || true; for _ in 1 2 3 4 5; do ${pkgs.procps}/bin/pgrep -x firefox >/dev/null 2>&1 || break; sleep 1; done; ${pkgs.sway}/bin/swaymsg exec ${pkgs.firefox}/bin/firefox >/dev/null 2>&1 || true'
      fi

      if [ "$has_sway" -eq 1 ] && ${pkgs.procps}/bin/pgrep -x chromium >/dev/null 2>&1; then
        async_command "drew-theme-restart-chromium-$stamp" \
          '${pkgs.procps}/bin/pkill -TERM -x chromium >/dev/null 2>&1 || true; for _ in 1 2 3 4 5; do ${pkgs.procps}/bin/pgrep -x chromium >/dev/null 2>&1 || break; sleep 1; done; ${pkgs.sway}/bin/swaymsg exec ${pkgs.chromium}/bin/chromium >/dev/null 2>&1 || true'
      fi
    '';
  };
  dictateIcon = "󰔊";

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
  '';

  dictateStatus = pkgs.writeShellScriptBin "dictate-status" ''
    runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}/dictate"
    status_file="$runtime_dir/status.json"

    if [ -s "$status_file" ]; then
      ${pkgs.coreutils}/bin/cat "$status_file"
    else
      ${pkgs.jq}/bin/jq -cn \
        --arg text "${dictateIcon}" \
        --arg tooltip "Dictation idle" \
        --arg class "idle" \
        '{text: $text, tooltip: $tooltip, class: $class}'
    fi
  '';

  dictateStreamStart = pkgs.writeShellScriptBin "dictate-stream-start" ''
    set -u

    runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}/dictate"
    model_file="$HOME/.local/share/whisper/models/ggml-base.en.bin"
    fallback_model_file="$HOME/.local/share/whisper/models/ggml-small.en.bin"
    final_fallback_model_file="$HOME/.local/share/whisper/models/ggml-medium.en.bin"
    stream_pid_file="$runtime_dir/stream.pid"
    parser_pid_file="$runtime_dir/parser.pid"
    watcher_pid_file="$runtime_dir/watcher.pid"
    status_file="$runtime_dir/status.json"
    stream_output="$runtime_dir/stream.out"
    stream_log="$runtime_dir/stream.log"
    parser_log="$runtime_dir/parser.log"
    startup_log="$runtime_dir/startup.log"

    update_status() {
      ${pkgs.jq}/bin/jq -cn \
        --arg text "$1" \
        --arg tooltip "$2" \
        --arg class "$3" \
        '{text: $text, tooltip: $tooltip, class: $class}' > "$status_file"
    }

    is_alive() {
      pid_file="$1"
      [ -s "$pid_file" ] && ${pkgs.procps}/bin/kill -0 "$(${pkgs.coreutils}/bin/cat "$pid_file")" >/dev/null 2>&1
    }

    ${pkgs.coreutils}/bin/mkdir -p "$runtime_dir"

    if is_alive "$stream_pid_file" || is_alive "$parser_pid_file"; then
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Dictation is already listening."
      exit 0
    fi

    if [ -s "$model_file" ]; then
      model_name="base.en"
    elif [ -s "$fallback_model_file" ]; then
      model_file="$fallback_model_file"
      model_name="small.en"
      ${pkgs.libnotify}/bin/notify-send -t 5000 "Dictation using small.en" "Run dictate-model-install to install base.en for lower latency."
    elif [ -s "$final_fallback_model_file" ]; then
      model_file="$final_fallback_model_file"
      model_name="medium.en"
      ${pkgs.libnotify}/bin/notify-send -t 5000 "Dictation using medium.en" "Run dictate-model-install to install base.en for lower latency."
    else
      update_status "${dictateIcon}" "Missing Whisper model. Run dictate-model-install." "error"
      ${pkgs.libnotify}/bin/notify-send -t 7000 "Dictation model missing" "Run dictate-model-install first."
      exit 1
    fi

    ${pkgs.coreutils}/bin/rm -f "$stream_output" "$stream_log" "$parser_log" "$startup_log" "$stream_pid_file" "$parser_pid_file" "$watcher_pid_file"
    : > "$stream_output"
    : > "$parser_log"
    update_status "${dictateIcon}" "Dictation listening with $model_name (step 3s, window 10s)..." "listening"

    ${pkgs.whisper-cpp}/bin/whisper-stream \
      -m "$model_file" \
      -l en \
      -t 8 \
      --step 3000 \
      --length 10000 \
      -vth 0.6 \
      > "$stream_output" 2> "$stream_log" &
    stream_pid="$!"
    printf '%s\n' "$stream_pid" > "$stream_pid_file"

    ${pkgs.coreutils}/bin/sleep 0.5
    if ! ${pkgs.procps}/bin/kill -0 "$stream_pid" >/dev/null 2>&1; then
      failure="$(${pkgs.coreutils}/bin/tail -n 4 "$stream_log" 2>/dev/null | ${pkgs.coreutils}/bin/tr '\n' ' ' | ${pkgs.gnused}/bin/sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
      [ -n "$failure" ] || failure="See $stream_log"
      update_status "${dictateIcon}" "Dictation stream failed: $failure" "error"
      ${pkgs.libnotify}/bin/notify-send -t 8000 "Dictation stream failed" "$failure"
      ${pkgs.coreutils}/bin/rm -f "$stream_pid_file"
      exit 1
    fi

    (
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        ${pkgs.coreutils}/bin/sleep 0.5
        ${pkgs.gnugrep}/bin/grep -Eq 'using VAD|n_new_line' "$stream_log" 2>/dev/null && exit 0
        if ! ${pkgs.procps}/bin/kill -0 "$stream_pid" >/dev/null 2>&1; then
          failure="$(${pkgs.coreutils}/bin/tail -n 4 "$stream_log" 2>/dev/null | ${pkgs.coreutils}/bin/tr '\n' ' ' | ${pkgs.gnused}/bin/sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
          [ -n "$failure" ] || failure="See $stream_log"
          update_status "${dictateIcon}" "Dictation stream failed: $failure" "error"
          ${pkgs.libnotify}/bin/notify-send -t 8000 "Dictation stream failed" "$failure"
          ${pkgs.coreutils}/bin/rm -f "$stream_pid_file"
          exit 1
        fi
      done
      printf '%s\n' "Dictation stream is still starting. See $stream_log" > "$startup_log"
      update_status "${dictateIcon}" "Dictation still starting. See $stream_log" "listening"
    ) &

    (
      ${pkgs.coreutils}/bin/tail -c +1 -F "$stream_output" 2>/dev/null |
        ${pkgs.gawk}/bin/awk '
          BEGIN {
            RS = "\r|\n"
          }

          function clean(value) {
            gsub(/\033\[[0-9;?]*[[:alpha:]]/, "", value)
            gsub(/\[[^]]*\][ ]*/, "", value)
            gsub(/[[:space:]]+/, " ", value)
            sub(/^ /, "", value)
            sub(/ $/, "", value)
            return value
          }

          function emit_text(value, emit, max_overlap, i) {
            value = clean(value)
            if (value == "") {
              return
            }

            emit = value
            if (last_text != "") {
              if (value == last_text) {
                emit = ""
              } else if (index(value, last_text) == 1) {
                emit = substr(value, length(last_text) + 1)
              } else if (index(last_text, value) == 1) {
                emit = ""
              } else {
                max_overlap = length(last_text)
                if (length(value) < max_overlap) {
                  max_overlap = length(value)
                }
                for (i = max_overlap; i > 0; i--) {
                  if (substr(last_text, length(last_text) - i + 1) == substr(value, 1, i)) {
                    emit = substr(value, i + 1)
                    break
                  }
                }
              }
            }

            last_text = value
            emit = clean(emit)
            if (emit != "") {
              print "STATUS\tTranscribing...\ttranscribing"
              print "TEXT\t" emit
              print "STATUS\tDictation listening...\tlistening"
              fflush()
            }
          }

          /^### Transcription [0-9]+ START/ {
            in_block = 1
            text = ""
            print "STATUS\tTranscribing...\ttranscribing"
            fflush()
            next
          }

          /^### Transcription [0-9]+ END/ {
            if (in_block) {
              emit_text(text)
            }
            in_block = 0
            text = ""
            next
          }

          in_block && $0 !~ /^$/ {
            text = text " " $0
            next
          }

          {
            line = clean($0)
            if (line == "" || line == "Start speaking" || line == "BLANK_AUDIO") {
              next
            }
            emit_text(line)
          }
        ' |
        while IFS="$(printf '\t')" read -r kind value class; do
          case "$kind" in
            STATUS)
              update_status "${dictateIcon}" "$value" "$class"
              ;;
            TEXT)
              printf '%s\n' "Typing: $value" >> "$parser_log"
              focused="$(${pkgs.sway}/bin/swaymsg -t get_tree 2>/dev/null | ${pkgs.jq}/bin/jq -r '.. | objects | select(.focused? == true) | [(.app_id // .window_properties.class // "unknown"), (.name // "unnamed")] | @tsv' 2>/dev/null || true)"
              [ -n "$focused" ] && printf '%s\n' "Focus: $focused" >> "$parser_log"
              update_status "${dictateIcon}" "Dictation typing into focused window..." "typing"
              if ! ${pkgs.wtype}/bin/wtype -d 15 -- "$value " >> "$parser_log" 2>&1; then
                update_status "${dictateIcon}" "Dictation typing failed. See $parser_log" "error"
                ${pkgs.libnotify}/bin/notify-send -t 8000 "Dictation typing failed" "See $parser_log"
              fi
              ;;
          esac
        done
    ) &
    parser_pid="$!"
    printf '%s\n' "$parser_pid" > "$parser_pid_file"

    (
      while ${pkgs.procps}/bin/kill -0 "$stream_pid" >/dev/null 2>&1; do
        ${pkgs.coreutils}/bin/sleep 1
      done

      if [ -s "$stream_pid_file" ] && [ "$(${pkgs.coreutils}/bin/cat "$stream_pid_file")" = "$stream_pid" ]; then
        failure="$(${pkgs.coreutils}/bin/tail -n 4 "$stream_log" 2>/dev/null | ${pkgs.coreutils}/bin/tr '\n' ' ' | ${pkgs.gnused}/bin/sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
        [ -n "$failure" ] || failure="See $stream_log"
        update_status "${dictateIcon}" "Dictation stream exited: $failure" "error"
        ${pkgs.libnotify}/bin/notify-send -t 8000 "Dictation stream exited" "$failure"
        ${pkgs.coreutils}/bin/rm -f "$stream_pid_file"
      fi
    ) &
    watcher_pid="$!"
    printf '%s\n' "$watcher_pid" > "$watcher_pid_file"

    ${pkgs.libnotify}/bin/notify-send -t 2000 "Dictation listening with $model_name..."
  '';

  dictateStreamStop = pkgs.writeShellScriptBin "dictate-stream-stop" ''
    set -u

    runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}/dictate"
    stream_pid_file="$runtime_dir/stream.pid"
    parser_pid_file="$runtime_dir/parser.pid"
    watcher_pid_file="$runtime_dir/watcher.pid"
    status_file="$runtime_dir/status.json"

    update_status() {
      ${pkgs.coreutils}/bin/mkdir -p "$runtime_dir"
      ${pkgs.jq}/bin/jq -cn \
        --arg text "$1" \
        --arg tooltip "$2" \
        --arg class "$3" \
        '{text: $text, tooltip: $tooltip, class: $class}' > "$status_file"
    }

    kill_tree() {
      pid="$1"
      ${pkgs.procps}/bin/kill -0 "$pid" >/dev/null 2>&1 || return 0
      for child in $(${pkgs.procps}/bin/pgrep -P "$pid" 2>/dev/null || true); do
        kill_tree "$child"
      done
      ${pkgs.procps}/bin/kill "$pid" >/dev/null 2>&1 || true
    }

    kill_pid_file() {
      pid_file="$1"
      if [ -s "$pid_file" ]; then
        kill_tree "$(${pkgs.coreutils}/bin/cat "$pid_file")"
      fi
    }

    kill_pid_file "$stream_pid_file"
    ${pkgs.coreutils}/bin/sleep 0.7
    kill_pid_file "$parser_pid_file"
    kill_pid_file "$watcher_pid_file"
    kill_pid_file "$stream_pid_file"
    ${pkgs.coreutils}/bin/rm -f "$stream_pid_file" "$parser_pid_file" "$watcher_pid_file"
    update_status "${dictateIcon}" "Dictation idle" "idle"
    ${pkgs.libnotify}/bin/notify-send -t 2000 "Dictation stopped."
  '';

  dictateStart = pkgs.writeShellScriptBin "dictate-start" ''
    exec ${dictateStreamStart}/bin/dictate-stream-start
  '';

  dictateStop = pkgs.writeShellScriptBin "dictate-stop" ''
    exec ${dictateStreamStop}/bin/dictate-stream-stop
  '';

  dictateCancel = pkgs.writeShellScriptBin "dictate-cancel" ''
    set -u

    runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}/dictate"
    record_pid_file="$runtime_dir/record.pid"
    transcribe_pid_file="$runtime_dir/transcribe.pid"
    stream_pid_file="$runtime_dir/stream.pid"
    parser_pid_file="$runtime_dir/parser.pid"
    watcher_pid_file="$runtime_dir/watcher.pid"
    status_file="$runtime_dir/status.json"

    kill_tree() {
      pid="$1"
      ${pkgs.procps}/bin/kill -0 "$pid" >/dev/null 2>&1 || return 0
      for child in $(${pkgs.procps}/bin/pgrep -P "$pid" 2>/dev/null || true); do
        kill_tree "$child"
      done
      ${pkgs.procps}/bin/kill "$pid" >/dev/null 2>&1 || true
    }

    kill_pid_file() {
      pid_file="$1"
      if [ -s "$pid_file" ]; then
        kill_tree "$(${pkgs.coreutils}/bin/cat "$pid_file")"
      fi
    }

    ${pkgs.coreutils}/bin/mkdir -p "$runtime_dir"
    kill_pid_file "$record_pid_file"
    kill_pid_file "$transcribe_pid_file"
    kill_pid_file "$stream_pid_file"
    ${pkgs.coreutils}/bin/sleep 0.7
    kill_pid_file "$parser_pid_file"
    kill_pid_file "$watcher_pid_file"
    kill_pid_file "$stream_pid_file"
    ${pkgs.coreutils}/bin/rm -f "$runtime_dir"/audio.wav "$runtime_dir"/transcript.txt "$runtime_dir"/*.log "$runtime_dir"/stream.out "$record_pid_file" "$transcribe_pid_file" "$stream_pid_file" "$parser_pid_file" "$watcher_pid_file"
    ${pkgs.jq}/bin/jq -cn \
      --arg text "${dictateIcon}" \
      --arg tooltip "Dictation idle" \
      --arg class "idle" \
      '{text: $text, tooltip: $tooltip, class: $class}' > "$status_file"
    ${pkgs.libnotify}/bin/notify-send -t 2000 "Dictation canceled."
  '';

  dictateToggle = pkgs.writeShellScriptBin "dictate-toggle" ''
    set -u

    runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}/dictate"
    stream_pid_file="$runtime_dir/stream.pid"
    parser_pid_file="$runtime_dir/parser.pid"
    watcher_pid_file="$runtime_dir/watcher.pid"

    if [ -s "$stream_pid_file" ] && ${pkgs.procps}/bin/kill -0 "$(${pkgs.coreutils}/bin/cat "$stream_pid_file")" >/dev/null 2>&1; then
      exec ${dictateStreamStop}/bin/dictate-stream-stop
    fi

    if [ -s "$parser_pid_file" ] && ${pkgs.procps}/bin/kill -0 "$(${pkgs.coreutils}/bin/cat "$parser_pid_file")" >/dev/null 2>&1; then
      exec ${dictateStreamStop}/bin/dictate-stream-stop
    fi

    if [ -s "$watcher_pid_file" ] && ${pkgs.procps}/bin/kill -0 "$(${pkgs.coreutils}/bin/cat "$watcher_pid_file")" >/dev/null 2>&1; then
      exec ${dictateStreamStop}/bin/dictate-stream-stop
    fi

    exec ${dictateStreamStart}/bin/dictate-stream-start
  '';

  dictateModelInstall = pkgs.writeShellScriptBin "dictate-model-install" ''
    set -eu

    model_dir="$HOME/.local/share/whisper/models"
    model_file="$model_dir/ggml-base.en.bin"
    model_url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"

    ${pkgs.coreutils}/bin/mkdir -p "$model_dir"

    if [ -s "$model_file" ]; then
      printf '%s\n' "Model already installed: $model_file"
      exit 0
    fi

    ${pkgs.curl}/bin/curl -L --fail --progress-bar -o "$model_file.tmp" "$model_url"
    ${pkgs.coreutils}/bin/mv "$model_file.tmp" "$model_file"
    printf '%s\n' "Installed model: $model_file"
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
    inputs.ags.homeManagerModules.default
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
      GTK_THEME = gtkThemeEnv;
    };
    packages = with pkgs; [
      airpodsConnect
      airpodsDisconnect
      bat
      bitwarden-cli
      brightnessctl
      calibre
      claude-code
      codex
      dictateCancel
      dictateModelInstall
      dictateStart
      dictateStatus
      dictateStop
      dictateStreamStart
      dictateStreamStop
      dictateToggle
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
      swayWorkspaceState
      taskwarrior3
      toggleCapsEscape
      waybarGammastepToggle
      waybarGammastepStatus
      whisper-cpp
      wtype
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
        ".local/share/whisper"
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
      theme = theme.variant;
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
    **/.mcp.json
    **/.claude/
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
    user_pref("ui.systemUsesDarkTheme", ${toString firefoxDarkMode});
  '';

  home.pointerCursor = {
    enable = true;
    package = pkgs.vanilla-dmz;
    name = "DMZ-Black";
    size = 20;
    gtk.enable = true;
    x11.enable = true;
  };

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface" = {
      color-scheme = gtkColorScheme;
      gtk-theme = gtkThemeName;
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = gtkThemeName;
      package = pkgs.gnome-themes-extra;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = isDark;
    gtk4.theme = null;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = isDark;
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
    settings = {
      "github.com" = config.lib.dag.entryBefore [ "wildcardIdentity" ] {
        User = "git";
        IdentityFile = "~/.ssh/git@github.com";
        IdentitiesOnly = true;
      };

      "bitbucket.org" = config.lib.dag.entryBefore [ "wildcardIdentity" ] {
        User = "git";
        IdentityFile = "~/.ssh/git@bitbucket.org";
        IdentitiesOnly = true;
      };

      wildcardIdentity =
        config.lib.dag.entryAfter
          [
            "github.com"
            "bitbucket.org"
          ]
          {
            header = "Host * !*.sftp.wpengine.com !lab-core !lab-core-ts";
            IdentityFile = "~/.ssh/%r@%h";
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

  home.activation.refreshThemeSession = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    run ${refreshThemeSession}/bin/drew-refresh-theme-session
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
      ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
      Type = "exec";
    };
  };

  programs.lazygit.enable = true;

  programs.ags = {
    enable = true;
    configDir = agsConfig;
    systemd.enable = true;
    extraPackages =
      with inputs.astal.packages.${pkgs.stdenv.hostPlatform.system};
      [
        battery
        bluetooth
        brightness
        network
        wireplumber
      ]
      ++ (with pkgs; [
        bash
        brightnessctl
        coreutils
        gawk
        gammastep
        gnused
        iproute2
        jq
        procps
        pulseaudio
        sway
        systemd
        wireplumber
      ]);
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "yy";
  };

  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  systemd.user.services.gnome-keyring.Service.ExecStart = lib.mkForce (
    "/run/wrappers/bin/gnome-keyring-daemon --start --foreground --components=secrets"
  );

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
      "containers/systemd/local-proxy.network".text = ''
        [Network]
        NetworkName=local-proxy
      '';
      "containers/systemd/traefik-local-proxy.container".text = ''
        [Unit]
        Description=Rootless Traefik local development proxy
        Requires=podman.socket local-proxy.network
        After=podman.socket local-proxy.network

        [Container]
        Image=docker.io/library/traefik:v3.7
        ContainerName=traefik-local-proxy
        Network=local-proxy.network
        PublishPort=127.0.0.1:80:80
        Volume=%t/podman/podman.sock:/var/run/docker.sock
        Exec=--entrypoints.web.address=:80 --providers.docker=true --providers.docker.endpoint=unix:///var/run/docker.sock --providers.docker.exposedbydefault=false --providers.docker.network=local-proxy --log.level=INFO

        [Service]
        Restart=on-failure
        RestartSec=2s
        TimeoutStartSec=900

        [Install]
        WantedBy=default.target
      '';
      "htop/htoprc".source = ./config/htop/htoprc;
      "mako/config".text = theme.makoConfig;
      "sway/config".text =
        builtins.replaceStrings
          [
            "output * bg $HOME/.local/share/wallpapers/white.jpg fill"
            "include $HOME/.config/sway/config.local"
            "bindsym $mod+t exec dictate-toggle"
            "bar {\n    swaybar_command waybar\n}"
          ]
          [
            "# Wallpaper is applied after config.local so output geometry is already set."
            "include $HOME/.config/sway/config.local\n${swayWallpaperConfig}"
            "bindsym $mod+t exec ${dictateToggle}/bin/dictate-toggle"
            "# Top bar is provided by AGS."
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
