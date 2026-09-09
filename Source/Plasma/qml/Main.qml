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
    property bool calendarVisible: false
    property bool settingsVisible: false
    property int settingsPage: 0

    function hidePopups() {
        launcherVisible = false
        runnerVisible = false
        clipboardVisible = false
        notificationCenterVisible = false
        calendarVisible = false
    }

    function toggleLauncher() {
        const next = !launcherVisible
        hidePopups()
        overviewVisible = false
        settingsVisible = false
        launcherVisible = next
    }

    function showRunner() {
        hidePopups()
        overviewVisible = false
        settingsVisible = false
        runnerVisible = true
    }

    function showClipboard() {
        const next = !clipboardVisible
        hidePopups()
        overviewVisible = false
        settingsVisible = false
        clipboardVisible = next
    }

    function showNotificationCenter() {
        const next = !notificationCenterVisible
        hidePopups()
        overviewVisible = false
        settingsVisible = false
        notificationCenterVisible = next
    }

    function showCalendar() {
        const next = !calendarVisible
        hidePopups()
        overviewVisible = false
        settingsVisible = false
        calendarVisible = next
    }

    function showOverview() {
        hidePopups()
        settingsVisible = false
        overviewVisible = !overviewVisible
    }

    function showSettings(page) {
        hidePopups()
        overviewVisible = false
        settingsPage = page === undefined ? 0 : page
        settingsVisible = true
    }

    Instantiator {
        model: PlasmaBackend.displays

        delegate: Desktop {
            id: desktopWindow
            required property var modelData
            displayData: modelData
            showIcons: modelData.primary
            onRunnerRequested: root.showRunner()
            onSettingsRequested: root.showSettings(0)
            Component.onCompleted: PlasmaBackend.registerDesktop(desktopWindow)
        }
    }

    Panel {
        id: panel
        displayData: PlasmaBackend.primaryDisplay
        onLauncherRequested: root.toggleLauncher()
        onClipboardRequested: root.showClipboard()
        onNotificationCenterRequested: root.showNotificationCenter()
        onCalendarRequested: root.showCalendar()
        onSettingsRequested: function(page) { root.showSettings(page) }
        Component.onCompleted: PanelBridge.registerPanel(panel)
    }

    Launcher {
        id: launcher
        visible: root.launcherVisible
        panelX: panel.x
        panelY: panel.y
        onSettingsRequested: root.showSettings(0)
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

    Calendar {
        id: calendar
        visible: root.calendarVisible
        panelX: panel.x
        panelY: panel.y
        panelWidth: panel.width
        onDismissed: root.calendarVisible = false
    }

    Settings {
        id: settings
        visible: root.settingsVisible
        page: root.settingsPage
        onDismissed: root.settingsVisible = false
    }

    Overview {
        id: overview
        visible: root.overviewVisible
        onDismissed: root.overviewVisible = false
    }

    WindowSwitcher {}

    Connections {
        target: PlasmaBackend
        function onRunnerRequested() {
            if (PlasmaBackend.takeLauncherRequest())
                root.toggleLauncher()
            else
                root.showRunner()
        }
        function onClipboardRequested() { root.showClipboard() }
        function onOverviewRequested() { root.showOverview() }
    }

    Notifications {}
}
