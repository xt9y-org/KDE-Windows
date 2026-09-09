import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 14
    property var state: ({ "available": false, "discoverable": false, "radioName": "", "devices": [] })
    property bool scanning: false

    function refresh() { state = PlasmaBackend.bluetoothState() }

    function scan() {
        scanning = true
        state = PlasmaBackend.bluetoothScan()
        scanning = false
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 3000
        running: root.visible && !root.scanning
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
                text: root.state.available ? "Paired, remembered, connected and discovered devices" : "Bluetooth is unavailable on this system."
                color: "#aeb5ba"
            }
        }
        Button {
            visible: root.state.available
            text: root.scanning ? "Scanning…" : "Scan"
            enabled: !root.scanning
            onClicked: root.scan()
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
                height: 66
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
                        text: modelData.connected ? "Connected" : modelData.paired ? "Paired" : modelData.remembered ? "Remembered" : "Discovered"
                        color: modelData.connected ? "#3daee9" : "#b8bec3"
                    }
                    Button {
                        visible: !modelData.paired && !modelData.remembered
                        text: "Pair"
                        onClicked: {
                            PlasmaBackend.pairBluetooth(modelData.id)
                            root.refresh()
                        }
                    }
                    Button {
                        visible: modelData.paired || modelData.remembered
                        text: "Remove"
                        onClicked: {
                            PlasmaBackend.removeBluetooth(modelData.id)
                            root.refresh()
                        }
                    }
                }
            }
        }
    }

    Label {
        text: "Pairing uses the Windows Bluetooth authentication wizard; removing a device clears its Windows pairing and cached services."
        color: "#808990"
        font.pixelSize: 11
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
}
