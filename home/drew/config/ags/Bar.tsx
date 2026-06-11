import { For, With, createBinding, createState, onCleanup } from "ags"
import app from "ags/gtk4/app"
import { createSubprocess, exec, execAsync } from "ags/process"
import { createPoll } from "ags/time"
import Astal from "gi://Astal?version=4.0"
import AstalNetwork from "gi://AstalNetwork"
import AstalWp from "gi://AstalWp"
import Gdk from "gi://Gdk?version=4.0"
import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"

type AudioDevice = {
  name: string
  description: string
  active: boolean
}

type WifiNetwork = {
  ssid: string
  locked: boolean
  connected: boolean
}

type StatusJson = {
  text?: string
  tooltip?: string
  class?: string
}

type WorkspaceSlot = {
  num: number
  active?: boolean
  visible?: boolean
  focused?: boolean
  current_workspace?: boolean
  non_empty?: boolean
  urgent?: boolean
}

const sh = (cmd: string) => `bash -lc ${JSON.stringify(cmd)}`
const profileBin = "/etc/profiles/per-user/drew/bin"
const command = (name: string) => `${profileBin}/${name}`
const dictateIcon = ""
const iwdStationPath = "busctl tree net.connman.iwd 2>/dev/null | awk '/\\/net\\/connman\\/iwd\\/[0-9]+\\/[0-9]+$/ { print $NF; exit }'"

const run = async (cmd: string) => {
  try {
    await execAsync(sh(cmd))
  } catch (error) {
    console.error(error)
  }
}

const parseArray = <T,>(raw: string): Array<T> => {
  try {
    const value = JSON.parse(raw)
    return Array.isArray(value) ? value : []
  } catch {
    return []
  }
}

const parseStatus = (raw: string): StatusJson => {
  try {
    return JSON.parse(raw)
  } catch {
    return {}
  }
}

const latestLine = (raw: string) => {
  const lines = raw.trim().split("\n").filter(Boolean)
  return lines.length > 0 ? lines[lines.length - 1] : "[]"
}

function ToolButton({
  className,
  label,
  children,
}: {
  className?: string
  label: any
  children: JSX.Element
}) {
  return (
    <menubutton class={`tool ${className ?? ""}`}>
      <label label={label} />
      <popover>
        <box class="popover" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
          {children}
        </box>
      </popover>
    </menubutton>
  )
}

function Row({
  label,
  value,
}: {
  label: string
  value: any
}) {
  return (
    <box class="row" spacing={10}>
      <label class="row-label" xalign={0} label={label} />
      <label class="row-value" xalign={1} hexpand label={value} />
    </box>
  )
}

function Workspaces({ connector }: { connector: string }) {
  const workspaces = createSubprocess(
    "[]",
    [command("sway-workspace-state"), connector],
    (raw) => latestLine(raw),
  )

  return (
    <box class="workspaces" spacing={2}>
      <For
        each={workspaces((raw) => parseArray<WorkspaceSlot>(raw))}
        id={(workspace) =>
          `${workspace.num}-${workspace.focused ? "focused" : "unfocused"}-${workspace.non_empty ? "non-empty" : "empty"}`
        }
      >
        {(workspace) => {
          const className = [
            "workspace",
            workspace.focused ? "focused" : "",
            workspace.non_empty ? "non-empty" : "",
            workspace.urgent ? "urgent" : "",
          ].filter(Boolean).join(" ")

          return (
            <button
              class={className}
              onClicked={() => run(`swaymsg workspace number ${workspace.num}`)}
            >
              <label label={`${workspace.num}`} />
            </button>
          )
        }}
      </For>
    </box>
  )
}

function Clock() {
  const time = createPoll("", 1000, () => GLib.DateTime.new_now_local().format("%a %b %d %H:%M:%S")!)

  return (
    <menubutton class="clock">
      <label label={time} />
      <popover>
        <box class="popover">
          <Gtk.Calendar />
        </box>
      </popover>
    </menubutton>
  )
}

