import QtQuick
import Quickshell

// App launcher (replaces rofi drun). Type to filter, Up/Down to move,
// Enter to launch, Esc or a click outside to close.
Item {
    id: root

    property bool active: false
    signal closeRequested()

    property int selected: 0

    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        if (q === "")
            return apps.sort((a, b) => a.name.localeCompare(b.name)).slice(0, 40);

        const scored = [];
        for (const a of apps) {
            const name = a.name.toLowerCase();
            let score = -1;
            if (name.startsWith(q))
                score = 0;
            else if (name.indexOf(q) >= 0)
                score = 1;
            else {
                const extra = ((a.genericName || "") + " " + (a.comment || "") + " "
                               + Array.from(a.keywords || []).join(" ")).toLowerCase();
                if (extra.indexOf(q) >= 0)
                    score = 2;
            }
            if (score >= 0)
                scored.push({ app: a, score: score });
        }
        scored.sort((x, y) => (x.score - y.score) || x.app.name.localeCompare(y.app.name));
        return scored.slice(0, 40).map(x => x.app);
    }

    function launch(i) {
        const e = results[i];
        if (!e)
            return;
        e.execute();
        closeRequested();
    }

    // Reset and grab the keyboard each time the launcher appears
    onVisibleChanged: {
        if (visible) {
            input.text = "";
            selected = 0;
            input.forceActiveFocus();
        }
    }

    // ---- search field (leaves room for the close button) ----
    Rectangle {
        id: field
        x: 22
        y: 22
        width: parent.width - 22 - 56
        height: 48
        radius: 24
        color: Colors.alpha(Colors.fg, 0.10)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 20
            text: "Search apps"
            color: Colors.dim
            visible: input.text === ""
            font.family: Colors.fontFamily
            font.pixelSize: 17
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Colors.fg
            selectionColor: Colors.accent
            selectedTextColor: Colors.bg
            font.family: Colors.fontFamily
            font.pixelSize: 17

            onTextChanged: root.selected = 0
            Keys.onDownPressed: root.selected = Math.min(root.selected + 1, root.results.length - 1)
            Keys.onUpPressed: root.selected = Math.max(root.selected - 1, 0)
            Keys.onReturnPressed: root.launch(root.selected)
            Keys.onEnterPressed: root.launch(root.selected)
        }
    }

    // ---- results ----
    ListView {
        id: list
        x: 22
        y: field.y + field.height + 14
        width: parent.width - 44
        height: parent.height - y - 22
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: root.results
        currentIndex: root.selected
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index

            width: list.width
            height: 46
            radius: 12
            color: index === root.selected ? Colors.alpha(Colors.accent, 0.22) : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            // icon, with the first letter as a fallback
            Item {
                id: iconBox
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28

                Text {
                    anchors.centerIn: parent
                    text: row.modelData.name.charAt(0).toUpperCase()
                    color: Colors.accent
                    font.family: Colors.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    visible: icon.status !== Image.Ready
                }

                Image {
                    id: icon
                    anchors.fill: parent
                    source: Quickshell.iconPath(row.modelData.icon, true)
                    sourceSize: Qt.size(56, 56)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }

            Column {
                x: 52
                width: parent.width - 52 - 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: row.modelData.name
                    color: Colors.fg
                    elide: Text.ElideRight
                    font.family: Colors.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Medium
                }
                Text {
                    width: parent.width
                    text: row.modelData.genericName || row.modelData.comment || ""
                    color: Colors.dim
                    elide: Text.ElideRight
                    visible: text !== ""
                    font.family: Colors.fontFamily
                    font.pixelSize: 11
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.selected = row.index
                onClicked: root.launch(row.index)
            }
        }
    }

    Text {
        anchors.centerIn: list
        text: "No results"
        color: Colors.dim
        visible: root.results.length === 0
        font.family: Colors.fontFamily
        font.pixelSize: 15
    }
}
