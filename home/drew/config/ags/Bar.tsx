import { For, Fragment, With, createBinding, createState, onCleanup } from "ags"
import app from "ags/gtk4/app"
import { exec, execAsync, subprocess } from "ags/process"
import { createPoll } from "ags/time"
import Astal from "gi://Astal?version=4.0"
import AstalBluetooth from "gi://AstalBluetooth"
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

type BluetoothDevice = {
  name: string
  connected: boolean
}

type StatusJson = {
  text?: string
  tooltip?: string
  class?: string
}

type WorkspaceSlot = {
  num: number
  name: string
  active?: boolean
  visible?: boolean
  focused?: boolean
  current_workspace?: boolean
  non_empty?: boolean
  urgent?: boolean
}

type SwayOutput = {
  name?: string
  active?: boolean
}

type SwayWorkspace = {
  num?: number
  name?: string
  output?: string
  visible?: boolean
  focused?: boolean
  urgent?: boolean
  representation?: string
}

type SwayState = {
  outputs: Array<SwayOutput>
  workspaces: Array<SwayWorkspace>
}

type PopupName = "" | "clock" | "network" | "bluetooth" | "audio" | "display" | "performance" | "session" | "power" | "dictation"

const sh = (cmd: string) => `bash -lc ${JSON.stringify(cmd)}`
const profileBin = "/etc/profiles/per-user/drew/bin"
const command = (name: string) => `${profileBin}/${name}`
const dictateIcon = ""
const iwdStationPath = "busctl tree net.connman.iwd 2>/dev/null | awk '/\\/net\\/connman\\/iwd\\/[0-9]+\\/[0-9]+$/ { print $NF; exit }'"
const bluetoothDevicesCommand =
  "objects=$(busctl --json=short call org.bluez / org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null || true); if [ -z \"$objects\" ]; then printf '[]'; else printf '%s' \"$objects\" | jq -c '[.data[0] | to_entries[] | select(.value[\"org.bluez.Device1\"] != null) | .value[\"org.bluez.Device1\"] as $device | select(($device.Connected.data // $device.Connected // false) == true) | {name: (($device.Alias.data // $device.Alias // $device.Name.data // $device.Name // \"Bluetooth device\") | tostring), connected: true}]' 2>/dev/null || printf '[]'; fi"
const bluetoothConnectedCommand =
  `${bluetoothDevicesCommand} | jq -e 'length > 0' >/dev/null && printf yes || printf no`
const defaultSinkCommand =
  "wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F ' = ' '/node.description|node.nick|node.name/ { gsub(/^\"|\"$/, \"\", $2); print $2; found=1; exit } END { if (!found) printf \"Unknown\" }'"
const defaultSourceCommand =
  "wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk -F ' = ' '/node.description|node.nick|node.name/ { gsub(/^\"|\"$/, \"\", $2); print $2; found=1; exit } END { if (!found) printf \"Unknown\" }'"
const keepAwakeUnit = "drew-ags-keep-awake.service"
const keepAwakeStatusCommand = `systemctl --user is-active --quiet ${keepAwakeUnit} && printf true || printf false`
const keepAwakeToggleCommand =
  `if systemctl --user is-active --quiet ${keepAwakeUnit}; then systemctl --user stop ${keepAwakeUnit}; else systemd-run --user --unit=drew-ags-keep-awake --property=Type=exec --property=Description='AGS keep awake inhibitor' --collect systemd-inhibit --what=idle:sleep --who=ags --why='AGS keep awake' sleep infinity; fi`

void AstalBluetooth

const run = async (cmd: string) => {
  try {
    await execAsync(sh(cmd))
  } catch (error) {
    console.error(`Command failed: ${cmd}`, error)
  }
}

