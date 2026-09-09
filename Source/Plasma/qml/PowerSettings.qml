import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 18

    Label { text: "Power"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
    Label {
        text: PlasmaBackend.batteryAvailable
              ? (PlasmaBackend.batteryPercent + "%" +
                 (PlasmaBackend.charging ? " • Charging" : PlasmaBackend.onAc ? " • AC power" : ""))
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
