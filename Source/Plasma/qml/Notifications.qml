import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: notificationsWindow
    visible: PlasmaBackend.notifications.length > 0
    width: 360
    height: Math.min(390, notificationColumn.implicitHeight + 10)
    x: Screen.virtualX + Screen.width - width - PlasmaTheme.panelMargin
    y: Screen.virtualY + Screen.height - PlasmaTheme.panelHeight - PlasmaTheme.panelMargin * 3 - height
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool | Qt.WindowDoesNotAcceptFocus
    color: "transparent"

    Column {
        id: notificationColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 6

        Repeater {
            model: PlasmaBackend.notifications

            delegate: PlasmaSurface {
                required property var modelData
                width: notificationColumn.width
                implicitHeight: content.implicitHeight + 18

                RowLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 9

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        Layout.alignment: Qt.AlignTop
                        radius: PlasmaTheme.itemRadius
                        color: PlasmaTheme.highlightSoft

                        Label {
                            anchors.centerIn: parent
                            text: "i"
                            font.bold: true
                            font.pixelSize: 16
                            color: PlasmaTheme.highlight
                        }
                    }

                    ColumnLayout {
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
                            visible: modelData.title.length > 0
                            Layout.fillWidth: true
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
                        implicitWidth: 28
                        implicitHeight: 28
                        icon.name: "window-close"
                        onClicked: PlasmaBackend.dismissNotification(modelData.id)
                    }
                }
            }
        }
    }
}
