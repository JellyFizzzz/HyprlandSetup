import QtQuick

Item {
    id: root

    signal dismissRequested()

    readonly property var n: Notifs.current

    // Clicking the popup hides it (the notification stays in the history)
    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissRequested()
    }

    // ---- icon, with the app's first letter as a fallback ----
    Rectangle {
        id: iconBox
        x: 16
        y: 20
        width: 44
        height: 44
        radius: 12
        color: Colors.alpha(Colors.fg, 0.10)

        Text {
            anchors.centerIn: parent
            text: root.n && root.n.appName ? root.n.appName.charAt(0).toUpperCase() : ""
            color: Colors.accent
            font.family: Colors.fontFamily
            font.pixelSize: 20
            font.weight: Font.DemiBold
            visible: icon.status !== Image.Ready
        }

        Image {
            id: icon
            anchors.fill: parent
            anchors.margins: 5
            source: Notifs.iconFor(root.n)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            sourceSize: Qt.size(88, 88)
            visible: status === Image.Ready
        }
    }

    // ---- text ----
    Column {
        x: 72
        y: 16
        width: parent.width - 72 - 16
        spacing: 1

        Text {
            width: parent.width
            text: root.n ? root.n.appName : ""
            color: Colors.dim
            elide: Text.ElideRight
            font.family: Colors.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.6
        }

        Text {
            width: parent.width
            text: root.n ? root.n.summary : ""
            color: Colors.fg
            elide: Text.ElideRight
            font.family: Colors.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            text: root.n ? root.n.body : ""
            visible: text !== ""
            color: Colors.alpha(Colors.fg, 0.75)
            textFormat: Text.StyledText
            maximumLineCount: 1
            elide: Text.ElideRight
            font.family: Colors.fontFamily
            font.pixelSize: 12
        }
    }

    // ---- action buttons, only when the app sent some ----
    Row {
        x: 72
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        spacing: 8

        Repeater {
            model: root.n ? root.n.actions : []

            Rectangle {
                id: btn
                required property var modelData

                visible: modelData.text !== ""
                height: 26
                width: label.implicitWidth + 26
                radius: 13
                color: Colors.alpha(Colors.accent, btnArea.containsMouse ? 0.35 : 0.22)
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: btn.modelData.text
                    color: Colors.accent
                    font.family: Colors.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: btnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        btn.modelData.invoke();
                        root.dismissRequested();
                    }
                }
            }
        }
    }
}
