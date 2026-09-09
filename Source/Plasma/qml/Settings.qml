import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: settings
    visible: false
    width: 920
    height: 650
    property var displayData: PlasmaBackend.primaryDisplay
    x: (displayData && displayData.x !== undefined ? displayData.x : Screen.virtualX) +
       Math.round(((displayData && displayData.width ? displayData.width : Screen.width) - width) / 2)
    y: (displayData && displayData.y !== undefined ? displayData.y : Screen.virtualY) +
       Math.round(((displayData && displayData.height ? displayData.height : Screen.height) - height) / 2)
    flags: Qt.Window | Qt.WindowStaysOnTopHint
    title: "System Settings"
    color: "#202428"

    signal dismissed()
    property int page: 0
    property var wifiState: ({ "enabled": false, "connected": false, "name": "", "networks": [] })
    property var bluetooth: ({ "available": false, "discoverable": false, "radioName": "", "devices": [] })

    function refreshHardware() {
        wifiState = PlasmaBackend.wifiState()
        bluetooth = PlasmaBackend.bluetoothState()
    }

    onVisibleChanged: {
        if (visible) {
            refreshHardware()
            requestActivate()
        }
    }

    Timer {
        interval: 3000
        running: settings.visible
        repeat: true
        onTriggered: settings.refreshHardware()
    }

    FileDialog {
        id: wallpaperDialog
        title: "Choose Wallpaper"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.png *.jpg *.jpeg *.bmp *.webp)", "All files (*)"]
        onAccepted: {
            wallpaperField.text = selectedFile.toString()
            PlasmaBackend.setWallpaper(wallpaperField.text)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 210
            Layout.fillHeight: true
            color: "#272c31"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                Label {
                    text: "System Settings"
                    color: "#eff0f1"
                    font.pixelSize: 20
                    font.bold: true
                    Layout.leftMargin: 8
                    Layout.topMargin: 8
                    Layout.bottomMargin: 12
                }

                Repeater {
                    model: ["Appearance", "Displays", "Network", "Bluetooth", "Sound", "Power", "Virtual Desktops"]
                    delegate: ItemDelegate {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        text: modelData
                        highlighted: settings.page === index
                        onClicked: settings.page = index
                    }
                }

                Item { Layout.fillHeight: true }

                Button {
                    Layout.fillWidth: true
                    text: "Close"
                    onClicked: settings.dismissed()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#202428"

            StackLayout {
                anchors.fill: parent
                anchors.margins: 28
                currentIndex: settings.page

                ColumnLayout {
                    spacing: 16
                    Label { text: "Appearance"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
                    Label { text: "Wallpaper"; color: "#d8dcdf"; font.pixelSize: 16 }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 250
                        radius: 10
                        color: "#16191c"
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: PlasmaBackend.wallpaperUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        TextField {
                            id: wallpaperField
                            Layout.fillWidth: true
                            text: PlasmaBackend.wallpaperUrl
                            placeholderText: "Wallpaper path"
                        }
                        Button { text: "Browse…"; onClicked: wallpaperDialog.open() }
                        Button { text: "Apply"; onClicked: PlasmaBackend.setWallpaper(wallpaperField.text) }
                    }
                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    spacing: 14
                    Label { text: "Displays"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
                    Label {
                        text: "Connected displays are managed directly through Windows monitor APIs."
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
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: brightnessInfo.available ? 142 : 105
                                    radius: 10
                                    color: "#2b3035"
                                    border.color: modelData.primary ? "#3daee9" : "#434b52"
                                    property var brightnessInfo: PlasmaBackend.displayBrightness(modelData.id)

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
                                                text: modelData.width + "×" + modelData.height + "  @ " + modelData.x + "," + modelData.y
                                                color: "#aeb5ba"
                                            }
                                        }
                                        Label {
                                            text: "Work area: " + modelData.workWidth + "×" + modelData.workHeight
                                            color: "#929ba2"
                                        }
                                        RowLayout {
                                            visible: parent.parent.brightnessInfo.available
                                            Layout.fillWidth: true
                                            Label { text: "Brightness"; color: "#d8dcdf" }
                                            Slider {
                                                id: brightnessSlider
                                                Layout.fillWidth: true
                                                from: 0
                                                to: 100
                                                value: parent.parent.parent.brightnessInfo.percent
                                                onMoved: PlasmaBackend.setDisplayBrightness(modelData.id, Math.round(value))
                                            }
                                            Label { text: Math.round(brightnessSlider.value) + "%"; color: "#d8dcdf"; Layout.preferredWidth: 48 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    spacing: 14
                    Label { text: "Network"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label {
                                text: settings.wifiState.connected ? settings.wifiState.name : "Wi-Fi"
                                color: "#eff0f1"
                                font.pixelSize: 17
                                font.bold: true
                            }
                            Label {
                                text: settings.wifiState.connected ? "Connected" : "Not connected"
                                color: "#aeb5ba"
                            }
                        }
                        Switch {
                            text: "Wi-Fi"
                            checked: settings.wifiState.enabled
                            onToggled: {
                                PlasmaBackend.setWifiEnabled(checked)
                                settings.refreshHardware()
                            }
                        }
                        Button {
                            visible: settings.wifiState.connected
                            text: "Disconnect"
                            onClicked: {
                                PlasmaBackend.disconnectWifi()
                                settings.refreshHardware()
                            }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ListView {
                            model: settings.wifiState.networks || []
                            spacing: 6
                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width
                                height: 66
                                radius: 8
                                color: "#2b3035"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Label { text: modelData.name; color: "#eff0f1"; font.bold: true }
                                        Label {
                                            text: modelData.connected ? "Connected" : (modelData.known ? "Saved network" : modelData.secure ? "Secured" : "Open")
                                            color: modelData.connected ? "#3daee9" : "#929ba2"
                                            font.pixelSize: 11
                                        }
                                    }
                                    Label { text: modelData.signal + "%"; color: "#c4c9cd" }
                                    Button {
                                        visible: !modelData.connected && modelData.known
                                        text: "Connect"
                                        onClicked: {
                                            PlasmaBackend.connectWifi(modelData.id)
                                            settings.refreshHardware()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Label {
                        text: "New secured networks require a saved Windows WLAN profile before direct connection."
                        color: "#808990"
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                }

                ColumnLayout {
                    spacing: 14
                    Label { text: "Bluetooth"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label {
                                text: settings.bluetooth.available ? (settings.bluetooth.radioName || "Bluetooth radio") : "No Bluetooth radio"
                                color: "#eff0f1"
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Label {
                                text: settings.bluetooth.available ? "Paired and remembered devices" : "Bluetooth is unavailable on this system."
                                color: "#aeb5ba"
                            }
                        }
                        Switch {
                            visible: settings.bluetooth.available
                            text: "Discoverable"
                            checked: settings.bluetooth.discoverable
                            onToggled: {
                                PlasmaBackend.setBluetoothDiscoverable(checked)
                                settings.refreshHardware()
                            }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ListView {
                            model: settings.bluetooth.devices || []
                            spacing: 6
                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width
                                height: 62
                                radius: 8
                                color: "#2b3035"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Label { text: modelData.name; color: "#eff0f1"; font.bold: true }
                                        Label { text: modelData.id; color: "#8f989f"; font.pixelSize: 11 }
                                    }
                                    Label {
                                        text: modelData.connected ? "Connected" : modelData.paired ? "Paired" : modelData.remembered ? "Remembered" : "Known"
                                        color: modelData.connected ? "#3daee9" : "#b8bec3"
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    spacing: 18
                    Label { text: "Sound"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
                    Label {
                        text: PlasmaBackend.audioAvailable ? "Default output device" : "No default audio output"
                        color: "#d8dcdf"
                        font.pixelSize: 16
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            text: PlasmaBackend.muted ? "Unmute" : "Mute"
                            enabled: PlasmaBackend.audioAvailable
                            onClicked: PlasmaBackend.toggleMute()
                        }
                        Slider {
                            id: volumeSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: PlasmaBackend.volume
                            enabled: PlasmaBackend.audioAvailable
                            onMoved: PlasmaBackend.setVolume(Math.round(value))
                        }
                        Label { text: PlasmaBackend.volume + "%"; color: "#eff0f1"; Layout.preferredWidth: 48 }
                    }
                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    spacing: 18
                    Label { text: "Power"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
                    Label {
                        text: PlasmaBackend.batteryAvailable
                              ? (PlasmaBackend.batteryPercent + "%" + (PlasmaBackend.charging ? " • Charging" : PlasmaBackend.onAc ? " • AC power" : ""))
                              : "No battery detected"
                        color: "#d8dcdf"
                        font.pixelSize: 18
                    }
                    ProgressBar {
                        visible: PlasmaBackend.batteryAvailable
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: PlasmaBackend.batteryPercent
                    }
                    Button { text: "Sleep"; onClicked: PlasmaBackend.suspend() }
                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    spacing: 18
                    Label { text: "Virtual Desktops"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
                    Label {
                        text: "Windows owns the desktop compositor; Plasma sends the native desktop commands while keeping its own overview and task UI."
                        color: "#aeb5ba"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                    RowLayout {
                        Button { text: "← Previous"; onClicked: PlasmaBackend.virtualDesktopLeft() }
                        Button { text: "New Desktop"; onClicked: PlasmaBackend.virtualDesktopCreate() }
                        Button { text: "Close Desktop"; onClicked: PlasmaBackend.virtualDesktopClose() }
                        Button { text: "Next →"; onClicked: PlasmaBackend.virtualDesktopRight() }
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
