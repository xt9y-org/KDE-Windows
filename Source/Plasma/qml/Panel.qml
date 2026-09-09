import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: panel
    objectName: "plasmaPanel"
    visible: true
    x: displayData && displayData.x !== undefined ? displayData.x : Screen.virtualX
    y: (displayData && displayData.y !== undefined ? displayData.y : Screen.virtualY) +
       (displayData && displayData.height ? displayData.height : Screen.height) - height
    width: displayData && displayData.width ? displayData.width : Screen.width
    height: 48
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    property var displayData: ({})
    signal launcherRequested()
    signal clipboardRequested()
    signal notificationCenterRequested()

    Rectangle {
        anchors.fill: parent
        color: "#e6262a2e"
        border.color: "#443f444a"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 8
            spacing: 5

            ToolButton {
                id: launcherButton
                Layout.preferredWidth: 42
                Layout.preferredHeight: 38
                text: "K"
                font.pixelSize: 18
                font.bold: true
                palette.buttonText: "#eff0f1"
                onClicked: panel.launcherRequested()
                background: Rectangle {
                    radius: 7
                    color: launcherButton.down ? "#4a555e" : launcherButton.hovered ? "#384047" : "transparent"
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 26
                color: "#495057"
            }

            Flickable {
                id: taskArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: taskRow.implicitWidth
                clip: true

                Row {
                    id: taskRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: PlasmaBackend.windows
                        delegate: ToolButton {
                            id: taskButton
                            required property var modelData
                            width: Math.min(220, Math.max(76, taskContent.implicitWidth + 22))
                            height: 38
                            hoverEnabled: true
                            onClicked: {
                                if (modelData.active)
                                    PlasmaBackend.minimizeWindow(modelData.id)
                                else
                                    PlasmaBackend.activateWindow(modelData.id)
                            }

                            contentItem: RowLayout {
                                id: taskContent
                                spacing: 7

                                Image {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    source: "image://shell/window/" + modelData.id
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                Label {
                                    Layout.maximumWidth: 164
                                    text: modelData.title
                                    color: modelData.active ? "white" : "#eff0f1"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }

                            background: Rectangle {
                                radius: 7
                                color: modelData.active ? "#4b5964" : taskButton.hovered ? "#343b41" : "transparent"
                                Rectangle {
                                    visible: modelData.active
                                    width: Math.min(parent.width - 20, 36)
                                    height: 2
                                    radius: 1
                                    color: "#3daee9"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2
                                }
                            }

                            TapHandler {
                                acceptedButtons: Qt.RightButton
                                onTapped: taskMenu.popup()
                            }

                            Menu {
                                id: taskMenu
                                MenuItem { text: "Minimize"; onTriggered: PlasmaBackend.minimizeWindow(modelData.id) }
                                MenuItem { text: modelData.maximized ? "Restore" : "Maximize"; onTriggered: PlasmaBackend.toggleMaximizeWindow(modelData.id) }
                                MenuSeparator {}
                                MenuItem { text: "Close"; onTriggered: PlasmaBackend.closeWindow(modelData.id) }
                            }
                        }
                    }
                }
            }

            Flickable {
                id: trayArea
                Layout.preferredWidth: Math.min(220, trayRow.implicitWidth)
                Layout.fillHeight: true
                contentWidth: trayRow.implicitWidth
                clip: true

                Row {
                    id: trayRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                        model: PlasmaBackend.trayIcons

                        delegate: ToolButton {
                            id: trayButton
                            required property var modelData
                            width: 32
                            height: 38
                            hoverEnabled: true
                            onClicked: PlasmaBackend.invokeTrayIcon(modelData.key, false)

                            background: Rectangle {
                                radius: 6
                                color: trayButton.down ? "#4a555e" : trayButton.hovered ? "#384047" : "transparent"
                            }

                            contentItem: Item {
                                Image {
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: modelData.icon
                                    visible: source.toString().length > 0
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                                Label {
                                    anchors.centerIn: parent
                                    visible: modelData.icon.length === 0
                                    text: "•"
                                    color: "#d9dcde"
                                    font.pixelSize: 18
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
            }

            ToolButton {
                id: clipboardButton
                Layout.preferredWidth: 34
                Layout.preferredHeight: 38
                text: "⧉"
                font.pixelSize: 17
                hoverEnabled: true
                onClicked: panel.clipboardRequested()
                ToolTip.visible: hovered
                ToolTip.text: "Clipboard"
                background: Rectangle {
                    radius: 6
                    color: clipboardButton.down ? "#4a555e" : clipboardButton.hovered ? "#384047" : "transparent"
                }
            }

            ToolButton {
                id: notificationsButton
                Layout.preferredWidth: 34
                Layout.preferredHeight: 38
                text: "N"
                font.pixelSize: 14
                font.bold: PlasmaBackend.notificationHistory.length > 0
                hoverEnabled: true
                onClicked: panel.notificationCenterRequested()
                ToolTip.visible: hovered
                ToolTip.text: "Notifications"
                background: Rectangle {
                    radius: 6
                    color: notificationsButton.down ? "#4a555e" : notificationsButton.hovered ? "#384047" : "transparent"
                }

                Rectangle {
                    visible: PlasmaBackend.notificationHistory.length > 0
                    width: 8
                    height: 8
                    radius: 4
                    color: "#3daee9"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 4
                    anchors.topMargin: 4
                }
            }

            StatusArea {}

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 26
                color: "#495057"
            }

            ColumnLayout {
                Layout.preferredWidth: 104
                Layout.fillHeight: true
                spacing: -2
                Label {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    text: PlasmaBackend.clockText
                    color: "#eff0f1"
                    font.pixelSize: 13
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    text: PlasmaBackend.dateText
                    color: "#b7bdc2"
                    font.pixelSize: 10
                }
            }
        }
    }
}
