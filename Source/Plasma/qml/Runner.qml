import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: runner
    visible: false
    width: 660
    height: 310
    x: Screen.virtualX + Math.round((Screen.width - width) / 2)
    y: Screen.virtualY + 72
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    signal dismissed()

    onVisibleChanged: {
        if (visible) {
            query.text = ""
            query.forceActiveFocus()
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

    Keys.onEscapePressed: dismissed()

    PlasmaSurface {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                spacing: 8

                Image {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    source: "image://shell/path/system-search"
                    visible: false
                }

                Label {
                    text: "⌕"
                    color: PlasmaTheme.highlight
                    font.pixelSize: 25
                }

                TextField {
                    id: query
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Search Plasma"
                    color: PlasmaTheme.text
                    placeholderTextColor: PlasmaTheme.secondaryText
                    selectByMouse: true
                    font.family: PlasmaTheme.fontFamily
                    font.pixelSize: 17
                    leftPadding: 10
                    rightPadding: 10
                    background: Rectangle {
                        radius: PlasmaTheme.itemRadius
                        color: PlasmaTheme.view
                        border.color: query.activeFocus ? PlasmaTheme.highlight : PlasmaTheme.frame
                        border.width: query.activeFocus ? 2 : 1
                    }
                    Keys.onEscapePressed: runner.dismissed()
                    Keys.onReturnPressed: runner.executeCurrent()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: PlasmaTheme.separator
            }

            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 1
                model: PlasmaBackend.searchApplications(query.text)

                delegate: PlasmaListDelegate {
                    required property var modelData
                    width: resultList.width
                    height: 42
                    text: modelData.name
                    icon.source: "image://shell/path/" + encodeURIComponent(modelData.iconPath.length > 0 ? modelData.iconPath : modelData.executable)
                    icon.width: 24
                    icon.height: 24
                    display: AbstractButton.TextBesideIcon
                    onClicked: {
                        PlasmaBackend.launchApplication(modelData.id)
                        runner.dismissed()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                Label {
                    Layout.fillWidth: true
                    text: query.text.length > 0 && resultList.count === 0 ? "Press Enter to run command or path" : "Type to search applications"
                    color: PlasmaTheme.secondaryText
                    font.family: PlasmaTheme.fontFamily
                    font.pixelSize: 10
                }
                Label {
                    text: "Alt+Space"
                    color: PlasmaTheme.disabledText
                    font.family: PlasmaTheme.fontFamily
                    font.pixelSize: 10
                }
            }
        }
    }
}
