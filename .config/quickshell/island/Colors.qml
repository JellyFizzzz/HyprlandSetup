pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live pywal palette. wal rewrites ~/.cache/wal/colors.json on every wallpaper
// change; FileView watches it, so everything bound to these properties
// recolours instantly with no restart.
Singleton {
    id: root

    // SF Pro if installed, then Inter, then Qt's default sans
    readonly property string fontFamily: {
        const have = Qt.fontFamilies();
        for (const f of ["SF Pro Display", "SF Pro", "Inter"])
            if (have.indexOf(f) >= 0)
                return f;
        return "sans-serif";
    }

    Component.onCompleted: console.log("island font:", fontFamily)

    // Same colour with a different opacity
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    readonly property color fg: adapter.special.foreground
    readonly property color bg: adapter.special.background
    readonly property color accent: adapter.colors.color4
    readonly property color accent2: adapter.colors.color5
    readonly property color dim: adapter.colors.color8

    // Accent lifted to a minimum lightness so it always reads on the black island
    readonly property color bright: Qt.hsla(Math.max(0, accent.hslHue), accent.hslSaturation, Math.max(accent.hslLightness, 0.65), 1)
    readonly property string wallpaper: adapter.wallpaper

    FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property string wallpaper: ""

            property JsonObject special: JsonObject {
                property string background: "#000000"
                property string foreground: "#ffffff"
            }
            property JsonObject colors: JsonObject {
                property string color4: "#7aa2f7"
                property string color5: "#bb9af7"
                property string color8: "#888888"
            }
        }
    }
}
