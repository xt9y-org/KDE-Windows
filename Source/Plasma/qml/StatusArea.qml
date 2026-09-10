import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 0
    signal settingsRequested(int page)

    property var bluetooth: ({ "available": false, "devices": [] })

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.bluetooth = PlasmaBackend.bluetoothState()
    }

    PlasmaIconButton {
        id: networkButton
        Layout.preferredWidth: 30
        Layout.preferredHeight: 36
        icon.name: PlasmaBackend.networkConnected
                   ? (PlasmaBackend.wifi ? "network-wireless" : "network-wired")
                   : "network-disconnect"
        onClicked: root.settingsRequested(2)
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: PlasmaBackend.networkConnected
                      ? PlasmaBackend.networkName + (PlasmaBackend.wifi ? "  " + PlasmaBackend.networkSignal + "%" : "")
                      : "Disconnected"
    }

    PlasmaIconButton {
        id: bluetoothButton
        visible: root.bluetooth.available
        Layout.preferredWidth: 30
        Layout.preferredHeight: 36
        icon.name: "preferences-system-bluetooth"
        onClicked: root.settingsRequested(3)
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: root.bluetooth.radioName || "Bluetooth"
    }

    PlasmaIconButton {
        id: batteryButton
        visible: PlasmaBackend.batteryAvailable
        Layout.preferredWidth: 30
        Layout.preferredHeight: 36
        icon.name: PlasmaBackend.charging ? "battery-100-charging" :
                   PlasmaBackend.batteryPercent <= 15 ? "battery-caution" :
                   PlasmaBackend.batteryPercent <= 40 ? "battery-040" :
                   PlasmaBackend.batteryPercent <= 70 ? "battery-060" : "battery-100"
        icon.color: PlasmaBackend.batteryPercent >= 0 && PlasmaBackend.batteryPercent <= 15 && !PlasmaBackend.charging
                    ? PlasmaTheme.negative : PlasmaTheme.text
        onClicked: root.settingsRequested(5)
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: PlasmaBackend.batteryPercent + "% — " +
                      (PlasmaBackend.charging ? "Charging" : PlasmaBackend.onAc ? "AC power" : "Battery")
    }

    PlasmaIconButton {
        id: volumeButton
        visible: PlasmaBackend.audioAvailable
        Layout.preferredWidth: 30
        Layout.preferredHeight: 36
        icon.name: PlasmaBackend.muted || PlasmaBackend.volume === 0 ? "audio-volume-muted" :
                   PlasmaBackend.volume < 35 ? "audio-volume-low" :
                   PlasmaBackend.volume < 70 ? "audio-volume-medium" : "audio-volume-high"
        onClicked: volumePopup.open()
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: PlasmaBackend.muted ? "Audio Muted" : "Volume " + PlasmaBackend.volume + "%"

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: root.settingsRequested(4)
        }

        Popup {
            id: volumePopup
            width: 330
            height: 146
            x: volumeButton.width - width
            y: -height - 8
            padding: 0

            background: PlasmaSurface {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Audio Volume"
                        color: PlasmaTheme.text
                        font.family: PlasmaTheme.fontFamily
                        font.pixelSize: 16
                        Layout.fillWidth: true
                    }
                    PlasmaIconButton {
                        icon.name: "configure"
                        onClicked: {
                            volumePopup.close()
                            root.settingsRequested(4)
                        }
                        ToolTip.visible: hovered
                        ToolTip.text: "Configure Audio Devices"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: PlasmaTheme.separator
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    PlasmaIconButton {
                        icon.name: PlasmaBackend.muted ? "audio-volume-muted" : "audio-volume-high"
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
                        Layout.preferredWidth: 42
                        text: PlasmaBackend.volume + "%"
                        color: PlasmaTheme.text
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }

    PlasmaIconButton {
        id: settingsButton
        Layout.preferredWidth: 30
        Layout.preferredHeight: 36
        icon.name: "configure"
        onClicked: root.settingsRequested(0)
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: "System Settings"
    }
}
