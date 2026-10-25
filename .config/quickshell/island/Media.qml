pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Now-playing state from MPRIS: Spotify, mpv with mpris, and browsers
// (Brave exposes YouTube tabs here). Picks a playing player first, otherwise
// the first paused one, and ignores the playerctld proxy so nothing doubles.
Singleton {
    id: root

    readonly property var players: Mpris.players.values.filter(p => p.dbusName.indexOf("playerctld") < 0)

    readonly property var player: {
        const ps = players;
        for (const p of ps) {
            if (p.playbackState === MprisPlaybackState.Playing)
                return p;
        }
        return ps.length > 0 ? ps[0] : null;
    }

    readonly property bool hasPlayer: player !== null
    readonly property bool playing: player ? player.playbackState === MprisPlaybackState.Playing : false
    readonly property string title: player ? (player.trackTitle || "Unknown title") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string art: player ? (player.trackArtUrl || "") : ""
    readonly property real length: player ? player.length : 0
    readonly property real position: player ? player.position : 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    function playPause() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }
    function next() {
        if (player && player.canGoNext)
            player.next();
    }
    function previous() {
        if (player && player.canGoPrevious)
            player.previous();
    }

    // MPRIS only reports position on demand, so poll once a second while playing
    Timer {
        running: root.playing && root.length > 0
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}
