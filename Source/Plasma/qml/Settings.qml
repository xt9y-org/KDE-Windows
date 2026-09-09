import QtQuick
import QtQuick.Controls
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

    onVisibleChanged: if (visible) requestActivate()

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

                AppearanceSettings {}
                DisplaySettings {}
                NetworkSettings {}
                BluetoothSettings {}
                SoundSettings {}
                PowerSettings {}
                VirtualDesktopSettings {}
            }
        }
    }
}
