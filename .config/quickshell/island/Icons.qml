pragma Singleton

import QtQuick
import Quickshell

// Font Awesome glyphs from a Nerd Font (your waybar already uses them).
// If no Nerd Font is installed every glyph is an empty string and the UI
// simply shows text, instead of empty boxes.
Singleton {
    id: root

    readonly property bool ok: Qt.fontFamilies().some(f => /nerd|awesome/i.test(f))

    function g(c) {
        return ok ? c : "";
    }

    readonly property string wifi: g("\uf1eb")
    readonly property string bluetooth: g("\uf293")
    readonly property string volume: g("\uf028")
    readonly property string volumeOff: g("\uf026")
    readonly property string mic: g("\uf130")
    readonly property string micOff: g("\uf131")
    readonly property string moon: g("\uf186")
    readonly property string leaf: g("\uf06c")
    readonly property string music: g("\uf001")
    readonly property string camera: g("\uf030")
    readonly property string sun: g("\uf185")
    readonly property string bolt: g("\uf0e7")

    readonly property string lock: g("\uf023")
    readonly property string hibernate: g("\uf2dc")
    readonly property string logout: g("\uf08b")
    readonly property string shutdown: g("\uf011")
    readonly property string suspend: g("\uf186")
    readonly property string reboot: g("\uf021")

    function battery(pct) {
        if (pct >= 88) return g("\uf240");
        if (pct >= 63) return g("\uf241");
        if (pct >= 38) return g("\uf242");
        if (pct >= 13) return g("\uf243");
        return g("\uf244");
    }
}
