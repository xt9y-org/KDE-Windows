import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 12
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

    Label {
        text: "Bluetooth"
        color: PlasmaTheme.text
        font.family: PlasmaTheme.fontFamily
        font.pixelSize: 20
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label {
                text: root.state.available ? (root.state.radioName || "Bluetooth radio") : "No Bluetooth radio"
                color: PlasmaTheme.text
                font.pixelSize: 14
                font.bold: true
            }
            Label {
                text: root.state.available ? "Connected and remembered devices" : "Bluetooth is unavailable on this system."
                color: PlasmaTheme.secondaryText
                font.pixelSize: 10
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

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: PlasmaTheme.separator
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.state.devices || []
        spacing: 4

        delegate: PlasmaSurface {
            required property var modelData
            width: ListView.view.width
            height: 60
            viewStyle: true
            selected: modelData.connected

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 15
                    color: PlasmaTheme.highlightSoft
                    Label {
                        anchors.centerIn: parent
                        text: "B"
                        color: PlasmaTheme.highlight
                        font.bold: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Label { text: modelData.name; color: PlasmaTheme.text; font.bold: true; font.pixelSize: 12 }
                    Label { text: modelData.id; color: PlasmaTheme.secondaryText; font.pixelSize: 9 }
                }

                Label {
                    text: modelData.connected ? "Connected" : modelData.paired ? "Paired" : modelData.remembered ? "Remembered" : "Discovered"
                    color: modelData.connected ? PlasmaTheme.highlight : PlasmaTheme.secondaryText
                    font.pixelSize: 10
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

    Label {
        text: "Pairing uses the Windows Bluetooth authentication UI."
        color: PlasmaTheme.disabledText
        font.pixelSize: 10
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
}
