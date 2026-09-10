import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: clipboard
    visible: false
    width: 390
    height: 440
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
                Layout.preferredHeight: 40
                spacing: 4

                PlasmaIconButton {
                    icon.name: "edit-paste"
                    enabled: false
                }
                Label {
                    text: "Clipboard"
                    color: PlasmaTheme.text
                    font.family: PlasmaTheme.fontFamily
                    font.pixelSize: 15
                    Layout.fillWidth: true
                }
                PlasmaIconButton {
                    icon.name: "edit-clear-history"
                    enabled: PlasmaBackend.clipboardEntries.length > 0
                    onClicked: PlasmaBackend.clearClipboardHistory()
                    ToolTip.visible: hovered
                    ToolTip.text: "Clear Clipboard History"
                }
                PlasmaIconButton {
                    icon.name: "window-close"
                    onClicked: clipboard.dismissed()
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
                model: PlasmaBackend.clipboardEntries
                spacing: 1

                delegate: Item {
                    id: entry
                    required property string modelData
                    required property int index
                    width: history.width
                    height: Math.max(48, textLabel.implicitHeight + 18)

                    Rectangle {
                        anchors.fill: parent
                        radius: PlasmaTheme.itemRadius
                        color: mouse.containsMouse ? PlasmaTheme.buttonHover : "transparent"
                    }

                    Label {
                        id: textLabel
                        anchors.left: parent.left
                        anchors.right: removeButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        text: modelData
                        color: PlasmaTheme.text
                        font.family: PlasmaTheme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                    }

                    PlasmaIconButton {
                        id: removeButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 4
                        implicitWidth: 28
                        implicitHeight: 28
                        icon.name: "window-close"
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

            Label {
                visible: PlasmaBackend.clipboardEntries.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "Clipboard history is empty"
                color: PlasmaTheme.secondaryText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: PlasmaTheme.fontFamily
            }
        }
    }
}
