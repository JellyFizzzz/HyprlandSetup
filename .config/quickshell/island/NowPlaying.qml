import QtQuick
import QtQuick.Effects

Item {
    id: root
    height: 120

    // ---- album art / thumbnail, rounded with a mask ----
    Item {
        id: artBox
        width: 120
        height: 120

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Colors.alpha(Colors.fg, 0.10)

            Text {
                anchors.centerIn: parent
                text: "♪"
                color: Colors.dim
                font.family: Colors.fontFamily
                font.pixelSize: 44
                visible: artImg.status !== Image.Ready
            }
        }

        Image {
            id: artImg
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(240, 240)
            visible: status === Image.Ready
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: artMask
            }
        }

        Item {
            id: artMask
            anchors.fill: parent
            layer.enabled: true
            visible: false
            Rectangle {
                anchors.fill: parent
                radius: 20
            }
        }
    }

    // ---- text, progress, controls ----
    Column {
        x: 136
        width: parent.width - 136
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            width: parent.width
            text: Media.hasPlayer ? Media.title : "Not playing"
            color: Colors.fg
            elide: Text.ElideRight
            font.family: Colors.fontFamily
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            text: Media.hasPlayer ? Media.artist : "Nothing is playing right now"
            color: Colors.dim
            elide: Text.ElideRight
            font.family: Colors.fontFamily
            font.pixelSize: 13
        }

        Item { width: 1; height: 10 }

        Rectangle {
            width: parent.width
            height: 4
            radius: 2
            color: Colors.alpha(Colors.fg, 0.15)

            Rectangle {
                width: parent.width * Media.progress
                height: parent.height
                radius: 2
                color: Colors.accent
            }
        }

        Item { width: 1; height: 6 }

        Row {
            spacing: 26
            opacity: Media.hasPlayer ? 1 : 0.35

            Item {
                width: 30
                height: 30
                Text {
                    anchors.centerIn: parent
                    text: "⏮"
                    color: Colors.fg
                    font.family: Colors.fontFamily
                    font.pixelSize: 20
                }
                MouseArea { anchors.fill: parent; onClicked: Media.previous() }
            }

            Item {
                width: 30
                height: 30
                Text {
                    anchors.centerIn: parent
                    text: Media.playing ? "⏸" : "▶"
                    color: Colors.fg
                    font.family: Colors.fontFamily
                    font.pixelSize: 24
                }
                MouseArea { anchors.fill: parent; onClicked: Media.playPause() }
            }

            Item {
                width: 30
                height: 30
                Text {
                    anchors.centerIn: parent
                    text: "⏭"
                    color: Colors.fg
                    font.family: Colors.fontFamily
                    font.pixelSize: 20
                }
                MouseArea { anchors.fill: parent; onClicked: Media.next() }
            }
        }
    }
}
