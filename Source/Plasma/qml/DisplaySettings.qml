import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 14

    Label { text: "Displays"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
    Label {
        text: "Resolution, refresh rate, primary display and supported monitor brightness are controlled natively."
        color: "#aeb5ba"
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 10

            Repeater {
                model: PlasmaBackend.displays

                delegate: Rectangle {
                    id: displayCard
                    required property var modelData
                    property var brightnessInfo: PlasmaBackend.displayBrightness(modelData.id)
                    property var currentMode: PlasmaBackend.currentDisplayMode(modelData.id)
                    property var modes: PlasmaBackend.displayModes(modelData.id)
                    property int selectedMode: -1

                    Layout.fillWidth: true
                    Layout.preferredHeight: brightnessInfo.available ? 202 : 162
                    radius: 10
                    color: "#2b3035"
                    border.color: modelData.primary ? "#3daee9" : "#434b52"

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
                        anchors.margins: 14
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                Layout.fillWidth: true
                                text: modelData.name + (modelData.primary ? "  • Primary" : "")
                                color: "#eff0f1"
                                font.bold: true
                                font.pixelSize: 15
                            }
                            Label {
                                text: displayCard.currentMode.width + "×" + displayCard.currentMode.height +
                                      (displayCard.currentMode.refreshRate > 0 ? " @ " + displayCard.currentMode.refreshRate + " Hz" : "")
                                color: "#aeb5ba"
                            }
                        }

                        Label {
                            text: "Position " + modelData.x + ", " + modelData.y +
                                  "   •   Work area " + modelData.workWidth + "×" + modelData.workHeight
                            color: "#929ba2"
                            font.pixelSize: 11
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Mode"; color: "#d8dcdf"; Layout.preferredWidth: 72 }
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
                            Label { text: "Brightness"; color: "#d8dcdf"; Layout.preferredWidth: 72 }
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
                                color: "#d8dcdf"
                                Layout.preferredWidth: 48
                            }
                        }
                    }
                }
            }
        }
    }
}
