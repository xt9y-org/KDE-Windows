import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: panel
    objectName: "plasmaPanel"
    visible: true

    readonly property int screenX: displayData && displayData.x !== undefined ? displayData.x : Screen.virtualX
    readonly property int screenY: displayData && displayData.y !== undefined ? displayData.y : Screen.virtualY
    readonly property int screenWidth: displayData && displayData.width ? displayData.width : Screen.width
    readonly property int screenHeight: displayData && displayData.height ? displayData.height : Screen.height

    x: screenX + PlasmaTheme.panelMargin
    y: screenY + screenHeight - height - PlasmaTheme.panelMargin
    width: Math.max(1, screenWidth - PlasmaTheme.panelMargin * 2)
    height: PlasmaTheme.panelHeight
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    property var displayData: ({})
    signal launcherRequested()
    signal clipboardRequested()
    signal notificationCenterRequested()
    signal calendarRequested()
    signal settingsRequested(int page)

    PlasmaSurface {
        anchors.fill: parent
        radius: 6

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 3
            anchors.rightMargin: 3
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            spacing: 1

            PlasmaIconButton {
                id: launcherButton
                Layout.preferredWidth: 38
                Layout.fillHeight: true
                icon.name: "start-here-kde"
                icon.width: 24
                icon.height: 24
                onClicked: panel.launcherRequested()
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: "Application Launcher"
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 25
                color: PlasmaTheme.separator
            }

            FavoriteStrip {
                Layout.preferredWidth: implicitWidth
                Layout.fillHeight: true
            }

            Flickable {
                id: taskArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: taskRow.implicitWidth
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: taskRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Repeater {
                        model: PlasmaBackend.windows

                        delegate: ToolButton {
                            id: taskButton
                            required property var modelData
                            width: 40
                            height: 38
                            hoverEnabled: true
                            display: AbstractButton.IconOnly
                            onClicked: {
                                if (modelData.active)
                                    PlasmaBackend.minimizeWindow(modelData.id)
                                else
                                    PlasmaBackend.activateWindow(modelData.id)
                            }

                            contentItem: Item {
                                Image {
                                    anchors.centerIn: parent
                                    width: 26
                                    height: 26
                                    source: "image://shell/window/" + modelData.id
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                            }

                            background: Rectangle {
                                radius: PlasmaTheme.itemRadius
                                color: taskButton.down ? PlasmaTheme.buttonPressed :
                                       modelData.active ? PlasmaTheme.highlightSoft :
                                       taskButton.hovered ? PlasmaTheme.buttonHover : "transparent"

                                Rectangle {
                                    visible: modelData.active
                                    width: 20
                                    height: 2
                                    radius: 1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 1
                                    color: PlasmaTheme.highlight
                                }
                            }

                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                            ToolTip.text: modelData.title

                            TapHandler {
                                acceptedButtons: Qt.RightButton
                                onTapped: taskMenu.popup()
                            }

                            Menu {
                                id: taskMenu
                                MenuItem { text: "Minimize"; onTriggered: PlasmaBackend.minimizeWindow(modelData.id) }
                                MenuItem {
                                    text: modelData.maximized ? "Restore" : "Maximize"
                                    onTriggered: PlasmaBackend.toggleMaximizeWindow(modelData.id)
                                }
                                MenuSeparator {}
                                MenuItem { text: "Close"; onTriggered: PlasmaBackend.closeWindow(modelData.id) }
                            }
                        }
                    }
                }
            }

            Row {
                id: trayRow
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Repeater {
                    model: PlasmaBackend.trayIcons

                    delegate: PlasmaIconButton {
                        id: trayButton
                        required property var modelData
                        width: 30
                        height: 36
                        onClicked: PlasmaBackend.invokeTrayIcon(modelData.key, false)

                        contentItem: Item {
                            Image {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: modelData.icon
                                visible: source.toString().length > 0
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            Label {
                                anchors.centerIn: parent
                                visible: modelData.icon.length === 0
                                text: "•"
                                color: PlasmaTheme.text
                                font.pixelSize: 16
                            }
                        }

                        ToolTip.visible: hovered && modelData.tooltip.length > 0
                        ToolTip.text: modelData.tooltip
                        ToolTip.delay: 500

                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: PlasmaBackend.invokeTrayIcon(modelData.key, true)
                        }
                    }
                }
            }

            PlasmaIconButton {
                id: clipboardButton
                Layout.preferredWidth: 30
                Layout.fillHeight: true
                icon.name: "edit-paste"
                onClicked: panel.clipboardRequested()
                ToolTip.visible: hovered
                ToolTip.text: "Clipboard"
            }

            PlasmaIconButton {
                id: notificationsButton
                Layout.preferredWidth: 30
                Layout.fillHeight: true
                icon.name: PlasmaBackend.notificationHistory.length > 0 ? "notifications" : "notifications-disabled"
                onClicked: panel.notificationCenterRequested()
                ToolTip.visible: hovered
                ToolTip.text: "Notifications"

                Rectangle {
                    visible: PlasmaBackend.notificationHistory.length > 0
                    width: 6
                    height: 6
                    radius: 3
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 3
                    anchors.topMargin: 3
                    color: PlasmaTheme.highlight
                }
            }

            StatusArea {
                onSettingsRequested: function(page) { panel.settingsRequested(page) }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 25
                color: PlasmaTheme.separator
            }

            ToolButton {
                id: clockButton
                Layout.preferredWidth: 94
                Layout.fillHeight: true
                hoverEnabled: true
                onClicked: panel.calendarRequested()
                palette.buttonText: PlasmaTheme.text

                background: Rectangle {
                    radius: PlasmaTheme.itemRadius
                    color: clockButton.down ? PlasmaTheme.buttonPressed : clockButton.hovered ? PlasmaTheme.buttonHover : "transparent"
                }

                contentItem: Column {
                    anchors.centerIn: parent
                    spacing: -2
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: PlasmaBackend.clockText
                        color: PlasmaTheme.text
                        font.family: PlasmaTheme.fontFamily
                        font.pixelSize: 12
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: PlasmaBackend.dateText
                        color: PlasmaTheme.secondaryText
                        font.family: PlasmaTheme.fontFamily
                        font.pixelSize: 9
                    }
                }

                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
            }
        }
    }
}
