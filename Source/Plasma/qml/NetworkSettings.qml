import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 12
    property var state: ({ "enabled": false, "connected": false, "name": "", "networks": [] })
    property var pendingNetwork: null

    function refresh() { state = PlasmaBackend.wifiState() }

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
            spacing: 8
            Label { text: "Password"; color: PlasmaTheme.text }
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

    Label {
        text: "Wi-Fi & Internet"
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
                text: root.state.connected ? root.state.name : "Wi-Fi"
                color: PlasmaTheme.text
                font.family: PlasmaTheme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }
            Label {
                text: root.state.connected ? "Connected" : "Not connected"
                color: root.state.connected ? PlasmaTheme.positive : PlasmaTheme.secondaryText
                font.pixelSize: 10
            }
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

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: PlasmaTheme.separator
    }

    Label { text: "Available Networks"; color: PlasmaTheme.secondaryText; font.pixelSize: 11 }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.state.networks || []
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
                Image {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    source: "image://shell/path/network-wireless"
                    visible: false
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Label { text: modelData.name; color: PlasmaTheme.text; font.bold: true; font.pixelSize: 12 }
                    Label {
                        text: modelData.connected ? "Connected" :
                              modelData.known ? "Saved network" :
                              modelData.secure ? "Secured" : "Open"
                        color: modelData.connected ? PlasmaTheme.highlight : PlasmaTheme.secondaryText
                        font.pixelSize: 10
                    }
                }
                Label { text: modelData.signal + "%"; color: PlasmaTheme.secondaryText; font.pixelSize: 10 }
                Button {
                    visible: !modelData.connected
                    text: modelData.known ? "Connect" : (modelData.secure ? "Password…" : "Connect")
                    onClicked: root.connectNetwork(modelData)
                }
            }
        }
    }

    Label {
        text: "Enterprise authentication remains managed by Windows WLAN policy."
        color: PlasmaTheme.disabledText
        font.pixelSize: 10
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
}
