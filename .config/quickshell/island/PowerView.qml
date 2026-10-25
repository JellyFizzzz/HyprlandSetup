import QtQuick
import Quickshell

// Power menu (replaces wlogout). Same six actions and same keys as your
// wlogout layout: l lock, h hibernate, e logout, s shutdown, u suspend, r reboot.
Item {
    id: root

    property bool active: false
    signal closeRequested()

    readonly property var actions: [
        { label: "Lock",      key: "L", icon: Icons.lock,      cmd: ["sh", "-c", "sleep 0.3 && setsid hyprlock &"] },
        { label: "Hibernate", key: "H", icon: Icons.hibernate, cmd: ["systemctl", "hibernate"] },
        { label: "Logout",    key: "E", icon: Icons.logout,    cmd: ["hyprctl", "dispatch", "exit"] },
        { label: "Shutdown",  key: "S", icon: Icons.shutdown,  cmd: ["systemctl", "poweroff"] },
        { label: "Suspend",   key: "U", icon: Icons.suspend,   cmd: ["systemctl", "suspend"] },
        { label: "Reboot",    key: "R", icon: Icons.reboot,    cmd: ["systemctl", "reboot"] }
    ]

    function run(i) {
        closeRequested();
        Quickshell.execDetached(actions[i].cmd);
    }

    // Keyboard shortcuts: this item holds focus while the menu is open
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            const k = event.text.toUpperCase();
            for (let i = 0; i < root.actions.length; i++) {
                if (root.actions[i].key === k) {
                    root.run(i);
                    event.accepted = true;
                    return;
                }
            }
        }
    }

    onVisibleChanged: if (visible) keys.forceActiveFocus()

    Row {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 8
        spacing: 12

        Repeater {
            model: root.actions

            Item {
                id: btn
                required property var modelData
                required property int index

                width: 78
                height: 104

                Rectangle {
                    id: circle
                    y: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56
                    height: 56
                    radius: 28
                    scale: area.pressed ? 0.92 : 1
                    color: area.containsMouse ? Colors.alpha(Colors.accent, 0.9)
                                              : Colors.alpha(Colors.fg, 0.12)
                    Behavior on color { ColorAnimation { duration: 90 } }
                    Behavior on scale { NumberAnimation { duration: 90 } }

                    // icon when a Nerd Font is available, otherwise the shortcut letter
                    Text {
                        anchors.centerIn: parent
                        text: btn.modelData.icon !== "" ? btn.modelData.icon : btn.modelData.key
                        color: area.containsMouse ? Colors.bg : Colors.fg
                        font.family: Colors.fontFamily
                        font.pixelSize: btn.modelData.icon !== "" ? 22 : 20
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    id: nameLabel
                    anchors.top: circle.bottom
                    anchors.topMargin: 9
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: btn.modelData.label
                    color: Colors.fg
                    font.family: Colors.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                // keyboard hint
                Text {
                    anchors.top: nameLabel.bottom
                    anchors.topMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: btn.modelData.key
                    color: Colors.dim
                    font.family: Colors.fontFamily
                    font.pixelSize: 10
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.run(btn.index)
                }
            }
        }
    }
}
