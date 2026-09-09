import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: notificationsWindow
    visible: PlasmaBackend.notifications.length > 0
    width: 380
    height: Math.min(360, notificationColumn.implicitHeight + 16)
    x: Screen.virtualX + Screen.width - width - 12
    y: Screen.virtualY + Screen.height - 48 - height - 12
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool | Qt.WindowDoesNotAcceptFocus
    color: "transparent"

    Column {
        id: notificationColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 8

        Repeater {
            model: PlasmaBackend.notifications

            delegate: Rectangle {
                required property var modelData
                width: notificationColumn.width
                implicitHeight: content.implicitHeight + 20
                radius: 10
                color: "#f22b3035"
                border.color: "#5a626a72"
                border.width: 1

                RowLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignTop
                        radius: 8
                        color: "#343c43"

                        Label {
                            anchors.centerIn: parent
                            text: "i"
                            font.bold: true
                            font.pixelSize: 18
                            color: "#3daee9"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                Layout.fillWidth: true
                                text: modelData.title.length > 0 ? modelData.title : modelData.source
                                color: "#eff0f1"
                                font.bold: true
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            Label {
                                text: modelData.timestamp
                                color: "#9da5ab"
                                font.pixelSize: 10
                            }
                        }

                        Label {
                            visible: modelData.source.length > 0 && modelData.title.length > 0
                            text: modelData.source
                            color: "#9da5ab"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: modelData.body
                            color: "#d9dcde"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }

                    ToolButton {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignTop
                        text: "×"
                        onClicked: PlasmaBackend.dismissNotification(modelData.id)
                        background: Rectangle {
                            radius: 6
                            color: parent.hovered ? "#424a51" : "transparent"
                        }
                        contentItem: Label {
                            text: parent.text
                            color: "#cfd3d6"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 16
                        }
                    }
                }
            }
        }
    }
}
