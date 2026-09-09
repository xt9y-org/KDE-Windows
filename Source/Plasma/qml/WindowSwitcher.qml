import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: switcher
    visible: PlasmaBackend.windowSwitcherVisible
    width: Math.min(Screen.width - 80, Math.max(420, row.implicitWidth + 36))
    height: 154
    x: Screen.virtualX + Math.round((Screen.width - width) / 2)
    y: Screen.virtualY + Math.round((Screen.height - height) / 2)
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#f223272b"
        border.color: "#5a596168"
        border.width: 1

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: PlasmaBackend.windows

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: 132
                    height: 112
                    radius: 9
                    color: index === PlasmaBackend.windowSwitcherIndex ? "#4b5964" : "#30363c"
                    border.color: index === PlasmaBackend.windowSwitcherIndex ? "#3daee9" : "#434b52"
                    border.width: index === PlasmaBackend.windowSwitcherIndex ? 2 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 6

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            source: "image://shell/window/" + modelData.id
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData.title
                            horizontalAlignment: Text.AlignHCenter
                            color: "#eff0f1"
                            elide: Text.ElideRight
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