function Audio() {
  const wp = AstalWp.get_default()
  const speaker = wp?.defaultSpeaker
  const sinks = createPoll(
    "[]",
    2000,
    sh(
      "default=$(pactl get-default-sink 2>/dev/null || true); pactl -f json list sinks 2>/dev/null | jq -c --arg default \"$default\" '[.[] | select(.name != null) | {name, description: (.description // .properties[\"device.description\"] // .name), active: (.name == $default)}]'",
    ),
  )
  const sources = createPoll(
    "[]",
    2000,
    sh(
      "default=$(pactl get-default-source 2>/dev/null || true); pactl -f json list sources 2>/dev/null | jq -c --arg default \"$default\" '[.[] | select(.name != null) | select((.name | endswith(\".monitor\")) | not) | {name, description: (.description // .properties[\"device.description\"] // .name), active: (.name == $default)}]'",
    ),
  )

  const outputMute = createPoll("no", 500, sh("wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q '\\[MUTED\\]' && printf yes || printf no"))
  const inputMute = createPoll("no", 500, sh("wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q '\\[MUTED\\]' && printf yes || printf no"))
  const label = createPoll(
    "󰕾",
    500,
    sh("state=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true); volume=$(printf '%s' \"$state\" | awk '{ printf \"%d\", $2 * 100 }'); if printf '%s' \"$state\" | grep -q '\\[MUTED\\]'; then printf '󰖁'; elif [ \"${volume:-0}\" -lt 34 ]; then printf '󰕿'; elif [ \"${volume:-0}\" -lt 67 ]; then printf '󰖀'; else printf '󰕾'; fi"),
  )
  const speakerVolume = speaker ? createBinding(speaker, "volume") : 0

  return (
    <ToolButton className="audio" label={label}>
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <label class="section-title" xalign={0} label="Output" />
        <box spacing={8}>
          <button
            class={outputMute((mute) => (mute === "yes" ? "choice active" : "choice"))}
            onClicked={() => run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")}
          >
            <label label="Mute" />
          </button>
          <slider
            hexpand
            widthRequest={220}
            value={speakerVolume as any}
            onChangeValue={({ value }) => speaker?.set_volume(value)}
          />
        </box>
        <For each={sinks((raw) => parseArray<AudioDevice>(raw))}>
          {(sink) => (
            <button class={sink.active ? "choice active" : "choice"} onClicked={() => run(`pactl set-default-sink ${JSON.stringify(sink.name)}`)}>
              <label xalign={0} label={`${sink.active ? "* " : ""}${sink.description}`} />
            </button>
          )}
        </For>

        <label class="section-title" xalign={0} label="Input" />
        <box spacing={8}>
          <button
            class={inputMute((mute) => (mute === "yes" ? "choice active" : "choice"))}
            onClicked={() => run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")}
          >
            <label label="Mute" />
          </button>
          <label label="Default source" />
        </box>
        <For each={sources((raw) => parseArray<AudioDevice>(raw))}>
          {(source) => (
            <button class={source.active ? "choice active" : "choice"} onClicked={() => run(`pactl set-default-source ${JSON.stringify(source.name)}`)}>
              <label xalign={0} label={`${source.active ? "* " : ""}${source.description}`} />
            </button>
          )}
        </For>
      </box>
    </ToolButton>
  )
}

function Network() {
  const network = AstalNetwork.get_default()
  const wifi = network ? createBinding(network, "wifi") : null
  const icon = createPoll(
    "󰤨",
    2000,
    sh("if ! ip -brief addr show scope global | grep -q .; then printf '󰤭'; elif ip -brief addr show scope global | awk '{print $1}' | grep -Eq '^(en|eth)'; then printf '󰈀'; else printf '󰤨'; fi"),
  )
  const status = createPoll(
    "Disconnected",
    10000,
    sh("ip -brief addr show scope global | awk '{print $1\": \"$3}' | paste -sd '\\n' - || true"),
  )
  const networks = createPoll(
    "[]",
    10000,
    sh(`station=$(${iwdStationPath}); if [ -z "$station" ]; then printf '[]'; exit 0; fi; busctl --json=short call net.connman.iwd "$station" net.connman.iwd.Station GetOrderedNetworks 2>/dev/null | jq -r '.data[0][][0]' | head -n 8 | while IFS= read -r path; do name=$(busctl --json=short get-property net.connman.iwd "$path" net.connman.iwd.Network Name 2>/dev/null | jq -r '.data // empty'); type=$(busctl --json=short get-property net.connman.iwd "$path" net.connman.iwd.Network Type 2>/dev/null | jq -r '.data // empty'); connected=$(busctl --json=short get-property net.connman.iwd "$path" net.connman.iwd.Network Connected 2>/dev/null | jq -r '.data // false'); [ -n "$name" ] && jq -cn --arg ssid "$name" --arg type "$type" --argjson connected "$connected" '{ssid: $ssid, locked: ($type != "open"), connected: $connected}'; done | jq -s -c '.'`),
  )

  return (
    <ToolButton className="network" label={icon}>
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <Row label="Status" value={status} />
        <With value={wifi as any}>
          {(w: any) =>
            w && (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
                <Row label="SSID" value={w.ssid || "Unknown"} />
                <Row label="Signal" value={`${w.strength ?? 0}%`} />
              </box>
            )
          }
        </With>
        <button onClicked={() => run(`station=$(${iwdStationPath}); [ -n "$station" ] && busctl call net.connman.iwd "$station" net.connman.iwd.Station Scan`)}>
          <label label="Scan Wi-Fi" />
        </button>
        <For each={networks((raw) => parseArray<WifiNetwork>(raw))}>
          {(network) => (
            <box class={network.connected ? "network-row active" : "network-row"} spacing={8}>
              <label class="network-lock" label={network.locked ? "" : ""} />
              <label hexpand xalign={0} ellipsize={3} label={network.ssid} />
            </box>
          )}
        </For>
      </box>
    </ToolButton>
  )
}

function Power() {
  const icon = createPoll(
    "󰁹",
    10000,
    sh("ac=$(cat /sys/class/power_supply/AC/online 2>/dev/null || printf 0); capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || printf 100); if [ \"$ac\" = 1 ]; then printf '󰚥'; elif [ \"$capacity\" -le 15 ]; then printf '󰁺'; elif [ \"$capacity\" -le 30 ]; then printf '󰁼'; elif [ \"$capacity\" -le 55 ]; then printf '󰁾'; elif [ \"$capacity\" -le 80 ]; then printf '󰂀'; else printf '󰁹'; fi"),
  )
  const details = createPoll(
    "",
    30000,
    sh("printf 'Status: '; cat /sys/class/power_supply/BAT0/status 2>/dev/null || true; printf 'Capacity: '; cat /sys/class/power_supply/BAT0/capacity 2>/dev/null | sed 's/$/%/' || true"),
  )

  return (
    <ToolButton className="power" label={icon}>
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <Row label="Battery" value={details} />
        <Row label="AC" value={createPoll("", 30000, sh("cat /sys/class/power_supply/AC/online 2>/dev/null | sed 's/1/connected/;s/0/disconnected/' || true"))} />
      </box>
    </ToolButton>
  )
}

function Display() {
  const brightness = createPoll(
    "0",
    2000,
    sh("awk '{ cur=$1 } FNR==NR { max=$1; next } END { if (max > 0) printf \"%d\", cur * 100 / max }' /sys/class/backlight/intel_backlight/max_brightness /sys/class/backlight/intel_backlight/brightness"),
  )
  const gammastep = createPoll("{}", 10000, command("waybar-gammastep-status"))

  return (
    <ToolButton className="display" label="󰍹">
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <label class="section-title" xalign={0} label="Brightness" />
        <slider
          widthRequest={260}
          value={brightness((b) => Number(b) / 100)}
          onChangeValue={({ value }) => run(`brightnessctl set ${Math.round(value * 100)}% || true`)}
        />
        <With value={gammastep(parseStatus)}>
          {(status) => (
            <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              <Row label="Gammastep" value={status.tooltip ?? "Unknown"} />
              <button onClicked={() => run(command("waybar-gammastep-toggle"))}>
                <label label="Toggle Gammastep" />
              </button>
            </box>
          )}
        </With>
      </box>
    </ToolButton>
  )
}

function Performance() {
  const cpu = createPoll("0%", 3000, sh("top -bn1 | awk '/Cpu\\(s\\)/ { printf \"%d%%\", 100 - $8 }'"))
  const memory = createPoll("0%", 5000, sh("free | awk '/Mem:/ { printf \"%d%%\", $3 * 100 / $2 }'"))
  const temp = createPoll("", 5000, sh("for t in /sys/class/thermal/thermal_zone*/temp; do awk '{ printf \"%d°C\", $1 / 1000 }' \"$t\"; break; done"))

  return (
    <ToolButton className="performance" label="󰓅">
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <Row label="CPU" value={cpu} />
        <Row label="Memory" value={memory} />
        <Row label="Temperature" value={temp} />
      </box>
    </ToolButton>
  )
}

function Session() {
  const idle = createPoll(
    "false",
    2000,
    sh("pgrep -f 'systemd-inhibit.*AGS keep awake' >/dev/null && printf true || printf false"),
  )
  const [pending, setPending] = createState("")
  const toggleIdle = () =>
    run(
      "if pgrep -f 'systemd-inhibit.*AGS keep awake' >/dev/null; then pkill -f 'systemd-inhibit.*AGS keep awake'; else systemd-inhibit --what=idle:sleep --who=ags --why='AGS keep awake' sleep infinity >/dev/null 2>&1 & fi",
    )
  const confirm = (action: string, command: string) => {
    if (pending() === action) {
      setPending("")
      run(command)
    } else {
      setPending(action)
    }
  }

  return (
    <ToolButton className="session" label="󰍃">
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <button
          class={idle((enabled) => (enabled === "true" ? "choice active" : "choice"))}
          onClicked={toggleIdle}
        >
          <label label={idle((enabled) => (enabled === "true" ? "Disable keep awake" : "Enable keep awake"))} />
        </button>
        <button onClicked={() => run(command("lock-screen"))}>
          <label label="Lock" />
        </button>
        <button onClicked={() => confirm("reboot", "systemctl reboot")}>
          <label label={pending((value) => (value === "reboot" ? "Confirm reboot" : "Reboot"))} />
        </button>
        <button class="danger" onClicked={() => confirm("shutdown", "systemctl poweroff")}>
          <label label={pending((value) => (value === "shutdown" ? "Confirm shutdown" : "Shutdown"))} />
        </button>
      </box>
    </ToolButton>
  )
}

function Dictation() {
  const status = createPoll("{}", 1000, command("dictate-status"))
  const label = status((raw) => {
    const klass = parseStatus(raw).class ?? "idle"
    switch (klass) {
      case "listening":
        return "󰍬"
      case "transcribing":
        return "󰔊"
      case "typing":
        return ""
      case "error":
        return ""
      default:
        return dictateIcon
    }
  })
  const klass = status((raw) => `dictation ${parseStatus(raw).class ?? "idle"}`)
  const tooltip = status((raw) => parseStatus(raw).tooltip ?? "Dictation idle")

  return (
    <button class={klass} tooltipText={tooltip} onClicked={() => run(command("dictate-cancel"))}>
      <label label={label} />
    </button>
  )
}

export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  let win: Astal.Window
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  onCleanup(() => {
    win.destroy()
  })

  return (
    <window
      $={(self) => (win = self)}
      visible
      namespace="drew-top-bar"
      name={`bar-${gdkmonitor.connector}`}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox class="bar">
        <box $type="start" class="left" spacing={0}>
          <Workspaces connector={gdkmonitor.connector} />
        </box>
        <box $type="center" class="center">
          <Clock />
        </box>
        <box $type="end" class="right" spacing={0}>
          <Dictation />
          <Network />
          <Audio />
          <Display />
          <Performance />
          <Session />
          <Power />
        </box>
      </centerbox>
    </window>
  )
}
