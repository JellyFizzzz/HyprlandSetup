import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: win

    // One fixed transparent canvas, big enough for the largest mode.
    // Only the pill takes input; every other pixel clicks through.
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "island"
    // Launcher, wallpaper picker, etc. need the keyboard; hover/main does not.
    WlrLayershell.keyboardFocus: win.interactive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: win.interactive ? scrim : pill }

    // ------------------------------------------------------------------
    // Tuning knobs
    // ------------------------------------------------------------------
    readonly property string timeFormat: "HH:mm"      // "h:mm" for 12-hour
    readonly property real spring: 6.0                // higher = snappier
    readonly property real damping: 0.48              // lower = bouncier
    readonly property int collapseDelay: 200          // ms before hover-close

    // Target pill size per mode
    readonly property var sizes: ({
        collapsed: Qt.size(Cava.active ? 160 : 112, 34),
        main:      Qt.size(640, 240),
        launcher:  Qt.size(640, 400),
        wallpaper: Qt.size(780, 290),
        center:    Qt.size(420, 580),
        power:     Qt.size(560, 150),
        notification: Qt.size(440, Notifs.hasActions ? 118 : 84)
    })

    // ------------------------------------------------------------------
    // State machine
    //   collapsed -> (hover) -> main -> (click) -> main + pinned
    //   keybind/IPC modes: launcher, wallpaper, center, power (sticky)
    // ------------------------------------------------------------------
    property string mode: "collapsed"
    property bool pinned: false

    readonly property bool interactive:
        mode === "launcher" || mode === "wallpaper" || mode === "center" || mode === "power"
    readonly property bool sticky: pinned || interactive

    function openMode(m) {
        if (m === "collapsed" || !(m in sizes))
            return;
        collapseTimer.stop();
        pinned = (m === "main");
        mode = m;
    }

    function close() {
        collapseTimer.stop();
        notifTimer.stop();
        pinned = false;
        mode = "collapsed";
    }

    function toggleMode(m) {
        if (mode === m && sticky)
            close();
        else
            openMode(m);
    }

    // ---- notifications ----
    function showNotification(n) {
        // Only interrupt the quiet states; a pinned screen or an open launcher keeps priority
        if (mode !== "collapsed" && mode !== "notification")
            return;
        Notifs.current = n;
        mode = "notification";
        notifTimer.interval = Notifs.timeoutFor(n);
        if (hover.hovered)
            notifTimer.stop();
        else
            notifTimer.restart();
    }

    Timer {
        id: notifTimer
        onTriggered: if (win.mode === "notification") win.close()
    }

    Connections {
        target: Notifs
        function onArrived(n) { win.showNotification(n); }
    }

    Timer {
        id: collapseTimer
        interval: win.collapseDelay
        onTriggered: if (win.mode === "main" && !win.pinned) win.close()
    }

    // Keybind hooks: qs -c island ipc call island toggle launcher
    IpcHandler {
        target: "island"

        function toggle(mode: string): void { win.toggleMode(mode); }
        function open(mode: string): void { win.openMode(mode); }
        function close(): void { win.close(); }
        function dnd(): void { Notifs.dnd = !Notifs.dnd; }
    }

    Shortcut {
        sequence: "Escape"
        enabled: win.sticky
        onActivated: win.close()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Full-window click catcher. It only receives input while a keyboard-driven
    // mode is open (the mask switches to it), so clicking anywhere outside the
    // island closes the launcher, wallpapers, control center or power menu.
    Item {
        id: scrim
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }
    }

    // ------------------------------------------------------------------
    // The pill
    // ------------------------------------------------------------------
    Rectangle {
        id: pill

        // Springs run on animW/animH; the clamp stops undershoot from ever
        // producing a zero or negative size.
        property real animW: win.sizes[win.mode].width
        property real animH: win.sizes[win.mode].height
        Behavior on animW { SpringAnimation { spring: win.spring; damping: win.damping; epsilon: 0.5 } }
        Behavior on animH { SpringAnimation { spring: win.spring; damping: win.damping; epsilon: 0.5 } }

        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        width: Math.max(animW, 40)
        height: Math.max(animH, 24)
        radius: Math.min(height / 2, 34)
        color: "#000000"   // the island body is always pure black
        clip: true

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered) {
                    collapseTimer.stop();
                    notifTimer.stop();
                    if (win.mode === "collapsed") {
                        win.pinned = false;
                        win.mode = "main";
                    }
                } else if (win.mode === "main" && !win.pinned) {
                    collapseTimer.restart();
                } else if (win.mode === "notification") {
                    notifTimer.interval = 1200;
                    notifTimer.restart();
                }
            }
        }

        // Clicking the open main screen pins it
        TapHandler {
            onTapped: if (win.mode === "main") win.pinned = true
        }

        // ---- mode layers: content stays full-size and is revealed as the
        // pill grows, instead of reflowing while it animates ----
        ModeLayer {
            name: "collapsed"; activeMode: win.mode; dims: win.sizes.collapsed
            // equaliser, left of the time; only while audio is playing
            Item {
                width: 68
                height: 24
                x: 18
                anchors.verticalCenter: parent.verticalCenter
                opacity: Cava.active ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 220 } }

                Repeater {
                    model: Cava.bars
                    Rectangle {
                        required property int index
                        x: index * 5
                        width: 3
                        radius: 1.5
                        height: Math.max(3, (Cava.values[index] || 0) / 100 * 22)
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.accent
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: Cava.active ? parent.width - width - 18 : (parent.width - width) / 2
                Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                text: Qt.formatDateTime(clock.date, win.timeFormat)
                color: Colors.bright
                font.family: Colors.fontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
        }

        ModeLayer {
            name: "main"; activeMode: win.mode; dims: win.sizes.main
            MainScreen {
                anchors.fill: parent
                anchors.margins: 22
                now: clock.date
                timeFormat: win.timeFormat
            }
        }

        ModeLayer {
            name: "launcher"; activeMode: win.mode; dims: win.sizes.launcher
            LauncherView {
                anchors.fill: parent
                active: win.mode === "launcher"
                onCloseRequested: win.close()
            }
        }

        ModeLayer {
            name: "wallpaper"; activeMode: win.mode; dims: win.sizes.wallpaper
            WallpaperView {
                anchors.fill: parent
                active: win.mode === "wallpaper"
                onCloseRequested: win.close()
            }
        }

        ModeLayer {
            name: "center"; activeMode: win.mode; dims: win.sizes.center
            ControlCenter {
                anchors.fill: parent
                onCloseRequested: win.close()
            }
        }

        ModeLayer {
            name: "power"; activeMode: win.mode; dims: win.sizes.power
            PowerView {
                anchors.fill: parent
                active: win.mode === "power"
                onCloseRequested: win.close()
            }
        }

        ModeLayer {
            name: "notification"; activeMode: win.mode; dims: win.sizes.notification
            NotificationPopup {
                anchors.fill: parent
                onDismissRequested: win.close()
            }
        }

        // ---- close button, shown whenever the island is held open ----
        Rectangle {
            id: closeBtn
            z: 10
            width: 22
            height: 22
            radius: 11
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 12
            color: Colors.alpha(Colors.fg, closeArea.containsMouse ? 0.30 : 0.14)
            opacity: win.sticky ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: Colors.fg
                font.family: Colors.fontFamily
                font.pixelSize: 10
            }

            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: win.close()
            }
        }
    }
}
