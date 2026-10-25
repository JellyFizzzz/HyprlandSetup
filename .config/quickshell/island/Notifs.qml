pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The island is the notification daemon (replaces swaync). Every notification
// is tracked, so the history stays available for the control center in
// phase 6 until it is dismissed.
Singleton {
    id: root

    property bool dnd: false

    // History (newest last). Used by the control center later.
    readonly property var list: server.trackedNotifications

    // The notification currently shown in the island popup
    property var current: null

    // Fired for each new notification when Do Not Disturb is off
    signal arrived(var notification)

    readonly property bool hasActions: {
        if (!current)
            return false;
        const a = current.actions;
        for (let i = 0; i < a.length; i++) {
            if (a[i].text !== "")
                return true;
        }
        return false;
    }

    // Popup time: low 1.5 s, normal 2.2 s, critical 4.5 s
    function timeoutFor(n) {
        if (n.urgency === NotificationUrgency.Critical)
            return 4500;
        if (n.urgency === NotificationUrgency.Low)
            return 1500;
        return 2200;
    }

    function iconFor(n) {
        if (!n)
            return "";
        if (n.image)
            return n.image;
        if (n.appIcon) {
            if (n.appIcon.indexOf("/") === 0)
                return "file://" + n.appIcon;
            return Quickshell.iconPath(n.appIcon, true);
        }
        return "";
    }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            if (!root.dnd)
                root.arrived(notification);
        }
    }
}
