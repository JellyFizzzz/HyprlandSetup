import QtQuick

Item {
    id: root

    property date now: new Date()
    property string timeFormat: "HH:mm"
    property int weekStart: 1   // 0 = Sunday, 1 = Monday

    readonly property int year: now.getFullYear()
    readonly property int month: now.getMonth()
    readonly property int offset: (new Date(year, month, 1).getDay() - weekStart + 7) % 7
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
    readonly property int rows: Math.ceil((offset + daysInMonth) / 7)

    // ---- left: now playing ----
    NowPlaying {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 168 - 24
    }

    // ---- right: time, date, month grid ----
    Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            text: Qt.formatDateTime(root.now, root.timeFormat)
            color: Colors.bright
            font.family: Colors.fontFamily
            font.pixelSize: 34
            font.weight: Font.DemiBold
        }

        Text {
            text: Qt.formatDateTime(root.now, "dddd, d MMMM")
            color: Colors.accent
            font.family: Colors.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Item { width: 1; height: 8 }

        Grid {
            columns: 7
            rowSpacing: 2
            columnSpacing: 0

            // weekday letters
            Repeater {
                model: 7
                Item {
                    required property int index
                    width: 24
                    height: 16
                    Text {
                        anchors.centerIn: parent
                        text: ["S", "M", "T", "W", "T", "F", "S"][(index + root.weekStart) % 7]
                        color: Colors.dim
                        font.family: Colors.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }

            // days
            Repeater {
                model: root.rows * 7
                Item {
                    id: cell
                    required property int index
                    readonly property int day: index - root.offset + 1
                    readonly property bool valid: day >= 1 && day <= root.daysInMonth
                    readonly property bool today: valid && day === root.now.getDate()

                    width: 24
                    height: 16

                    Rectangle {
                        anchors.centerIn: parent
                        width: 18
                        height: 16
                        radius: 8
                        color: Colors.accent
                        visible: cell.today
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cell.valid ? cell.day : ""
                        color: cell.today ? Colors.bg : Colors.fg
                        font.family: Colors.fontFamily
                        font.pixelSize: 11
                        font.weight: cell.today ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}
