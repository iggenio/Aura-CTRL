# Aura-CTRL

**Aura RGB logo control and status alerts for Asuswrt-Merlin**

Aura-CTRL turns the Aura RGB logo of an ASUS ROG router into a status light.

- **Lighting** – how the logo looks when everything is fine: one scene, or a day scene and a night scene with their start times.
- **Alerts** – the logo shows problems. The colour tells the family of the alert (Security, Connectivity, Wi-Fi, System, Maintenance, Activity), the animation tells how urgent it is (Critical, Warning, Info).

Version 1.0.0 – tested on the ASUS ROG Rapture GT-AXE11000 with Asuswrt-Merlin 3004.388.12_2.

## Features

### Lighting
- **24 animations**: the 14 effects of the router's light controller (including Pulse, Siren and Siren multicolor, which the ASUS page does not show) and 10 made by Aura-CTRL: Multi-colour, Colour steps, Traffic meter, Colour fade, Colour breathing, Alternate, Two-colour siren, Heartbeat, Candle, Sweep.
- **Traffic meter**: a bar meter of the internet traffic. Three zones always on (green, yellow and red by default, colours of your choice); each zone goes from dim to full as the traffic fills its third of the line. 100% is the speed of your line (enter the results of a speed test), measured every 3, 5 or 10 seconds.
- **Day and night**: two scenes with their start times; at night each alert can be shown or hidden.
- **Brightness**, with a separate night brightness.
- **Smooth transitions**: the logo fades through black when it changes, without the flash of the previous colour.
- **Eco mode**: the animations marked *High CPU* (about one CPU core while they run) are replaced by the closest router effect. Router effects run on the light controller and use no CPU.

### Alerts
11 alerts, each with a fixed yes/no rule – **no thresholds to tune**:

| Alert | Family | Severity | Rule |
| --- | --- | --- | --- |
| Router tampering | Security | Critical | Critical settings (DNS, remote access, port forwarding, SSH, admin), `/jffs/scripts` or the scheduled jobs changed |
| Evil twin detected | Security | Critical | A nearby access point uses your network name with a BSSID that is not this router or an AiMesh node |
| Internet down | Connectivity | Critical | The WAN connection is down |
| Protection stalled (Skynet) | Security | Warning | Skynet is installed but its block list is not loaded, or its malware lists were not updated for 48 hours |
| Unknown device | Security | Warning | A device never seen before gets an address from the router |
| Radar detected (ZW-DFS) | Wi-Fi | Warning | ZW-DFS logged a radar event |
| High temperature | System | Warning | CPU temperature over 90 °C |
| USB missing or almost full | System | Warning | A USB disk mounted at start-up is gone, or a disk is over 90% full |
| Radar check in progress (ZW-DFS) | Wi-Fi | Info | ZW-DFS background radar check or move in progress |
| Firmware update available | Maintenance | Info | The router found a new firmware |
| Admin session active | Activity | Info | Someone is logged in to the web page or SSH |

- For each alert: on/off, colour (family colour, Custom 1, Custom 2 or its own), animation, duration (while active, 5/10/30 minutes, until acknowledged), shown at night or not, and **Test** (10 seconds on the logo).
- **Several alerts at once**: the most severe alert is shown with its animation and the colours of the others appear every 10 seconds. With a known zone map up to 3 alerts (none Critical) share the logo.
- **Acknowledge** clears the alerts shown and accepts new devices and configuration changes.

### Diagnostics
- **Light zones**: a button per zone (1 to 5) lights it in white, so you can see how your model uses them. On models not yet verified you choose 3 or 5 zones from the result.
- **Colour correction**: the LEDs do not show colours like a screen (yellow can look green, white bluish). Red, green and blue sliders with test colours on the logo; verified models start from measured values (GT-AXE11000: 100 / 60 / 57 %).
- Router model, CPU temperature, unknown devices, recent events.

### Light on the router
- The check that cron runs every minute reads settings and nvram once and starts about 30 short processes (about half a second on a GT-AXE11000).
- Temporary signals are never saved with `nvram commit`: a reboot never leaves an old alert colour.

## Supported routers

| Model | Status |
| --- | --- |
| ROG Rapture GT-AXE11000 | Verified: all features, zone map with 3 zones, colour correction measured |
| Other ASUS routers with Aura RGB (`aura_rgb` in `rc_support`) | Router effects, Colour steps, Traffic meter and all alerts. After you test the light zones and choose 3 or 5 zones in Diagnostics, all features are available. Until then, animations made by the add-on are shown as the closest router effect, transitions are instant and several alerts are shown one after the other |

Help to verify more models: in **Diagnostics > Light zones** press the Zone 1 to Zone 5 buttons and report on GitHub or SNBForums which part of the logo lights up for each zone, and the colour correction values that look right on your logo.

## Requirements

- Asuswrt-Merlin firmware (tested on 3004.388.12_2) with **JFFS custom scripts** enabled.
- An ASUS router with an Aura RGB logo.
- SSH access (LAN) and a PC with `scp`.
- Optional: [ZW-DFS](https://github.com/iggenio/ZW-DFS) for the radar alerts, Skynet for the protection alert.

## Installation

See [INSTALL.txt](INSTALL.txt) for the full guide. In short:

1. On the router (SSH): `mkdir -p /jffs/addons/aura-ctrl`
2. On the PC: `scp -O aura-ctrl.sh aura-ctrl.asp <router-user>@<router-ip>:/jffs/addons/aura-ctrl/`
3. On the router: add the three hook lines described in INSTALL.txt, then run `/jffs/addons/aura-ctrl/aura-ctrl.sh install`
4. Reload the WebUI (Ctrl+F5) and open **Administration > Aura-CTRL**.

To restore the original logo at any time: `service restart_leds` (a reboot does the same).

## Support

If ZW-DFS is useful to you, you can buy me a coffee:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/iggenio)

## Files

| File | Purpose |
| --- | --- |
| `aura-ctrl.sh` | Management script (alerts, scenes, animations, WebUI install) |
| `aura-ctrl.asp` | WebUI page |
| `INSTALL.txt` | Installation guide, commands, notes |
| `CHANGELOG.txt` | Version history |
| `LICENSE` | GNU GPL v3 |

## AI assistance

Aura-CTRL was developed by iggenio with the assistance of Claude (Anthropic), an AI model, which contributed to the analysis, the code and the documentation. The author reviewed and tested it on a GT-AXE11000. Review the code before installing it on your router; use it at your own risk.

## License

GNU General Public License v3.0 or later – see [LICENSE](LICENSE).
