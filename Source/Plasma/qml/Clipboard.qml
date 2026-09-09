import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: clipboard
    visible: false
    width: 500
    height: 420
    x: Screen.virtualX + Screen.width - width - 18
    y: Screen.virtualY + Screen.height - height - 62
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
                    text: "Clipboard"
                    color: "#eff0f1"
                    font.pixelSize: 20
                    font.bold: true
                    Layout.fillWidth: true
                }
                ToolButton {
                    text: "Clear"
                    onClicked: PlasmaBackend.clearClipboardHistory()
                }
                ToolButton {
                    text: "×"
                    onClicked: clipboard.dismissed()
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: history
                    model: PlasmaBackend.clipboardEntries
                    spacing: 4

                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        width: history.width
                        height: Math.max(52, textLabel.implicitHeight + 18)
                        radius: 7
                        color: mouse.containsMouse ? "#374047" : "#2d3338"

                        Label {
                            id: textLabel
                            anchors.left: parent.left
                            anchors.right: removeButton.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            text: modelData
                            color: "#eff0f1"
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                        }

                        ToolButton {
                            id: removeButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 5
                            width: 34
                            height: 34
                            text: "×"
                            onClicked: PlasmaBackend.removeClipboardEntry(index)
                        }

                        MouseArea {
                            id: mouse
                            anchors.left: parent.left
                            anchors.right: removeButton.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            hoverEnabled: true
                            onClicked: {
                                PlasmaBackend.activateClipboardEntry(index)
                                clipboard.dismissed()
                            }
                        }
                    }
                }
            }

            Label {
                visible: PlasmaBackend.clipboardEntries.length === 0
                text: "Clipboard history is empty"
                color: "#90989f"
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
