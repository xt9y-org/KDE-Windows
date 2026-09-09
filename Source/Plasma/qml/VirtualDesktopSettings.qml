import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 18

    Label { text: "Virtual Desktops"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
    Label {
        text: "Windows remains the compositor. KDE-Windows owns the shell UI and sends the native desktop commands for switching, creating and closing desktops."
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
