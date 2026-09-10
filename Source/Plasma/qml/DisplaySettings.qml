import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 12

    Label {
        text: "Display & Monitor"
        color: PlasmaTheme.text
        font.family: PlasmaTheme.fontFamily
        font.pixelSize: 20
        font.bold: true
    }
    Label {
        text: "Display Configuration"
        color: PlasmaTheme.secondaryText
        font.family: PlasmaTheme.fontFamily
        font.pixelSize: 11
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 8

            Repeater {
                model: PlasmaBackend.displays

                delegate: PlasmaSurface {
                    id: displayCard
                    required property var modelData
                    property var brightnessInfo: PlasmaBackend.displayBrightness(modelData.id)
                    property var currentMode: PlasmaBackend.currentDisplayMode(modelData.id)
                    property var modes: PlasmaBackend.displayModes(modelData.id)
                    property int selectedMode: -1

                    Layout.fillWidth: true
                    Layout.preferredHeight: brightnessInfo.available ? 188 : 146
                    viewStyle: true
                    selected: modelData.primary

                    function selectCurrentMode() {
                        selectedMode = -1
                        for (let i = 0; i < modes.length; ++i) {
                            if (modes[i].width === currentMode.width &&
                                modes[i].height === currentMode.height &&
                                modes[i].refreshRate === currentMode.refreshRate) {
                                selectedMode = i
                                break
                            }
                        }
                    }

                    Component.onCompleted: selectCurrentMode()
                    onCurrentModeChanged: selectCurrentMode()

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Rectangle {
                                Layout.preferredWidth: 42
                                Layout.preferredHeight: 28
                                radius: 3
                                color: PlasmaTheme.alternate
                                border.color: modelData.primary ? PlasmaTheme.highlight : PlasmaTheme.frame
                                border.width: modelData.primary ? 2 : 1
                                Label {
                                    anchors.centerIn: parent
                                    text: "1"
                                    color: PlasmaTheme.text
                                    font.pixelSize: 11
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: PlasmaTheme.text
                                    font.family: PlasmaTheme.fontFamily
                                    font.bold: true
                                    font.pixelSize: 13
                                }
                                Label {
                                    text: modelData.primary ? "Primary display" : "Display"
                                    color: modelData.primary ? PlasmaTheme.highlight : PlasmaTheme.secondaryText
                                    font.pixelSize: 10
                                }
                            }
                            Label {
                                text: displayCard.currentMode.width + "×" + displayCard.currentMode.height +
                                      (displayCard.currentMode.refreshRate > 0 ? " @ " + displayCard.currentMode.refreshRate + " Hz" : "")
                                color: PlasmaTheme.secondaryText
                                font.pixelSize: 10
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: PlasmaTheme.separator
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Resolution & refresh rate:"; color: PlasmaTheme.text; Layout.preferredWidth: 145 }
                            ComboBox {
                                id: modeBox
                                Layout.fillWidth: true
                                model: displayCard.modes
                                textRole: "label"
                                currentIndex: displayCard.selectedMode
                            }
                            Button {
                                text: "Apply"
                                enabled: modeBox.currentIndex >= 0
                                onClicked: {
                                    const mode = displayCard.modes[modeBox.currentIndex]
                                    if (mode && PlasmaBackend.setDisplayMode(modelData.id, mode.width, mode.height, mode.refreshRate)) {
                                        displayCard.currentMode = PlasmaBackend.currentDisplayMode(modelData.id)
                                        displayCard.selectCurrentMode()
                                    }
                                }
                            }
                            Button {
                                visible: !modelData.primary
                                text: "Make Primary"
                                onClicked: PlasmaBackend.setPrimaryDisplay(modelData.id)
                            }
                        }

                        RowLayout {
                            visible: displayCard.brightnessInfo.available
                            Layout.fillWidth: true
                            Label { text: "Brightness:"; color: PlasmaTheme.text; Layout.preferredWidth: 145 }
                            Slider {
                                id: brightnessSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: displayCard.brightnessInfo.percent
                                onMoved: PlasmaBackend.setDisplayBrightness(modelData.id, Math.round(value))
                            }
                            Label {
                                text: Math.round(brightnessSlider.value) + "%"
                                color: PlasmaTheme.text
                                Layout.preferredWidth: 44
                            }
                        }
                    }
                }
            }
        }
    }
}
