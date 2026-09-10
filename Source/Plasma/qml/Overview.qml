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
    color: PlasmaTheme.dark ? "#dc171a1d" : "#dce8ecef"

    signal dismissed()

    Keys.onEscapePressed: dismissed()
    onVisibleChanged: if (visible) {
        requestActivate()
        overviewSearch.text = ""
        overviewSearch.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 34
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Label {
                text: "Overview"
                color: PlasmaTheme.text
                font.family: PlasmaTheme.fontFamily
                font.pixelSize: 22
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            TextField {
                id: overviewSearch
                Layout.preferredWidth: Math.min(420, overview.width * 0.38)
                Layout.preferredHeight: 38
                placeholderText: "Search…"
                color: PlasmaTheme.text
                placeholderTextColor: PlasmaTheme.secondaryText
                selectByMouse: true
                background: Rectangle {
                    radius: PlasmaTheme.itemRadius
                    color: PlasmaTheme.view
                    border.color: overviewSearch.activeFocus ? PlasmaTheme.highlight : PlasmaTheme.frame
                    border.width: overviewSearch.activeFocus ? 2 : 1
                }
                Keys.onEscapePressed: overview.dismissed()
                Keys.onReturnPressed: {
                    const results = PlasmaBackend.searchApplications(text)
                    if (results.length > 0) {
                        PlasmaBackend.launchApplication(results[0].id)
                        overview.dismissed()
                    }
                }
            }

            Item { Layout.fillWidth: true }

            PlasmaIconButton {
                icon.name: "window-close"
                onClicked: overview.dismissed()
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 286
            cellHeight: 188
            model: PlasmaBackend.windows
            clip: true

            delegate: Item {
                id: windowDelegate
                required property var modelData
                width: 274
                height: 176

                PlasmaSurface {
                    anchors.fill: parent
                    anchors.margins: 4
                    viewStyle: true
                    selected: modelData.active
                    radius: 7

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: PlasmaTheme.itemRadius
                            color: hover.containsMouse ? PlasmaTheme.buttonHover : PlasmaTheme.alternate
                            border.color: PlasmaTheme.separator
                            border.width: 1
                            clip: true

                            Image {
                                anchors.centerIn: parent
                                width: 64
                                height: 64
                                source: "image://shell/window/" + modelData.id
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            Image {
                                anchors.fill: parent
                                anchors.margins: 1
                                source: "image://shell/thumbnail/" + modelData.id
                                sourceSize.width: 250
                                sourceSize.height: 122
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                cache: false
                                visible: status === Image.Ready
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    PlasmaBackend.activateWindow(modelData.id)
                                    overview.dismissed()
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Image {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                source: "image://shell/window/" + modelData.id
                                fillMode: Image.PreserveAspectFit
                            }
                            Label {
                                Layout.fillWidth: true
                                text: modelData.title
                                color: PlasmaTheme.text
                                font.family: PlasmaTheme.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                            PlasmaIconButton {
                                implicitWidth: 26
                                implicitHeight: 26
                                icon.name: "window-close"
                                onClicked: PlasmaBackend.closeWindow(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            Button { text: "Previous Desktop"; onClicked: PlasmaBackend.virtualDesktopLeft() }
            Button { text: "New Desktop"; onClicked: PlasmaBackend.virtualDesktopCreate() }
            Button { text: "Next Desktop"; onClicked: PlasmaBackend.virtualDesktopRight() }
        }
    }
}
