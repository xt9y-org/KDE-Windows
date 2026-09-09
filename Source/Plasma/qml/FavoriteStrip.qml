import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Row {
    id: root
    spacing: 2

    Repeater {
        model: Favorites.applications

        delegate: ToolButton {
            id: favoriteButton
            required property var modelData
            width: 38
            height: 38
            hoverEnabled: true
            onClicked: Favorites.launch(modelData.id)

            contentItem: Image {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: "image://shell/path/" + encodeURIComponent(modelData.iconPath.length > 0 ? modelData.iconPath : modelData.executable)
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            background: Rectangle {
                radius: 7
                color: favoriteButton.down ? "#4a555e" : favoriteButton.hovered ? "#343b41" : "transparent"
            }

            ToolTip.visible: hovered
            ToolTip.text: modelData.name
            ToolTip.delay: 400

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
