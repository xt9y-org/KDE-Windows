import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: center
    visible: false
    width: 420
    height: 520
    x: Screen.virtualX + Screen.width - width - 12
    y: Screen.virtualY + Screen.height - height - 58
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    signal dismissed()

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#f223272b"
        border.color: "#5a596168"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "Notifications"
                    color: "#eff0f1"
                    font.pixelSize: 20
                    font.bold: true
                    Layout.fillWidth: true
                }
                ToolButton {
                    text: "Clear"
                    enabled: PlasmaBackend.notificationHistory.length > 0
                    onClicked: PlasmaBackend.clearNotificationHistory()
                }
                ToolButton { text: "×"; onClicked: center.dismissed() }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: history
                    model: PlasmaBackend.notificationHistory
                    spacing: 7

                    delegate: Rectangle {
                        required property var modelData
                        width: history.width
                        implicitHeight: bodyColumn.implicitHeight + 22
                        radius: 9
                        color: "#30363c"
                        border.color: "#495158"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            ColumnLayout {
                                id: bodyColumn
                                Layout.fillWidth: true
                                spacing: 3
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.title.length > 0 ? modelData.title : modelData.source
                                    color: "#eff0f1"
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Label {
                                    visible: modelData.source.length > 0 && modelData.title.length > 0
                                    Layout.fillWidth: true
                                    text: modelData.source
                                    color: "#9da5ab"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.body
                                    color: "#d9dcde"
                                    wrapMode: Text.Wrap
                                }
                                Label {
                                    text: modelData.timestamp
                                    color: "#899198"
                                    font.pixelSize: 10
                                }
                            }

                            ToolButton {
                                Layout.alignment: Qt.AlignTop
                                text: "×"
                                onClicked: PlasmaBackend.removeNotificationHistory(modelData.id)
                            }
                        }
                    }
                }
            }

            Label {
                visible: PlasmaBackend.notificationHistory.length === 0
                text: "No notifications"
                color: "#90989f"
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
