import QtQuick
import QtQuick.Controls

Row {
    id: root
    spacing: 1

    Repeater {
        model: Favorites.applications

        delegate: PlasmaIconButton {
            id: favoriteButton
            required property var modelData
            width: 40
            height: 38
            onClicked: Favorites.launch(modelData.id)

            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    source: "image://shell/path/" + encodeURIComponent(modelData.iconPath.length > 0 ? modelData.iconPath : modelData.executable)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            ToolTip.visible: hovered
            ToolTip.text: modelData.name
            ToolTip.delay: 500

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: favoriteMenu.popup()
            }

            Menu {
                id: favoriteMenu
                MenuItem {
                    text: "Unpin from Task Manager"
                    onTriggered: Favorites.setFavorite(modelData.id, false)
                }
            }
        }
    }
}
