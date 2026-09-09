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
    property bool overviewVisible: false
    property bool notificationCenterVisible: false

    function hidePopups() {
        launcherVisible = false
        runnerVisible = false
        clipboardVisible = false
        notificationCenterVisible = false
    }

    function showRunner() {
        hidePopups()
        overviewVisible = false
        runnerVisible = true
    }

    function showClipboard() {
        launcherVisible = false
        runnerVisible = false
        overviewVisible = false
        notificationCenterVisible = false
        clipboardVisible = !clipboardVisible
    }

    function showNotificationCenter() {
        launcherVisible = false
        runnerVisible = false
        clipboardVisible = false
        overviewVisible = false
        notificationCenterVisible = !notificationCenterVisible
    }

    function showOverview() {
        hidePopups()
        overviewVisible = !overviewVisible
    }

    Desktop {
        id: desktop
        onRunnerRequested: root.showRunner()
        Component.onCompleted: PlasmaBackend.registerDesktop(desktop)
    }

    Panel {
        id: panel
        onLauncherRequested: {
            root.runnerVisible = false
            root.clipboardVisible = false
            root.notificationCenterVisible = false
            root.overviewVisible = false
            root.launcherVisible = !root.launcherVisible
        }
        onClipboardRequested: root.showClipboard()
        onNotificationCenterRequested: root.showNotificationCenter()
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

    NotificationCenter {
        id: notificationCenter
        visible: root.notificationCenterVisible
        onDismissed: root.notificationCenterVisible = false
    }

    Overview {
        id: overview
        visible: root.overviewVisible
        onDismissed: root.overviewVisible = false
    }

    WindowSwitcher {}

    Connections {
        target: PlasmaBackend
        function onRunnerRequested() { root.showRunner() }
        function onClipboardRequested() { root.showClipboard() }
        function onOverviewRequested() { root.showOverview() }
    }

    Notifications {}
}
