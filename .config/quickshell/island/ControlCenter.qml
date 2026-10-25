import QtQuick

// Android-style control center: status row, toggle grid, sliders, notifications.
// Opened with SUPER + N (qs -c island ipc call island toggle center).
Item {
    id: root

    signal closeRequested()

    // Newest first
    readonly property var items: Notifs.list.values.slice().reverse()

    // Poll Wi-Fi, brightness and ambience only while this screen is visible
    onVisibleChanged: Sys.watching = visible

    // ------------------------------------------------------------------
    // Status row: wifi name, battery, volume
    // ------------------------------------------------------------------
    Row {
        x: 22
        y: 20
        height: 30
        spacing: 18

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Text {
                text: Icons.wifi
                visible: text !== ""
                color: Colors.accent
                font.family: Colors.fontFamily
                font.pixelSize: 15
            }
            Text {
                text: !Sys.wifiOn ? "Wi-Fi off" : (Sys.wifiName !== "" ? Sys.wifiName : "Not connected")
                width: Math.min(implicitWidth, 120)
                elide: Text.ElideRight
                color: Colors.fg
                font.family: Colors.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: Sys.hasBattery

            Text {
                text: Icons.battery(Sys.batteryPct)
                visible: text !== ""
                color: Colors.accent
                font.family: Colors.fontFamily
                font.pixelSize: 15
            }
            Text {
                text: Sys.batteryPct + "%" + (Sys.charging ? "  " + Icons.bolt : "")
                color: Colors.fg
                font.family: Colors.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                text: Sys.muted ? Icons.volumeOff : Icons.volume
                visible: text !== ""
                color: Colors.accent
                font.family: Colors.fontFamily
                font.pixelSize: 15
            }
            Text {
                text: Sys.muted ? "Muted" : Math.round(Sys.volume * 100) + "%"
                color: Colors.fg
                font.family: Colors.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }
    }

    // ------------------------------------------------------------------
    // Toggle grid
    // ------------------------------------------------------------------
    Grid {
        x: 22
        y: 64
        columns: 4
        spacing: 10

        ToggleTile {
            icon: Icons.wifi
            label: "Wi-Fi"
            sub: Sys.wifiOn ? (Sys.wifiName !== "" ? Sys.wifiName : "On") : "Off"
            active: Sys.wifiOn
            onClicked: Sys.toggleWifi()
        }
        ToggleTile {
            icon: Icons.bluetooth
            label: "Bluetooth"
            sub: Sys.btLabel
            active: Sys.btOn
            onClicked: Sys.toggleBt()
        }
        ToggleTile {
            icon: Sys.muted ? Icons.volumeOff : Icons.volume
            label: "Sound"
            sub: Sys.muted ? "Muted" : Math.round(Sys.volume * 100) + "%"
            active: !Sys.muted
            onClicked: Sys.toggleMute()
        }
        ToggleTile {
            icon: Sys.micMuted ? Icons.micOff : Icons.mic
            label: "Mic"
            sub: Sys.micMuted ? "Muted" : "On"
            active: !Sys.micMuted
            onClicked: Sys.toggleMic()
        }

        ToggleTile {
            icon: Icons.moon
            label: "Do not disturb"
            sub: Notifs.dnd ? "On" : "Off"
            active: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        ToggleTile {
            icon: Icons.leaf
            label: "Power saver"
            sub: Sys.powerSaver ? "On" : "Off"
            active: Sys.powerSaver
            onClicked: Sys.togglePowerSaver()
        }
        ToggleTile {
            icon: Icons.music
            label: "Ambience"
            sub: Sys.ambience === "playing" ? "Playing" : (Sys.ambience === "paused" ? "Paused" : "None")
            active: Sys.ambience === "playing"
            dimmed: Sys.ambience === "none"
            optimistic: Sys.ambience !== "none"
            onClicked: Sys.toggleAmbience()
        }
        ToggleTile {
            icon: Icons.camera
            label: "Screenshot"
            optimistic: false
            sub: ""
            onClicked: {
                root.closeRequested();
                Sys.screenshot();
            }
        }
    }

    // ------------------------------------------------------------------
    // Sliders
    // ------------------------------------------------------------------
    Column {
        x: 22
        y: 216
        width: parent.width - 44
        spacing: 6

        SliderRow {
            width: parent.width
            icon: Icons.sun
            label: "Brightness"
            value: Sys.brightness
            onMoved: v => Sys.setBrightness(v)
        }
        SliderRow {
            width: parent.width
            icon: Sys.muted ? Icons.volumeOff : Icons.volume
            label: "Volume"
            value: Sys.volume
            dimmed: Sys.muted
            onMoved: v => Sys.setVolume(v)
        }
    }

    // ------------------------------------------------------------------
    // Notifications
    // ------------------------------------------------------------------
    Item {
        id: notifHeader
        x: 22
        y: 322
        width: parent.width - 44
        height: 24

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            color: Colors.fg
            font.family: Colors.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: clearText.implicitWidth + 22
            height: 24
            radius: 12
            visible: root.items.length > 0
            color: Colors.alpha(Colors.fg, clearArea.containsMouse ? 0.22 : 0.12)
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: clearText
                anchors.centerIn: parent
                text: "Clear all"
                color: Colors.fg
                font.family: Colors.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: clearArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    for (const n of Notifs.list.values.slice())
                        n.dismiss();
                }
            }
        }
    }

    ListView {
        id: nlist
        x: 22
        y: 354
        width: parent.width - 44
        height: parent.height - y - 20
        clip: true
        spacing: 8
        boundsBehavior: Flickable.StopAtBounds
        model: root.items

        delegate: Rectangle {
            id: card
            required property var modelData

            width: nlist.width
            height: col.implicitHeight + 24
            radius: 16
            color: Colors.alpha(Colors.fg, 0.08)

            Column {
                id: col
                x: 14
                y: 12
                width: parent.width - 28
                spacing: 2

                Item {
                    width: parent.width
                    height: 16

                    Text {
                        width: parent.width - 24
                        text: card.modelData.appName
                        color: Colors.dim
                        elide: Text.ElideRight
                        font.family: Colors.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.6
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.alpha(Colors.fg, dismissArea.containsMouse ? 0.30 : 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Colors.fg
                            font.family: Colors.fontFamily
                            font.pixelSize: 8
                        }

                        MouseArea {
                            id: dismissArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: card.modelData.dismiss()
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: card.modelData.summary
                    color: Colors.fg
                    elide: Text.ElideRight
                    font.family: Colors.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: card.modelData.body
                    visible: text !== ""
                    color: Colors.alpha(Colors.fg, 0.75)
                    textFormat: Text.StyledText
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: Colors.fontFamily
                    font.pixelSize: 12
                }

                Row {
                    spacing: 6

                    Repeater {
                        model: card.modelData.actions

                        Rectangle {
                            id: act
                            required property var modelData

                            visible: modelData.text !== ""
                            height: 24
                            width: actLabel.implicitWidth + 22
                            radius: 12
                            color: Colors.alpha(Colors.accent, actArea.containsMouse ? 0.35 : 0.22)

                            Text {
                                id: actLabel
                                anchors.centerIn: parent
                                text: act.modelData.text
                                color: Colors.accent
                                font.family: Colors.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: actArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: act.modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: nlist
        visible: root.items.length === 0
        text: "No notifications"
        color: Colors.dim
        font.family: Colors.fontFamily
        font.pixelSize: 14
    }
}
