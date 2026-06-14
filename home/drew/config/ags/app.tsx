import { createBinding, For, This } from "ags"
import app from "ags/gtk4/app"
import Gdk from "gi://Gdk?version=4.0"
import style from "./style.scss"
import Bar from "./Bar"

function monitorId(monitor: Gdk.Monitor) {
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

app.start({
  css: style,
  gtkTheme: "Adwaita",
  main() {
    const monitors = createBinding(app, "monitors")

    return (
      <For each={monitors} id={monitorId}>
        {(monitor) => (
          <This this={app}>
            <Bar gdkmonitor={monitor} />
          </This>
        )}
      </For>
    )
  },
})
