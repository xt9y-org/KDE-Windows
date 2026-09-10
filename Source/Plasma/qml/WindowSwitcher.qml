import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: switcher
    visible: PlasmaBackend.windowSwitcherVisible
    width: Math.min(Screen.width - 120, 860)
    height: Math.min(Screen.height - 160, 440)
    x: Screen.virtualX + Math.round((Screen.width - width) / 2)
    y: Screen.virtualY + Math.round((Screen.height - height) / 2)
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool | Qt.WindowDoesNotAcceptFocus
    color: "transparent"

    PlasmaSurface {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Label {
                text: "Windows"
                color: PlasmaTheme.text
                font.family: PlasmaTheme.fontFamily
                font.pixelSize: 13
                Layout.leftMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: PlasmaTheme.separator
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: PlasmaBackend.windows
                cellWidth: 204
                cellHeight: 158

                delegate: Item {
                    id: delegateRoot
                    required property var modelData
                    required property int index
                    width: 196
                    height: 150

                    PlasmaSurface {
                        anchors.fill: parent
                        anchors.margins: 3
                        viewStyle: true
                        selected: index === PlasmaBackend.windowSwitcherIndex
                        radius: 6

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 7

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: PlasmaTheme.itemRadius
                                color: PlasmaTheme.alternate
                                border.color: PlasmaTheme.separator
                                border.width: 1
                                clip: true

                                Image {
                                    id: fallbackIcon
                                    anchors.centerIn: parent
                                    width: 54
                                    height: 54
                                    source: "image://shell/window/" + modelData.id
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                Image {
                                    id: thumbnail
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    source: "image://shell/thumbnail/" + modelData.id
                                    sourceSize.width: 176
                                    sourceSize.height: 100
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    asynchronous: true
                                    cache: false
                                    visible: status === Image.Ready
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Image {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    source: "image://shell/window/" + modelData.id
                                    fillMode: Image.PreserveAspectFit
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: index === PlasmaBackend.windowSwitcherIndex ? PlasmaTheme.highlight : PlasmaTheme.text
                                    font.family: PlasmaTheme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
