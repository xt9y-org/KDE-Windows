import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 12

    Label {
        text: "Power Management"
        color: PlasmaTheme.text
        font.family: PlasmaTheme.fontFamily
        font.pixelSize: 20
        font.bold: true
    }

    PlasmaSurface {
        Layout.fillWidth: true
        Layout.preferredHeight: PlasmaBackend.batteryAvailable ? 126 : 86
        viewStyle: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: PlasmaTheme.highlightSoft
                    Label {
                        anchors.centerIn: parent
                        text: "⚡"
                        color: PlasmaTheme.highlight
                        font.pixelSize: 15
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Label {
                        text: PlasmaBackend.batteryAvailable ? PlasmaBackend.batteryPercent + "%" : "No battery detected"
                        color: PlasmaTheme.text
                        font.bold: true
                        font.pixelSize: 14
                    }
                    Label {
                        visible: PlasmaBackend.batteryAvailable
                        text: PlasmaBackend.charging ? "Charging" : PlasmaBackend.onAc ? "AC power" : "On battery"
                        color: PlasmaTheme.secondaryText
                        font.pixelSize: 10
                    }
                }
                Button { text: "Sleep"; onClicked: PlasmaBackend.suspend() }
            }

            ProgressBar {
                visible: PlasmaBackend.batteryAvailable
                Layout.fillWidth: true
                from: 0
                to: 100
                value: PlasmaBackend.batteryPercent
            }
        }
    }

    Item { Layout.fillHeight: true }
}