const monitorName = (monitor: Gdk.Monitor) => {
  const geometry = monitor.geometry
  const geometryName = `${geometry.x},${geometry.y}-${geometry.width}x${geometry.height}`

  switch (geometryName) {
    case "0,0-1920x1200":
      return "eDP-1"
    case "1920,0-1920x1080":
      return "HDMI-A-1"
    case "3840,0-1920x1080":
      return "DP-2"
    default:
      return monitor.connector || geometryName
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

const [anyPopupOpen, setAnyPopupOpen] = createState(false)
const [swayState, setSwayState] = createState<SwayState>({ outputs: [], workspaces: [] })
const dictationStatus = createPoll("{}", 1000, command("dictate-status"))
const closePopupCallbacks = new Set<() => void>()
let swayEvents: ReturnType<typeof subprocess> | null = null
let swayRefreshPending = false
let swayRefreshQueued = false
let lastSwayState = ""

const closeAllPopups = () => {
  for (const close of closePopupCallbacks) {
    close()
  }
  setAnyPopupOpen(false)
}

const workspaceSlots: Record<string, Array<number>> = {
  "eDP-1": [1, 4, 7, 10],
  "HDMI-A-1": [2, 5, 8],
  "DP-2": [3, 6, 9],
}

const slotOutput = (num: number) => {
  if ([1, 4, 7, 10].includes(num)) return "eDP-1"
  if ([2, 5, 8].includes(num)) return "HDMI-A-1"
  return "DP-2"
}

const workspacesForConnector = ({ outputs, workspaces }: SwayState, connector: string) => {
  const slots = workspaceSlots[connector] ?? []
  const activeOutputs = outputs.filter((output) => output.active).map((output) => output.name).filter(Boolean)
  const firstActiveOutput = activeOutputs[0] ?? connector
  const nums = Array.from(new Set([...slots, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])).sort((a, b) => a - b)

  return nums.flatMap((num): Array<WorkspaceSlot> => {
    const output = slotOutput(num)
    const slotOutputActive = activeOutputs.includes(output)
    if (output !== connector && (slotOutputActive || connector !== firstActiveOutput)) return []

    const workspace = workspaces.find((item) => item.num === num && (item.output === connector || item.output === output))
    const active = Boolean(workspace?.visible)
    const nonEmpty = Boolean(workspace && (workspace.representation ?? "") !== "")
    if (!active && !nonEmpty) return []

    return [{
      num,
      name: workspace?.name ?? `${num}`,
      active,
      visible: workspace?.visible ?? false,
      focused: workspace?.focused ?? false,
      urgent: workspace?.urgent ?? false,
      current_workspace: active,
      non_empty: nonEmpty,
    }]
  })
}

const refreshSwayState = async () => {
  if (swayRefreshPending) {
    swayRefreshQueued = true
    return
  }
  swayRefreshPending = true

  try {
    const [outputsRaw, workspacesRaw] = await Promise.all([
      execAsync(sh("swaymsg -t get_outputs 2>/dev/null || printf '[]'")),
      execAsync(sh("swaymsg -t get_workspaces 2>/dev/null || printf '[]'")),
    ])
    const next = {
      outputs: parseArray<SwayOutput>(outputsRaw),
      workspaces: parseArray<SwayWorkspace>(workspacesRaw),
    }
    const nextJson = JSON.stringify(next)

    if (nextJson !== lastSwayState) {
      lastSwayState = nextJson
      setSwayState(next)
    }
  } catch (error) {
    console.error("Failed to refresh sway state", error)
  } finally {
    swayRefreshPending = false
    if (swayRefreshQueued) {
      swayRefreshQueued = false
      void refreshSwayState()
    }
  }
}

const ensureSwayState = () => {
  if (swayEvents) return

  void refreshSwayState()
  swayEvents = subprocess(
    sh("swaymsg -m -t subscribe '[\"workspace\",\"window\",\"output\"]' 2>/dev/null || true"),
    (raw) => {
      const events = raw.trim().split("\n").filter(Boolean)
      const shouldClosePopups = events.some((line) => {
        try {
          const event = JSON.parse(line)
          return event.change != null && (event.container != null || event.current != null)
        } catch {
          return false
        }
      })

      if (shouldClosePopups) {
        closeAllPopups()
      }

      void refreshSwayState()
    },
    (error) => {
      console.error("Sway event subscription failed", error)
      swayEvents = null
    },
  )
}

function ToolButton({
  name,
  className,
  label,
  popup,
  setPopup,
}: {
  name: PopupName
  className?: string
  label: any
  popup: any
  setPopup: (popup: PopupName) => void
}) {
  return (
    <button
      class={popup((active: PopupName) =>
        ["tool", className ?? "", active === name ? "active" : ""].filter(Boolean).join(" ")
      )}
      onClicked={() => setPopup(popup() === name ? "" : name)}
    >
      <label label={label} />
    </button>
  )
}

function Row({
  label,
  value,
  valueMaxWidthChars = 80,
}: {
  label: string
  value: any
  valueMaxWidthChars?: number
}) {
  return (
    <box class="row" spacing={10}>
      <label class="row-label" xalign={0} label={label} />
      <label class="row-value" xalign={1} hexpand ellipsize={3} maxWidthChars={valueMaxWidthChars} label={value} />
    </box>
  )
}

function Workspaces({ connector }: { connector: string }) {
  ensureSwayState()

  return (
    <box class="workspaces" spacing={2}>
      <For
        each={swayState((state) => workspacesForConnector(state, connector))}
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

type PopupProps = {
  popup: any
  setPopup: (popup: PopupName) => void
}

function Clock({ popup, setPopup }: PopupProps) {
  const time = createPoll("", 1000, () => GLib.DateTime.new_now_local().format("%a %b %d %H:%M:%S")!)

  return <ToolButton name="clock" className="clock" label={time} popup={popup} setPopup={setPopup} />
}

function ClockContent() {
  return <Gtk.Calendar />
}

function AudioButton({ popup, setPopup }: PopupProps) {
  const label = createPoll(
    "󰕾",
    500,
    sh("state=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true); volume=$(printf '%s' \"$state\" | awk '{ printf \"%d\", $2 * 100 }'); if printf '%s' \"$state\" | grep -q '\\[MUTED\\]'; then printf '󰖁'; elif [ \"${volume:-0}\" -lt 34 ]; then printf '󰕿'; elif [ \"${volume:-0}\" -lt 67 ]; then printf '󰖀'; else printf '󰕾'; fi"),
  )

  return <ToolButton name="audio" className="audio" label={label} popup={popup} setPopup={setPopup} />
}

function AudioContent() {
  const wp = AstalWp.get_default()
  const speaker = wp?.defaultSpeaker
  const defaultSpeaker = wp ? createBinding(wp, "defaultSpeaker") : null
  const defaultMicrophone = wp ? createBinding(wp, "defaultMicrophone") : null
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
  const defaultSink = createPoll("Unknown", 2000, sh(defaultSinkCommand))
  const defaultSource = createPoll("Unknown", 2000, sh(defaultSourceCommand))
  const defaultSinkLabel = defaultSpeaker ? defaultSpeaker((device: any) => device?.description || defaultSink()) : defaultSink
  const defaultSourceLabel = defaultMicrophone ? defaultMicrophone((device: any) => device?.description || defaultSource()) : defaultSource
  const speakerVolume = speaker ? createBinding(speaker, "volume") : 0

  return (
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
      <Row label="Default" value={defaultSinkLabel} valueMaxWidthChars={32} />
      <For each={sinks((raw) => parseArray<AudioDevice>(raw))}>
        {(sink) => (
          <button class={sink.active ? "choice active" : "choice"} onClicked={() => run(`pactl set-default-sink ${JSON.stringify(sink.name)}`)}>
            <label xalign={0} ellipsize={3} maxWidthChars={34} label={`${sink.active ? "* " : ""}${sink.description}`} />
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
      </box>
      <Row label="Default" value={defaultSourceLabel} valueMaxWidthChars={32} />
      <For each={sources((raw) => parseArray<AudioDevice>(raw))}>
        {(source) => (
          <button class={source.active ? "choice active" : "choice"} onClicked={() => run(`pactl set-default-source ${JSON.stringify(source.name)}`)}>
            <label xalign={0} ellipsize={3} maxWidthChars={34} label={`${source.active ? "* " : ""}${source.description}`} />
          </button>
        )}
      </For>
    </box>
  )
}

function BluetoothButton({ popup, setPopup }: PopupProps) {
  const connected = createPoll(
    "no",
    5000,
    sh(bluetoothConnectedCommand),
  )
  const label = connected((state) => (state === "yes" ? "󰂱" : "󰂲"))

  return <ToolButton name="bluetooth" className="bluetooth" label={label} popup={popup} setPopup={setPopup} />
}

function BluetoothContent() {
  const devices = createPoll(
    "[]",
    5000,
    sh(bluetoothDevicesCommand),
  )
  const rows = devices((raw) => {
    const connectedDevices = parseArray<BluetoothDevice>(raw)
    return connectedDevices.length > 0 ? connectedDevices : [{ name: "No connected devices", connected: false }]
  })

  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <Row label="Status" value={rows((connectedDevices) => connectedDevices.some((device) => device.connected) ? "Connected" : "Disconnected")} />
      <label class="section-title" xalign={0} label="Connected devices" />
      <For each={rows}>
        {(device) => (
          <box class={device.connected ? "choice active readonly-choice" : "choice readonly-choice"} spacing={8}>
            <label xalign={0} ellipsize={3} label={device.name} />
          </box>
        )}
      </For>
    </box>
  )
}

function NetworkButton({ popup, setPopup }: PopupProps) {
  const icon = createPoll(
    "󰤨",
    2000,
    sh("if ! ip -brief addr show scope global | grep -q .; then printf '󰤭'; elif ip -brief addr show scope global | awk '{print $1}' | grep -Eq '^(en|eth)'; then printf '󰈀'; else printf '󰤨'; fi"),
  )

  return <ToolButton name="network" className="network" label={icon} popup={popup} setPopup={setPopup} />
}

function NetworkContent() {
  const network = AstalNetwork.get_default()
  const wifi = network ? createBinding(network, "wifi") : null
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
  )
}

function PowerButton({ popup, setPopup }: PopupProps) {
  const icon = createPoll(
    "󰁹",
    10000,
    sh("ac=$(cat /sys/class/power_supply/AC/online 2>/dev/null || printf 0); capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || printf 100); if [ \"$ac\" = 1 ]; then printf '󰚥'; elif [ \"$capacity\" -le 15 ]; then printf '󰁺'; elif [ \"$capacity\" -le 30 ]; then printf '󰁼'; elif [ \"$capacity\" -le 55 ]; then printf '󰁾'; elif [ \"$capacity\" -le 80 ]; then printf '󰂀'; else printf '󰁹'; fi"),
  )

  return <ToolButton name="power" className="power" label={icon} popup={popup} setPopup={setPopup} />
}

function PowerContent() {
  const details = createPoll(
    "",
    30000,
    sh("printf 'Status: '; cat /sys/class/power_supply/BAT0/status 2>/dev/null || true; printf 'Capacity: '; cat /sys/class/power_supply/BAT0/capacity 2>/dev/null | sed 's/$/%/' || true"),
  )

  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <Row label="Battery" value={details} />
      <Row label="AC" value={createPoll("", 30000, sh("cat /sys/class/power_supply/AC/online 2>/dev/null | sed 's/1/connected/;s/0/disconnected/' || true"))} />
    </box>
  )
}

function DisplayButton({ popup, setPopup }: PopupProps) {
  return <ToolButton name="display" className="display" label="󰍹" popup={popup} setPopup={setPopup} />
}

function DisplayContent() {
  const brightness = createPoll(
    "0",
    2000,
    sh("awk '{ cur=$1 } FNR==NR { max=$1; next } END { if (max > 0) printf \"%d\", cur * 100 / max }' /sys/class/backlight/intel_backlight/max_brightness /sys/class/backlight/intel_backlight/brightness"),
  )
  const gammastep = createPoll("{}", 10000, command("waybar-gammastep-status"))

  return (
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
  )
}

function PerformanceButton({ popup, setPopup }: PopupProps) {
  return <ToolButton name="performance" className="performance" label="󰓅" popup={popup} setPopup={setPopup} />
}

function PerformanceContent() {
  const cpu = createPoll("0%", 3000, sh("top -bn1 | awk '/Cpu\\(s\\)/ { printf \"%d%%\", 100 - $8 }'"))
  const memory = createPoll("0%", 5000, sh("free | awk '/Mem:/ { printf \"%d%%\", $3 * 100 / $2 }'"))
  const temp = createPoll("", 5000, sh("for t in /sys/class/thermal/thermal_zone*/temp; do awk '{ printf \"%d°C\", $1 / 1000 }' \"$t\"; break; done"))

  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <Row label="CPU" value={cpu} />
      <Row label="Memory" value={memory} />
      <Row label="Temperature" value={temp} />
    </box>
  )
}

function SessionButton({ popup, setPopup }: PopupProps) {
  return <ToolButton name="session" className="session" label="󰍃" popup={popup} setPopup={setPopup} />
}

function SessionContent() {
  const idle = createPoll(
    "false",
    2000,
    sh(keepAwakeStatusCommand),
  )
  const [pending, setPending] = createState("")
  const toggleIdle = () => run(keepAwakeToggleCommand)
  const confirm = (action: string, command: string) => {
    if (pending() === action) {
      setPending("")
      run(command)
    } else {
      setPending(action)
    }
  }

  return (
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
  )
}

const dictationStateLabel = (klass: string) => {
  switch (klass) {
    case "listening":
      return "Listening"
    case "transcribing":
      return "Transcribing"
    case "typing":
      return "Typing"
    case "stopping":
      return "Stopping"
    case "error":
      return "Error"
    default:
      return "Idle"
  }
}

const dictationIsActive = (klass: string) => ["listening", "transcribing", "typing", "stopping"].includes(klass)
const dictationOverlayVisible = (klass: string) => ["listening", "transcribing", "typing", "stopping", "error"].includes(klass)

const dictationStateIcon = (klass: string) => {
  switch (klass) {
    case "listening":
      return "󰍬"
    case "transcribing":
      return "󰔊"
    case "typing":
      return ""
    case "stopping":
      return ""
    case "error":
      return ""
    default:
      return dictateIcon
  }
}

function DictationButton({ popup, setPopup }: PopupProps) {
  const label = dictationStatus((raw) => {
    const klass = parseStatus(raw).class ?? "idle"
    return dictationStateIcon(klass)
  })
  const klass = dictationStatus((raw) => {
    const state = parseStatus(raw).class ?? "idle"
    return ["tool", "dictation", state, popup() === "dictation" ? "active" : ""].filter(Boolean).join(" ")
  })
  const tooltip = dictationStatus((raw) => parseStatus(raw).tooltip ?? "Dictation idle")

  return (
    <button class={klass} tooltipText={tooltip} onClicked={() => setPopup(popup() === "dictation" ? "" : "dictation")}>
      <label label={label} />
    </button>
  )
}

function DictationOverlay({ connector, gdkmonitor }: { connector: string; gdkmonitor: Gdk.Monitor }) {
  const { TOP } = Astal.WindowAnchor
  const visible = dictationStatus((raw) => dictationOverlayVisible(parseStatus(raw).class ?? "idle"))
  const klass = dictationStatus((raw) => `dictation-overlay ${parseStatus(raw).class ?? "idle"}`)
  const icon = dictationStatus((raw) => dictationStateIcon(parseStatus(raw).class ?? "idle"))
  const label = dictationStatus((raw) => dictationStateLabel(parseStatus(raw).class ?? "idle"))
  const detail = dictationStatus((raw) => parseStatus(raw).tooltip ?? "Dictation idle")

  return (
    <window
      visible={visible}
      namespace="drew-dictation-overlay"
      name={`dictation-overlay-${connector}`}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.NONE}
      anchor={TOP}
      margin_top={42}
      application={app}
    >
      <box class={klass} spacing={10}>
        <label class="dictation-overlay-icon" label={icon} />
        <box orientation={Gtk.Orientation.VERTICAL} spacing={1}>
          <label class="dictation-overlay-label" xalign={0} label={label} />
          <label class="dictation-overlay-detail" xalign={0} label={detail} />
        </box>
      </box>
    </window>
  )
}

function DictationContent() {
  const stateClass = dictationStatus((raw) => parseStatus(raw).class ?? "idle")
  const stateLabel = stateClass(dictationStateLabel)
  const details = dictationStatus((raw) => parseStatus(raw).tooltip ?? "Dictation idle")

  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <box class={stateClass((klass) => `dictation-state ${klass}`)} orientation={Gtk.Orientation.VERTICAL} spacing={2}>
        <label class="dictation-state-label" xalign={0} label={stateLabel} />
        <label class="dictation-state-detail" xalign={0} wrap label={details} />
      </box>
      <button
        class={stateClass((klass) => (dictationIsActive(klass) ? "choice active" : "choice"))}
        onClicked={() => run(command("dictate-toggle"))}
      >
        <label label={stateClass((klass) => (dictationIsActive(klass) ? "Stop recording" : "Start recording"))} />
      </button>
    </box>
  )
}

