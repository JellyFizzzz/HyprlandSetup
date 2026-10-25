import QtQuick

Item {
    id: root

    property string icon: ""
    property string label: ""
    property real value: 0          // 0..1, comes from the system
    property bool dimmed: false
    signal moved(real v)

    property bool dragging: false
    property real dragValue: 0
    readonly property real shown: dragging ? dragValue : value

    height: 44

    Text {
        text: (root.icon !== "" ? root.icon + "   " : "") + root.label
        color: Colors.fg
        font.family: Colors.fontFamily
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }

    Text {
        anchors.right: parent.right
        text: Math.round(root.shown * 100) + "%"
        color: Colors.dim
        font.family: Colors.fontFamily
        font.pixelSize: 12
    }

    Rectangle {
        id: track
        y: 26
        width: parent.width
        height: 8
        radius: 4
        color: Colors.alpha(Colors.fg, 0.15)

        Rectangle {
            width: parent.width * root.shown
            height: parent.height
            radius: 4
            color: root.dimmed ? Colors.dim : Colors.accent
        }

        Rectangle {
            x: parent.width * root.shown - width / 2
            y: -5
            width: 18
            height: 18
            radius: 9
            color: Colors.fg
            scale: root.dragging ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: 120 } }
        }
    }

    MouseArea {
        y: 16
        width: parent.width
        height: 28

        function update(x) {
            root.dragValue = Math.max(0, Math.min(1, x / width));
            root.moved(root.dragValue);
        }

        onPressed: mouse => {
            root.dragging = true;
            update(mouse.x);
        }
        onPositionChanged: mouse => {
            if (pressed)
                update(mouse.x);
        }
        onReleased: root.dragging = false
        onCanceled: root.dragging = false
    }
}
