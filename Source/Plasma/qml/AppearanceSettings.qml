import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

ColumnLayout {
    spacing: 16

    Label { text: "Appearance"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
    Label { text: "Wallpaper"; color: "#d8dcdf"; font.pixelSize: 16 }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 250
        radius: 10
        color: "#16191c"
        clip: true
        Image {
            anchors.fill: parent
            source: PlasmaBackend.wallpaperUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    RowLayout {
        Layout.fillWidth: true
        TextField {
            id: wallpaperField
            Layout.fillWidth: true
            text: PlasmaBackend.wallpaperUrl
            placeholderText: "Wallpaper path"
        }
        Button { text: "Browse…"; onClicked: wallpaperDialog.open() }
        Button { text: "Apply"; onClicked: PlasmaBackend.setWallpaper(wallpaperField.text) }
    }

    FileDialog {
        id: wallpaperDialog
        title: "Choose Wallpaper"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.png *.jpg *.jpeg *.bmp *.webp)", "All files (*)"]
        onAccepted: {
            wallpaperField.text = selectedFile.toString()
            PlasmaBackend.setWallpaper(wallpaperField.text)
        }
    }

    Item { Layout.fillHeight: true }
}
