import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 12

    Label {
        text: "Quick Settings"
        color: PlasmaTheme.text
        font.family: PlasmaTheme.fontFamily
        font.pixelSize: 20
        font.bold: true
    }

    Label {
        text: "Theme"
        color: PlasmaTheme.secondaryText
        font.family: PlasmaTheme.fontFamily
        font.pixelSize: 11
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Repeater {
            model: [
                { "name": "Breeze", "dark": false },
                { "name": "Breeze Dark", "dark": true }
            ]

            delegate: ItemDelegate {
                id: themeDelegate
                required property var modelData
                Layout.preferredWidth: 150
                Layout.preferredHeight: 92
                onClicked: PlasmaTheme.dark = modelData.dark

                background: PlasmaSurface {
                    viewStyle: true
                    selected: PlasmaTheme.dark === modelData.dark
                }

                contentItem: ColumnLayout {
                    spacing: 5
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 3
                        color: modelData.dark ? "#232629" : "#eff0f1"
                        border.color: modelData.dark ? "#4f565d" : "#b9c0c4"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 12
                            color: modelData.dark ? "#31363b" : "#e4e7e9"
                            Rectangle {
                                width: 24
                                height: 3
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                color: "#3daee9"
                            }
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: PlasmaTheme.text
                        horizontalAlignment: Text.AlignHCenter
                        font.family: PlasmaTheme.fontFamily
                        font.pixelSize: 10
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: PlasmaTheme.separator
    }

    Label {
        text: "Wallpaper"
        color: PlasmaTheme.secondaryText
        font.family: PlasmaTheme.fontFamily
        font.pixelSize: 11
    }

    PlasmaSurface {
        Layout.fillWidth: true
        Layout.preferredHeight: 230
        viewStyle: true
        clip: true

        Image {
            anchors.fill: parent
            anchors.margins: 4
            source: PlasmaBackend.wallpaperUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: source.toString().length > 0
        }

        Label {
            anchors.centerIn: parent
            visible: PlasmaBackend.wallpaperUrl.length === 0
            text: "Desktop Wallpaper"
            color: PlasmaTheme.secondaryText
        }
    }

    RowLayout {
        Layout.fillWidth: true
        TextField {
            id: wallpaperField
            Layout.fillWidth: true
            text: PlasmaBackend.wallpaperUrl
            placeholderText: "Wallpaper path"
            selectByMouse: true
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
