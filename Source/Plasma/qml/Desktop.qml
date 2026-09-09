import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: desktop
    objectName: "plasmaDesktop"
    visible: true
    x: Screen.virtualX
    y: Screen.virtualY
    width: Screen.width
    height: Screen.height
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint
    color: "#1b1e20"

    Rectangle {
        anchors.fill: parent
        color: "#1b1e20"
    }

    Image {
        anchors.fill: parent
        source: PlasmaBackend.wallpaperUrl
        visible: source.toString().length > 0
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: false
    }

    GridView {
        id: desktopGrid
        anchors.fill: parent
        anchors.margins: 12
        anchors.bottomMargin: 62
        cellWidth: 96
        cellHeight: 108
        model: PlasmaBackend.desktopItems
        flow: GridView.FlowTopToBottom
        layoutDirection: Qt.LeftToRight
        clip: true

        delegate: Item {
            required property var modelData
            width: 92
            height: 104

            Rectangle {
                anchors.fill: parent
                radius: 7
                color: mouse.containsMouse ? "#553b454d" : "transparent"
            }

            Image {
                id: icon
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                width: 50
                height: 50
                source: modelData.icon
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: icon.bottom
                anchors.topMargin: 5
                horizontalAlignment: Text.AlignHCenter
                text: modelData.name
                color: "white"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: "#aa000000"
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onDoubleClicked: PlasmaBackend.launchDesktopItem(modelData.id)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        propagateComposedEvents: true
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton)
                desktopMenu.popup()
        }
    }

    Menu {
        id: desktopMenu
        MenuItem { text: "Refresh Desktop"; onTriggered: PlasmaBackend.reloadDesktop() }
        MenuSeparator {}
        MenuItem { text: "Open Runner"; onTriggered: PlasmaBackend.runnerRequested() }
    }
}
