import QtQuick

// One screen of the island. It keeps its full target size and is revealed by
// the pill growing around it. Content fades in slightly after the shape starts
// moving and fades out fast, which is what makes the transition read as Apple's.
Item {
    id: layer

    property string name
    property string activeMode
    property size dims: Qt.size(100, 100)

    readonly property bool shown: activeMode === name

    width: dims.width
    height: dims.height
    anchors.horizontalCenter: parent.horizontalCenter
    y: 0

    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.94
    transformOrigin: Item.Top
    visible: opacity > 0.01
    enabled: shown

    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation { duration: layer.shown ? 60 : 0 }
            NumberAnimation { duration: layer.shown ? 190 : 90; easing.type: Easing.OutCubic }
        }
    }

    Behavior on scale {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
}
