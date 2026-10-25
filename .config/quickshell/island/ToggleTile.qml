import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string sub: ""
    property bool active: false
    property bool dimmed: false
    // Flip the look the instant it is clicked instead of waiting for the system
    // to confirm. If the system disagrees, it snaps back after 1.5 s.
    property bool optimistic: true
    signal clicked()

    property bool _pending: false
    property bool _override: false
    readonly property bool shown: _pending ? _override : active

    onActiveChanged: _pending = false

    Timer {
        id: settle
        interval: 1500
        onTriggered: root._pending = false
    }

    width: 86
    height: 64
    radius: 18
    opacity: dimmed ? 0.5 : 1
    scale: area.pressed ? 0.95 : 1
    color: shown ? Colors.alpha(Colors.accent, area.pressed ? 0.75 : (area.containsMouse ? 1.0 : 0.9))
                 : Colors.alpha(Colors.fg, area.pressed ? 0.28 : (area.containsMouse ? 0.20 : 0.12))

    Behavior on color { ColorAnimation { duration: 80 } }
    Behavior on scale { NumberAnimation { duration: 80 } }
    Behavior on opacity { NumberAnimation { duration: 140 } }

    readonly property color textColor: shown ? Colors.bg : Colors.fg
    readonly property color subColor: shown ? Colors.alpha(Colors.bg, 0.7) : Colors.dim

    Column {
        anchors.centerIn: parent
        width: parent.width - 12
        spacing: 3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            visible: root.icon !== ""
            color: root.textColor
            font.family: Colors.fontFamily
            font.pixelSize: 20
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.label
            color: root.textColor
            elide: Text.ElideRight
            font.family: Colors.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.sub
            visible: root.sub !== ""
            color: root.subColor
            elide: Text.ElideRight
            font.family: Colors.fontFamily
            font.pixelSize: 10
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (root.optimistic) {
                root._override = !root.shown;
                root._pending = true;
                settle.restart();
            }
            root.clicked();
        }
    }
}
