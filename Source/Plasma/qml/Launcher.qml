import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: launcher
    objectName: "plasmaLauncher"
    width: 660
    height: 560
    x: panelX + 8
    y: panelY - height - 8
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    property int panelX: 0
    property int panelY: 0
    signal dismissed()
    signal settingsRequested()

    onVisibleChanged: {
        if (visible) {
            search.forceActiveFocus()
            search.selectAll()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#f223272b"
        border.color: "#5a596168"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "Applications"
                    color: "#eff0f1"
                    font.pixelSize: 22
                    font.bold: true
                    Layout.fillWidth: true
                }
                ToolButton {
                    icon.name: "configure"
                    onClicked: {
                        launcher.dismissed()
                        launcher.settingsRequested()
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: "System Settings"
                }
                ToolButton {
                    text: "×"
                    font.pixelSize: 20
                    onClicked: launcher.dismissed()
                    background: Rectangle { radius: 7; color: parent.hovered ? "#384047" : "transparent" }
                    palette.buttonText: "#eff0f1"
                }
            }

            TextField {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search applications…"
                color: "#eff0f1"
                placeholderTextColor: "#929aa1"
                selectByMouse: true
                background: Rectangle {
                    radius: 8
                    color: "#30363c"
                    border.color: search.activeFocus ? "#3daee9" : "#4b535a"
                }
                Keys.onEscapePressed: launcher.dismissed()
                Keys.onReturnPressed: {
                    const entries = PlasmaBackend.searchApplications(text)
                    if (entries.length > 0) {
                        PlasmaBackend.launchApplication(entries[0].id)
                        launcher.dismissed()
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: appList
                    model: PlasmaBackend.searchApplications(search.text)
                    spacing: 3
                    delegate: ItemDelegate {
                        required property var modelData
                        width: appList.width
                        height: 46
                        text: modelData.name
                        icon.source: "image://shell/path/" + encodeURIComponent(modelData.iconPath.length > 0 ? modelData.iconPath : modelData.executable)
                        icon.width: 24
                        icon.height: 24
                        display: AbstractButton.TextBesideIcon
                        palette.buttonText: "#eff0f1"
                        onClicked: {
                            PlasmaBackend.launchApplication(modelData.id)
                            launcher.dismissed()
                        }
                        background: Rectangle {
                            radius: 7
                            color: parent.hovered ? "#374047" : "transparent"
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#4b535a"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                ToolButton { text: "Lock"; onClicked: { PlasmaBackend.lockSession(); launcher.dismissed() } }
                ToolButton { text: "Log Out"; onClicked: PlasmaBackend.logOut() }
                Item { Layout.fillWidth: true }
                ToolButton { text: "Sleep"; onClicked: PlasmaBackend.suspend() }
                ToolButton { text: "Restart"; onClicked: PlasmaBackend.restart() }
                ToolButton { text: "Shut Down"; onClicked: PlasmaBackend.shutDown() }
            }
        }
    }
}
