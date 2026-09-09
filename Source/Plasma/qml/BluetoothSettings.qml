import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 14
    property var state: ({ "available": false, "discoverable": false, "radioName": "", "devices": [] })

    function refresh() { state = PlasmaBackend.bluetoothState() }
    Component.onCompleted: refresh()

    Timer {
        interval: 3000
        running: root.visible
        repeat: true
        onTriggered: root.refresh()
    }

    Label { text: "Bluetooth"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }

    RowLayout {
        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            Label {
                text: root.state.available ? (root.state.radioName || "Bluetooth radio") : "No Bluetooth radio"
                color: "#eff0f1"
                font.pixelSize: 16
                font.bold: true
            }
            Label {
                text: root.state.available ? "Paired, remembered and connected devices" : "Bluetooth is unavailable on this system."
                color: "#aeb5ba"
            }
        }
        Switch {
            visible: root.state.available
            text: "Discoverable"
            checked: root.state.discoverable
            onToggled: {
                PlasmaBackend.setBluetoothDiscoverable(checked)
                root.refresh()
            }
        }
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ListView {
            model: root.state.devices || []
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

    Label {
        text: "Device inventory and discoverability use the documented Windows Bluetooth APIs."
        color: "#808990"
        font.pixelSize: 11
    }
}
