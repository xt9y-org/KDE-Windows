import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: runner
    visible: false
    width: 620
    height: 360
    x: Screen.virtualX + Math.round((Screen.width - width) / 2)
    y: Screen.virtualY + 90
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    signal dismissed()

    onVisibleChanged: {
        if (visible) {
            query.forceActiveFocus()
            query.selectAll()
        }
    }

    function executeCurrent() {
        const results = PlasmaBackend.searchApplications(query.text)
        if (results.length > 0) {
            PlasmaBackend.launchApplication(results[0].id)
            dismissed()
            return
        }
        if (PlasmaBackend.runCommand(query.text))
            dismissed()
    }

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

            TextField {
                id: query
                Layout.fillWidth: true
                placeholderText: "Search or run a command…"
                color: "#eff0f1"
                placeholderTextColor: "#929aa1"
                selectByMouse: true
                font.pixelSize: 18
                background: Rectangle {
                    radius: 8
                    color: "#30363c"
                    border.color: query.activeFocus ? "#3daee9" : "#4b535a"
                }
                Keys.onEscapePressed: runner.dismissed()
                Keys.onReturnPressed: runner.executeCurrent()
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: resultList
                    model: PlasmaBackend.searchApplications(query.text)
                    spacing: 3

                    delegate: ItemDelegate {
                        required property var modelData
                        width: resultList.width
                        height: 44
                        text: modelData.name
                        palette.buttonText: "#eff0f1"
                        onClicked: {
                            PlasmaBackend.launchApplication(modelData.id)
                            runner.dismissed()
                        }
                        background: Rectangle {
                            radius: 7
                            color: parent.hovered ? "#374047" : "transparent"
                        }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: query.text.length > 0 && resultList.count === 0 ? "Enter to run command or path" : "Alt+Space"
                color: "#90989f"
                font.pixelSize: 11
            }
        }
    }
}
