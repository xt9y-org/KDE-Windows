import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 14
    property var state: ({ "enabled": false, "connected": false, "name": "", "networks": [] })
    property var pendingNetwork: null

    function refresh() {
        state = PlasmaBackend.wifiState()
    }

    function connectNetwork(network) {
        if (network.known) {
            PlasmaBackend.connectWifi(network.id)
            refresh()
            return
        }
        if (!network.secure) {
            PlasmaBackend.connectWifiPassword(network.id, "")
            refresh()
            return
        }
        pendingNetwork = network
        passwordField.text = ""
        passwordDialog.open()
        passwordField.forceActiveFocus()
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 3000
        running: root.visible
        repeat: true
        onTriggered: root.refresh()
    }

    Dialog {
        id: passwordDialog
        modal: true
        anchors.centerIn: Overlay.overlay
        title: root.pendingNetwork ? "Connect to " + root.pendingNetwork.name : "Connect to Wi-Fi"
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (root.pendingNetwork)
                PlasmaBackend.connectWifiPassword(root.pendingNetwork.id, passwordField.text)
            root.pendingNetwork = null
            root.refresh()
        }
        onRejected: root.pendingNetwork = null

        contentItem: ColumnLayout {
            spacing: 10
            Label {
                text: "Password"
                color: "#eff0f1"
            }
            TextField {
                id: passwordField
                Layout.preferredWidth: 340
                echoMode: TextInput.Password
                selectByMouse: true
                placeholderText: "8–63 characters or 64 hex digits"
                Keys.onReturnPressed: passwordDialog.accept()
            }
        }
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
                        visible: !modelData.connected
                        text: modelData.known ? "Connect" : (modelData.secure ? "Password…" : "Connect")
                        onClicked: root.connectNetwork(modelData)
                    }
                }
            }
        }
    }

    Label {
        text: "Open, WPA, WPA2 and WPA3-Personal networks can be saved and connected directly. Enterprise authentication remains managed by Windows WLAN policy."
        color: "#808990"
        font.pixelSize: 11
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
}
