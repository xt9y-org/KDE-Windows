import QtQuick
import QtQuick.Controls
import QtQuick.Window

Item {
    visible: false
    width: 0
    height: 0
    id: root

    property bool launcherVisible: false

    Desktop {
        id: desktop
        Component.onCompleted: PlasmaBackend.registerDesktop(desktop)
    }

    Panel {
        id: panel
        onLauncherRequested: root.launcherVisible = !root.launcherVisible
        Component.onCompleted: PlasmaBackend.registerPanel(panel)
    }

    Launcher {
        id: launcher
        visible: root.launcherVisible
        panelX: panel.x
        panelY: panel.y
        onDismissed: root.launcherVisible = false
    }

    Notifications {}
}