function PopupWindow({
  name,
  popup,
  connector,
  gdkmonitor,
  render,
  register,
}: {
  name: PopupName
  popup: any
  connector: string
  gdkmonitor: Gdk.Monitor
  render: () => JSX.Element
  register: (window: Astal.Window) => void
}) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      $={register}
      visible={popup((active: PopupName) => active === name)}
      namespace="drew-top-bar-popup"
      name={`bar-popup-${connector}-${name}`}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.NONE}
      anchor={TOP | RIGHT}
      margin_top={36}
      margin_right={18}
      application={app}
    >
      <box class="popover" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <With value={popup}>
          {(active: PopupName) => (active === name ? render() : <box />)}
        </With>
      </box>
    </window>
  )
}

export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  let win: Astal.Window | null = null
  let clickoutWin: Astal.Window | null = null
  const popupWins = new Array<Astal.Window>()
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
  const connector = monitorName(gdkmonitor)
  const [popup, setPopup] = createState<PopupName>("")
  const setActivePopup = (active: PopupName) => {
    if (active !== "") {
      closeAllPopups()
    }
    setPopup(active)
    setAnyPopupOpen(active !== "")
  }
  const closePopup = () => setPopup("")

  closePopupCallbacks.add(closePopup)

  onCleanup(() => {
    closePopupCallbacks.delete(closePopup)
    for (const popupWin of popupWins) {
      popupWin.destroy()
    }
    clickoutWin?.destroy()
    win?.destroy()
  })

  return (
    <Fragment>
      <window
        $={(self) => (clickoutWin = self)}
        visible={anyPopupOpen}
        namespace="drew-top-bar-clickout"
        name={`bar-clickout-${connector}`}
        gdkmonitor={gdkmonitor}
        layer={Astal.Layer.TOP}
        exclusivity={Astal.Exclusivity.IGNORE}
        keymode={Astal.Keymode.NONE}
        anchor={TOP | LEFT | RIGHT | Astal.WindowAnchor.BOTTOM}
        application={app}
      >
        <button
          class="clickout"
          hexpand
          vexpand
          widthRequest={gdkmonitor.geometry.width}
          heightRequest={gdkmonitor.geometry.height}
          onClicked={closeAllPopups}
        >
          <label label="" />
        </button>
      </window>
      <window
        $={(self) => (win = self)}
        visible
        namespace="drew-top-bar"
        name={`bar-${connector}`}
        gdkmonitor={gdkmonitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        keymode={Astal.Keymode.NONE}
        anchor={TOP | LEFT | RIGHT}
        application={app}
      >
        <centerbox class="bar">
          <box $type="start" class="left" spacing={0}>
            <Workspaces connector={connector} />
          </box>
          <box $type="center" class="center">
            <Clock popup={popup} setPopup={setActivePopup} />
          </box>
          <box $type="end" class="right" spacing={0}>
            <DictationButton popup={popup} setPopup={setActivePopup} />
            <NetworkButton popup={popup} setPopup={setActivePopup} />
            <BluetoothButton popup={popup} setPopup={setActivePopup} />
            <AudioButton popup={popup} setPopup={setActivePopup} />
            <DisplayButton popup={popup} setPopup={setActivePopup} />
            <PerformanceButton popup={popup} setPopup={setActivePopup} />
            <SessionButton popup={popup} setPopup={setActivePopup} />
            <PowerButton popup={popup} setPopup={setActivePopup} />
          </box>
        </centerbox>
      </window>
      <DictationOverlay connector={connector} gdkmonitor={gdkmonitor} />
      <PopupWindow name="clock" popup={popup} connector={connector} gdkmonitor={gdkmonitor} render={() => <ClockContent />} register={(self) => popupWins.push(self)} />
      <PopupWindow name="dictation" popup={popup} connector={connector} gdkmonitor={gdkmonitor} render={() => <DictationContent />} register={(self) => popupWins.push(self)} />
      <PopupWindow name="network" popup={popup} connector={connector} gdkmonitor={gdkmonitor} render={() => <NetworkContent />} register={(self) => popupWins.push(self)} />
      <PopupWindow name="bluetooth" popup={popup} connector={connector} gdkmonitor={gdkmonitor} render={() => <BluetoothContent />} register={(self) => popupWins.push(self)} />
      <PopupWindow name="audio" popup={popup} connector={connector} gdkmonitor={gdkmonitor} render={() => <AudioContent />} register={(self) => popupWins.push(self)} />
      <PopupWindow name="display" popup={popup} connector={connector} gdkmonitor={gdkmonitor} render={() => <DisplayContent />} register={(self) => popupWins.push(self)} />
      <PopupWindow name="performance" popup={popup} connector={connector} gdkmonitor={gdkmonitor} render={() => <PerformanceContent />} register={(self) => popupWins.push(self)} />
      <PopupWindow name="session" popup={popup} connector={connector} gdkmonitor={gdkmonitor} render={() => <SessionContent />} register={(self) => popupWins.push(self)} />
      <PopupWindow name="power" popup={popup} connector={connector} gdkmonitor={gdkmonitor} render={() => <PowerContent />} register={(self) => popupWins.push(self)} />
    </Fragment>
  )
}
