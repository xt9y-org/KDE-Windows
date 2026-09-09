import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: panel
    objectName: "plasmaPanel"
    visible: true
    x: Screen.virtualX
    y: Screen.virtualY + Screen.height - 48
    width: Screen.width
    height: 48
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    signal launcherRequested()

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
                palette.button: hovered ? "#384047" : "transparent"
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
                            required property var modelData
                            width: Math.min(190, Math.max(72, implicitContentWidth + 28))
                            height: 38
                            text: modelData.title
                            font.pixelSize: 13
                            palette.buttonText: modelData.active ? "white" : "#eff0f1"
                            hoverEnabled: true
                            onClicked: {
                                if (modelData.active)
                                    PlasmaBackend.minimizeWindow(modelData.id)
                                else
                                    PlasmaBackend.activateWindow(modelData.id)
                            }
                            background: Rectangle {
                                radius: 7
                                color: modelData.active ? "#4b5964" : parent.hovered ? "#343b41" : "transparent"
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
