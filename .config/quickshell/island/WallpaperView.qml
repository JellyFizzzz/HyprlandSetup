import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell

// Wallpaper switcher (replaces walset.sh + rofi). Left/Right or scroll to
// browse, Enter or click the centred wallpaper to apply. Applying runs your
// existing walset-backend.sh, so awww, wal, matugen and ambient audio all
// behave exactly as before.
Item {
    id: root

    property bool active: false
    signal closeRequested()

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    FolderListModel {
        id: files
        folder: "file://" + root.dir
        nameFilters: ["*.jpg", "*.jpeg", "*.png"]
        caseSensitive: false
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: root.syncCurrent()
    }

    // Start on the wallpaper that is currently applied
    function syncCurrent() {
        for (let i = 0; i < files.count; i++) {
            if (files.get(i, "filePath") === Colors.wallpaper) {
                list.currentIndex = i;
                return;
            }
        }
    }

    function apply(i) {
        const path = files.get(i, "filePath");
        if (!path)
            return;
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/walset-backend.sh", path]);
        closeRequested();
    }

    onVisibleChanged: {
        if (visible) {
            syncCurrent();
            list.forceActiveFocus();
        }
    }

    ListView {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        y: 44
        height: 200
        clip: true
        orientation: ListView.Horizontal
        spacing: 18
        model: files
        leftMargin: (width - 240) / 2
        rightMargin: (width - 240) / 2
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - 240) / 2
        preferredHighlightEnd: (width + 240) / 2
        highlightMoveDuration: 320
        keyNavigationEnabled: true
        boundsBehavior: Flickable.StopAtBounds

        Keys.onReturnPressed: root.apply(currentIndex)
        Keys.onEnterPressed: root.apply(currentIndex)

        // Vertical scroll wheel browses too; accumulate so touchpads don't race
        WheelHandler {
            property real acc: 0
            onWheel: event => {
                acc += event.angleDelta.y;
                if (acc >= 120) {
                    list.decrementCurrentIndex();
                    acc = 0;
                } else if (acc <= -120) {
                    list.incrementCurrentIndex();
                    acc = 0;
                }
            }
        }

        delegate: Item {
            id: card
            required property int index
            required property string fileName
            required property string filePath
            required property url fileUrl

            readonly property bool current: ListView.isCurrentItem
            readonly property bool applied: filePath === Colors.wallpaper

            width: 240
            height: list.height
            scale: current ? 1.0 : 0.82
            opacity: current ? 1.0 : 0.55
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 260 } }

            Item {
                id: thumb
                y: 8
                width: 240
                height: 135

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: Colors.alpha(Colors.fg, 0.10)
                }

                Image {
                    anchors.fill: parent
                    source: card.fileUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(480, 270)
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: mask
                    }
                }

                Item {
                    id: mask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                    }
                }

                // accent ring on the wallpaper that is currently applied
                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: "transparent"
                    border.width: 2
                    border.color: Colors.accent
                    visible: card.applied
                }
            }

            Text {
                y: thumb.y + thumb.height + 12
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                opacity: card.current ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                text: card.fileName.replace(/\.[^.]+$/, "") + (card.applied ? "  ·  current" : "")
                color: Colors.fg
                font.family: Colors.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (card.current)
                        root.apply(card.index);
                    else
                        list.currentIndex = card.index;
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: files.count === 0
        text: "No wallpapers found in ~/Pictures/Wallpapers"
        color: Colors.dim
        font.family: Colors.fontFamily
        font.pixelSize: 15
    }
}
