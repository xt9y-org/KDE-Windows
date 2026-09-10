import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 12

    Label {
        text: "Virtual Desktops"
        color: PlasmaTheme.text
        font.family: PlasmaTheme.fontFamily
        font.pixelSize: 20
        font.bold: true
    }
    Label {
        text: "Manage the native Windows virtual desktops from the Plasma shell."
        color: PlasmaTheme.secondaryText
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        font.pixelSize: 11
    }

    PlasmaSurface {
        Layout.fillWidth: true
        Layout.preferredHeight: 94
        viewStyle: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Button { text: "Previous"; icon.name: "go-previous"; onClicked: PlasmaBackend.virtualDesktopLeft() }
            Button { text: "New Desktop"; icon.name: "list-add"; onClicked: PlasmaBackend.virtualDesktopCreate() }
            Button { text: "Close Desktop"; icon.name: "window-close"; onClicked: PlasmaBackend.virtualDesktopClose() }
            Button { text: "Next"; icon.name: "go-next"; onClicked: PlasmaBackend.virtualDesktopRight() }
            Item { Layout.fillWidth: true }
        }
    }

    Item { Layout.fillHeight: true }
}
