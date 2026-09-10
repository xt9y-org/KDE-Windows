import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: center
    visible: false
    width: 350
    height: 520
    x: Screen.virtualX + Screen.width - width - PlasmaTheme.panelMargin
    y: Screen.virtualY + Screen.height - height - PlasmaTheme.panelHeight - PlasmaTheme.panelMargin * 3
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    signal dismissed()

    onVisibleChanged: if (visible) requestActivate()
    Keys.onEscapePressed: dismissed()

    PlasmaSurface {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                spacing: 4

                PlasmaIconButton {
                    icon.name: "notifications"
                    enabled: false
                }

                Label {
                    text: "Notifications"
                    color: PlasmaTheme.text
                    font.family: PlasmaTheme.fontFamily
                    font.pixelSize: 15
                    Layout.fillWidth: true
                }

                PlasmaIconButton {
                    icon.name: "edit-clear-history"
                    enabled: PlasmaBackend.notificationHistory.length > 0
                    onClicked: PlasmaBackend.clearNotificationHistory()
                    ToolTip.visible: hovered
                    ToolTip.text: "Clear All Notifications"
                }

                PlasmaIconButton {
                    icon.name: "window-close"
                    onClicked: center.dismissed()
                    ToolTip.visible: hovered
                    ToolTip.text: "Close"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: PlasmaTheme.separator
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 8

                Switch {
                    id: dndSwitch
                    checked: false
                    enabled: false
                }
                Label {
                    text: "Do not disturb"
                    color: PlasmaTheme.secondaryText
                    font.family: PlasmaTheme.fontFamily
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: PlasmaTheme.separator
            }

            ListView {
                id: history
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: PlasmaBackend.notificationHistory
                spacing: 0

                delegate: Item {
                    id: notificationDelegate
                    required property var modelData
                    width: history.width
                    height: Math.max(94, bodyColumn.implicitHeight + 22)

                    Rectangle {
                        anchors.fill: parent
                        color: hover.containsMouse ? PlasmaTheme.buttonHover : "transparent"
                        radius: PlasmaTheme.itemRadius
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignTop
                            radius: 4
                            color: PlasmaTheme.highlightSoft

                            Label {
                                anchors.centerIn: parent
                                text: "i"
                                color: PlasmaTheme.highlight
                                font.bold: true
                                font.pixelSize: 16
                            }
                        }

                        ColumnLayout {
                            id: bodyColumn
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.source.length > 0 ? modelData.source : "Notification"
                                    color: PlasmaTheme.secondaryText
                                    font.family: PlasmaTheme.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                                Label {
                                    text: modelData.timestamp
                                    color: PlasmaTheme.disabledText
                                    font.pixelSize: 10
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                visible: modelData.title.length > 0
                                text: modelData.title
                                color: PlasmaTheme.text
                                font.family: PlasmaTheme.fontFamily
                                font.bold: true
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData.body
                                color: PlasmaTheme.text
                                font.family: PlasmaTheme.fontFamily
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                        }

                        PlasmaIconButton {
                            Layout.alignment: Qt.AlignTop
                            icon.name: "window-close"
                            implicitWidth: 28
                            implicitHeight: 28
                            onClicked: PlasmaBackend.removeNotificationHistory(modelData.id)
                        }
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: PlasmaTheme.separator
                    }
                }
            }

            Label {
                visible: PlasmaBackend.notificationHistory.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "No new notifications"
                color: PlasmaTheme.secondaryText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: PlasmaTheme.fontFamily
            }
        }
    }
}
