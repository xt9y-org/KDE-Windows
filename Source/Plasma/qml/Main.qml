import QtQuick
import QtQuick.Controls
import QtQuick.Window

Item {
    visible: false
    width: 0
    height: 0
    id: root

    property bool launcherVisible: false
    property bool runnerVisible: false
    property bool clipboardVisible: false

    function showRunner() {
        launcherVisible = false
        clipboardVisible = false
        runnerVisible = true
    }

    function showClipboard() {
        launcherVisible = false
        runnerVisible = false
        clipboardVisible = !clipboardVisible
    }

    Desktop {
        id: desktop
        Component.onCompleted: PlasmaBackend.registerDesktop(desktop)
    }

    Panel {
        id: panel
        onLauncherRequested: {
            root.runnerVisible = false
            root.clipboardVisible = false
            root.launcherVisible = !root.launcherVisible
        }
        onClipboardRequested: root.showClipboard()
        Component.onCompleted: PlasmaBackend.registerPanel(panel)
    }

    Launcher {
        id: launcher
        visible: root.launcherVisible
        panelX: panel.x
        panelY: panel.y
        onDismissed: root.launcherVisible = false
    }

    Runner {
        id: runner
        visible: root.runnerVisible
        onDismissed: root.runnerVisible = false
    }

    Clipboard {
        id: clipboard
        visible: root.clipboardVisible
        onDismissed: root.clipboardVisible = false
    }

    Connections {
        target: PlasmaBackend
        function onRunnerRequested() { root.showRunner() }
        function onClipboardRequested() { root.showClipboard() }
    }

    Notifications {}
}
