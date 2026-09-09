import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 2

    ToolButton {
        id: networkButton
        Layout.preferredWidth: 34
        Layout.preferredHeight: 38
        hoverEnabled: true
        text: PlasmaBackend.networkConnected ? (PlasmaBackend.wifi ? "◉" : "◆") : "×"
        font.pixelSize: 14
        palette.buttonText: PlasmaBackend.networkConnected ? "#eff0f1" : "#da4453"
        background: Rectangle {
            radius: 6
            color: networkButton.hovered ? "#384047" : "transparent"
        }
        ToolTip.visible: hovered
        ToolTip.delay: 400
        ToolTip.text: PlasmaBackend.networkConnected
            ? PlasmaBackend.networkName + (PlasmaBackend.wifi ? "  " + PlasmaBackend.networkSignal + "%" : "")
            : "Disconnected"
    }

    ToolButton {
        id: batteryButton
        visible: PlasmaBackend.batteryAvailable
        Layout.preferredWidth: 58
        Layout.preferredHeight: 38
        hoverEnabled: true
        text: (PlasmaBackend.charging ? "⚡ " : "") + PlasmaBackend.batteryPercent + "%"
        font.pixelSize: 11
        palette.buttonText: PlasmaBackend.batteryPercent >= 0 && PlasmaBackend.batteryPercent <= 15 && !PlasmaBackend.charging
            ? "#da4453" : "#eff0f1"
        background: Rectangle {
            radius: 6
            color: batteryButton.hovered ? "#384047" : "transparent"
        }
        ToolTip.visible: hovered
        ToolTip.delay: 400
        ToolTip.text: PlasmaBackend.charging ? "Charging" : (PlasmaBackend.onAc ? "AC power" : "Battery")
    }

    ToolButton {
        id: volumeButton
        visible: PlasmaBackend.audioAvailable
        Layout.preferredWidth: 58
        Layout.preferredHeight: 38
        hoverEnabled: true
        text: PlasmaBackend.muted ? "Mute" : PlasmaBackend.volume + "%"
        font.pixelSize: 11
        palette.buttonText: "#eff0f1"
        onClicked: volumePopup.open()
        background: Rectangle {
            radius: 6
            color: volumeButton.down ? "#4a555e" : volumeButton.hovered ? "#384047" : "transparent"
        }

        Popup {
            id: volumePopup
            width: 250
            height: 94
            x: volumeButton.width - width
            y: -height - 8
            padding: 12

            background: Rectangle {
                radius: 10
                color: "#f22b3035"
                border.color: "#5a626a72"
                border.width: 1
            }

            RowLayout {
                anchors.fill: parent
                spacing: 10

                ToolButton {
                    Layout.preferredWidth: 52
                    text: PlasmaBackend.muted ? "Unmute" : "Mute"
                    onClicked: PlasmaBackend.toggleMute()
                }

                Slider {
                    id: volumeSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: PlasmaBackend.volume
                    live: true
                    onMoved: PlasmaBackend.setVolume(Math.round(value))
                }

                Label {
                    Layout.preferredWidth: 34
                    text: PlasmaBackend.volume + "%"
                    color: "#eff0f1"
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
