import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 0
    signal settingsRequested(int page)

    property var network: ({ "enabled": false, "connected": false, "name": "", "networks": [] })
    property var bluetooth: ({ "available": false, "devices": [] })

    function refreshStatus() {
        network = PlasmaBackend.wifiState()
        bluetooth = PlasmaBackend.bluetoothState()
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }

    PlasmaIconButton {
        id: networkButton
        Layout.preferredWidth: 30
        Layout.preferredHeight: 36
        icon.name: PlasmaBackend.networkConnected
                   ? (PlasmaBackend.wifi ? "network-wireless" : "network-wired")
                   : "network-disconnect"
        onClicked: {
            root.network = PlasmaBackend.wifiState()
            networkPopup.open()
        }
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: PlasmaBackend.networkConnected
                      ? PlasmaBackend.networkName + (PlasmaBackend.wifi ? "  " + PlasmaBackend.networkSignal + "%" : "")
                      : "Disconnected"

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: root.settingsRequested(2)
        }

        Popup {
            id: networkPopup
            width: 340
            height: 390
            x: networkButton.width - width
            y: -height - 8
            padding: 0

            background: PlasmaSurface {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Networks"
                        color: PlasmaTheme.text
                        font.family: PlasmaTheme.fontFamily
                        font.pixelSize: 15
                        Layout.fillWidth: true
                    }
                    Switch {
                        checked: root.network.enabled
                        onToggled: {
                            PlasmaBackend.setWifiEnabled(checked)
                            root.network = PlasmaBackend.wifiState()
                        }
                    }
                    PlasmaIconButton {
                        icon.name: "configure"
                        onClicked: {
                            networkPopup.close()
                            root.settingsRequested(2)
                        }
                        ToolTip.visible: hovered
                        ToolTip.text: "Configure Network Connections"
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: PlasmaTheme.separator }

                Label {
                    Layout.fillWidth: true
                    text: root.network.connected ? "Connected to " + root.network.name : "Available Networks"
                    color: root.network.connected ? PlasmaTheme.positive : PlasmaTheme.secondaryText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    model: root.network.networks || []

                    delegate: PlasmaListDelegate {
                        required property var modelData
                        width: ListView.view.width
                        height: 48
                        current: modelData.connected
                        text: modelData.name
                        icon.name: "network-wireless"
                        display: AbstractButton.TextBesideIcon
                        onClicked: {
                            if (modelData.connected)
                                return
                            if (modelData.known)
                                PlasmaBackend.connectWifi(modelData.id)
                            else if (!modelData.secure)
                                PlasmaBackend.connectWifiPassword(modelData.id, "")
                            else {
                                networkPopup.close()
                                root.settingsRequested(2)
                                return
                            }
                            root.network = PlasmaBackend.wifiState()
                        }

                        Label {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.signal + "%"
                            color: parent.current ? PlasmaTheme.highlightedText : PlasmaTheme.secondaryText
                            font.pixelSize: 9
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    visible: root.network.connected
                    text: "Disconnect"
                    onClicked: {
                        PlasmaBackend.disconnectWifi()
                        root.network = PlasmaBackend.wifiState()
                    }
                }
            }
        }
    }

    PlasmaIconButton {
        id: bluetoothButton
        visible: root.bluetooth.available
        Layout.preferredWidth: 30
        Layout.preferredHeight: 36
        icon.name: "preferences-system-bluetooth"
        onClicked: {
            root.bluetooth = PlasmaBackend.bluetoothState()
            bluetoothPopup.open()
        }
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: root.bluetooth.radioName || "Bluetooth"

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: root.settingsRequested(3)
        }

        Popup {
            id: bluetoothPopup
            width: 340
            height: 360
            x: bluetoothButton.width - width
            y: -height - 8
            padding: 0

            background: PlasmaSurface {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Bluetooth"
                        color: PlasmaTheme.text
                        font.family: PlasmaTheme.fontFamily
                        font.pixelSize: 15
                        Layout.fillWidth: true
                    }
                    PlasmaIconButton {
                        icon.name: "view-refresh"
                        onClicked: root.bluetooth = PlasmaBackend.bluetoothScan()
                        ToolTip.visible: hovered
                        ToolTip.text: "Scan for Devices"
                    }
                    PlasmaIconButton {
                        icon.name: "configure"
                        onClicked: {
                            bluetoothPopup.close()
                            root.settingsRequested(3)
                        }
                        ToolTip.visible: hovered
                        ToolTip.text: "Configure Bluetooth"
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: PlasmaTheme.separator }

                Label {
                    Layout.fillWidth: true
                    text: root.bluetooth.radioName || "Bluetooth Devices"
                    color: PlasmaTheme.secondaryText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    model: root.bluetooth.devices || []

                    delegate: PlasmaListDelegate {
                        required property var modelData
                        width: ListView.view.width
                        height: 48
                        current: modelData.connected
                        text: modelData.name
                        icon.name: "preferences-system-bluetooth"
                        display: AbstractButton.TextBesideIcon
                        onClicked: {
                            if (!modelData.paired && !modelData.remembered)
                                PlasmaBackend.pairBluetooth(modelData.id)
                            root.bluetooth = PlasmaBackend.bluetoothState()
                        }

                        Label {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Available"
                            color: parent.current ? PlasmaTheme.highlightedText : PlasmaTheme.secondaryText
                            font.pixelSize: 9
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    text: "Scan for New Devices"
                    onClicked: root.bluetooth = PlasmaBackend.bluetoothScan()
                }
            }
        }
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
        onClicked: batteryPopup.open()
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: PlasmaBackend.batteryPercent + "% — " +
                      (PlasmaBackend.charging ? "Charging" : PlasmaBackend.onAc ? "AC power" : "Battery")

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: root.settingsRequested(5)
        }

        Popup {
            id: batteryPopup
            width: 330
            height: 184
            x: batteryButton.width - width
            y: -height - 8
            padding: 0

            background: PlasmaSurface {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Power and Battery"
                        color: PlasmaTheme.text
                        font.family: PlasmaTheme.fontFamily
                        font.pixelSize: 15
                        Layout.fillWidth: true
                    }
                    PlasmaIconButton {
                        icon.name: "configure"
                        onClicked: {
                            batteryPopup.close()
                            root.settingsRequested(5)
                        }
                        ToolTip.visible: hovered
                        ToolTip.text: "Configure Power Management"
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: PlasmaTheme.separator }

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: PlasmaBackend.batteryPercent + "%"
                        color: PlasmaTheme.text
                        font.bold: true
                        font.pixelSize: 18
                    }
                    Label {
                        Layout.fillWidth: true
                        text: PlasmaBackend.charging ? "Charging" : PlasmaBackend.onAc ? "Plugged in" : "On battery"
                        color: PlasmaTheme.secondaryText
                    }
                }

                ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: PlasmaBackend.batteryPercent
                }

                Button {
                    Layout.alignment: Qt.AlignRight
                    text: "Sleep"
                    icon.name: "system-suspend"
                    onClicked: PlasmaBackend.suspend()
                }
            }
        }
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
                        font.pixelSize: 15
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

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: PlasmaTheme.separator }

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
