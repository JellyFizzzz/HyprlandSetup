pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Everything the control center shows or controls. Audio, battery, power
// profile and Bluetooth come from native Quickshell services and update live.
// Wi-Fi (nmcli), brightness (brightnessctl) and your wallpaper ambience are
// polled every 2 s, but only while the control center is open.
Singleton {
    id: root

    // Set by the control center while it is visible
    property bool watching: false

    // ---------------- audio ----------------
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [root.sink, root.source].filter(o => o !== null && o !== undefined)
    }

    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    function setVolume(v) {
        if (sink && sink.audio)
            sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMute() {
        if (sink && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }
    function toggleMic() {
        if (source && source.audio)
            source.audio.muted = !source.audio.muted;
    }

    // ---------------- battery and power profile ----------------
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery ? battery.isPresent : false
    readonly property int batteryPct: battery ? Math.min(100, Math.round(battery.percentage * 100)) : 0
    readonly property bool charging: battery
        ? (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged)
        : false

    readonly property bool powerSaver: PowerProfiles.profile === PowerProfile.PowerSaver
    function togglePowerSaver() {
        PowerProfiles.profile = powerSaver ? PowerProfile.Balanced : PowerProfile.PowerSaver;
    }

    // ---------------- bluetooth ----------------
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btOn: btAdapter ? btAdapter.enabled : false
    readonly property string btLabel: {
        if (!btOn)
            return "Off";
        const connected = Bluetooth.devices.values.filter(d => d.connected);
        return connected.length > 0 ? connected[0].name : "On";
    }
    function toggleBt() {
        if (btAdapter)
            btAdapter.enabled = !btAdapter.enabled;
    }

    // ---------------- wifi (nmcli) ----------------
    property bool wifiOn: false
    property string wifiName: ""

    Process {
        id: wifiRadio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiOn = text.trim() === "enabled"
        }
    }

    Process {
        id: wifiInfo
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = "";
                for (const line of text.split("\n")) {
                    if (line.startsWith("yes:")) {
                        const rest = line.slice(4);
                        const i = rest.lastIndexOf(":");
                        name = (i >= 0 ? rest.slice(0, i) : rest).replace(/\\:/g, ":");
                        break;
                    }
                }
                root.wifiName = name;
            }
        }
    }

    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiOn ? "off" : "on"]);
        wifiOn = !wifiOn;
        soon.restart();
    }

    // ---------------- brightness (same curve as your keys: -e4 -n2) ----------------
    property real brightness: 0.5
    property real pendingBrightness: 0.5

    Process {
        id: brightRead
        command: ["brightnessctl", "-e4", "-n2", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length >= 4 && Date.now() - root.lastBrightnessSet > 800)
                    root.brightness = (parseInt(f[3]) || 0) / 100;
            }
        }
    }

    property double lastBrightnessSet: 0
    property bool brightnessDirty: false

    // One brightnessctl at a time. While it runs, newer slider values are
    // coalesced and sent the moment it exits, so the screen follows the drag.
    Process {
        id: brightSet
        onExited: {
            if (root.brightnessDirty)
                root.sendBrightness();
        }
    }

    function sendBrightness() {
        brightnessDirty = false;
        brightSet.command = ["brightnessctl", "-e4", "-n2", "set",
                             Math.max(5, Math.round(pendingBrightness * 100)) + "%"];
        brightSet.running = true;
    }

    function setBrightness(v) {
        brightness = v;
        pendingBrightness = v;
        lastBrightnessSet = Date.now();
        if (brightSet.running)
            brightnessDirty = true;
        else
            sendBrightness();
    }

    // ---------------- wallpaper ambience (your walset audio) ----------------
    property string ambience: "none"   // none | playing | paused

    Process {
        id: ambRead
        command: ["sh", "-c",
            "p=$(cat /tmp/wallpaper-audio.pid 2>/dev/null); [ -n \"$p\" ] && kill -0 \"$p\" 2>/dev/null && ps -o stat= -p \"$p\"; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                root.ambience = t === "" ? "none" : (t.indexOf("T") >= 0 ? "paused" : "playing");
            }
        }
    }

    function toggleAmbience() {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/walset-audio-toggle.sh"]);
        soon.restart();
    }

    // ---------------- misc actions ----------------
    function screenshot() {
        Quickshell.execDetached(["sh", "-c",
            "sleep 0.6 && hyprshot -m output -o \"$HOME/Pictures/Screenshots\""]);
    }

    // ---------------- polling ----------------
    function refresh() {
        wifiRadio.running = true;
        wifiInfo.running = true;
        brightRead.running = true;
        ambRead.running = true;
    }

    Timer {
        running: root.watching
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: soon
        interval: 700
        onTriggered: root.refresh()
    }
}
