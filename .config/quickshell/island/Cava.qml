pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Runs cava with cava.conf (raw ascii on stdout) and exposes:
//   values  14 numbers, 0-100, one per bar
//   active  true while any audio is audible, false ~1.6 s after it goes quiet
// Because cava listens to the default output, this reacts to anything that
// makes sound: music, YouTube, and your ambient wallpaper audio alike.
Singleton {
    id: root

    readonly property int bars: 14
    property var values: new Array(14).fill(0)
    property bool active: false

    // Peak level (0-100) that counts as "audio is playing"
    readonly property int threshold: 4
    readonly property int silenceMs: 800

    Timer {
        id: silence
        interval: root.silenceMs
        onTriggered: root.active = false
    }

    Timer {
        id: respawn
        interval: 3000
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(";");
                const v = [];
                let peak = 0;
                for (let i = 0; i < root.bars; i++) {
                    const n = parseInt(parts[i]) || 0;
                    v.push(n);
                    if (n > peak)
                        peak = n;
                }
                if (peak >= root.threshold) {
                    root.active = true;
                    silence.restart();
                }
                // Skip updates while silent so hidden bars cost nothing
                if (peak > 0 || root.active)
                    root.values = v;
            }
        }

        onExited: (code, status) => {
            console.log("cava exited with code", code, "- retrying in 3 s");
            respawn.start();
        }
    }
}
