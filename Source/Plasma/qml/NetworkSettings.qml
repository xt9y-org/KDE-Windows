import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 14
    property var state: ({ "enabled": false, "connected": false, "name": "", "networks": [] })

    function refresh() {
        state = PlasmaBackend.wifiState()
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 3000
        running: root.visible
        repeat: true
        onTriggered: root.refresh()
    }

    Label { text: "Network"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }

    RowLayout {
        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            Label {
                text: root.state.connected ? root.state.name : "Wi-Fi"
                color: "#eff0f1"
                font.pixelSize: 17
                font.bold: true
            }
            Label { text: root.state.connected ? "Connected" : "Not connected"; color: "#aeb5ba" }
        }
        Switch {
            text: "Wi-Fi"
            checked: root.state.enabled
            onToggled: {
                PlasmaBackend.setWifiEnabled(checked)
                root.refresh()
            }
        }
        Button {
            visible: root.state.connected
            text: "Disconnect"
            onClicked: {
                PlasmaBackend.disconnectWifi()
                root.refresh()
            }
        }
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ListView {
            model: root.state.networks || []
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
                            text: modelData.connected ? "Connected" :
                                  modelData.known ? "Saved network" :
                                  modelData.secure ? "Secured" : "Open"
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
                            root.refresh()
                        }
                    }
                }
            }
        }
    }

    Label {
        text: "Saved Windows WLAN profiles connect directly. Unsaved secured networks are not persisted by KDE-Windows."
        color: "#808990"
        font.pixelSize: 11
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
}
