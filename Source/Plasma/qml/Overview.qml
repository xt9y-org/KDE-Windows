import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: overview
    visible: false
    x: Screen.virtualX
    y: Screen.virtualY
    width: Screen.width
    height: Screen.height
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "#d91d2024"

    signal dismissed()

    Keys.onEscapePressed: dismissed()

    Component.onCompleted: if (visible) requestActivate()
    onVisibleChanged: if (visible) requestActivate()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 42
        spacing: 22

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "Overview"
                color: "#eff0f1"
                font.pixelSize: 28
                font.bold: true
                Layout.fillWidth: true
            }
            ToolButton {
                text: "×"
                font.pixelSize: 22
                onClicked: overview.dismissed()
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 280
            cellHeight: 180
            model: PlasmaBackend.windows
            clip: true

            delegate: Rectangle {
                required property var modelData
                width: 260
                height: 160
                radius: 12
                color: mouse.containsMouse ? "#48535c" : "#30363c"
                border.color: modelData.active ? "#3daee9" : "#525b63"
                border.width: modelData.active ? 2 : 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: "#252a2e"
                        Label {
                            anchors.centerIn: parent
                            text: modelData.title.length > 0 ? modelData.title.charAt(0).toUpperCase() : "?"
                            color: "#dfe3e6"
                            font.pixelSize: 42
                            font.bold: true
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: modelData.title
                        color: "#eff0f1"
                        elide: Text.ElideRight
                        font.pixelSize: 13
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        PlasmaBackend.activateWindow(modelData.id)
                        overview.dismissed()
                    }
                }
            }
        }
    }
}
