import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: desktop
    objectName: "plasmaDesktop"
    visible: true
    x: displayData && displayData.x !== undefined ? displayData.x : Screen.virtualX
    y: displayData && displayData.y !== undefined ? displayData.y : Screen.virtualY
    width: displayData && displayData.width ? displayData.width : Screen.width
    height: displayData && displayData.height ? displayData.height : Screen.height
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint
    color: PlasmaTheme.window

    property var displayData: ({})
    property bool showIcons: true
    signal runnerRequested()
    signal settingsRequested()

    Rectangle {
        anchors.fill: parent
        color: PlasmaTheme.window

        gradient: Gradient {
            GradientStop { position: 0.0; color: PlasmaTheme.dark ? "#263743" : "#dfeef7" }
            GradientStop { position: 1.0; color: PlasmaTheme.dark ? "#18242c" : "#b9d7e8" }
        }
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
        visible: desktop.showIcons
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.topMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: PlasmaTheme.panelHeight + PlasmaTheme.panelMargin * 2 + 8
        cellWidth: 86
        cellHeight: 96
        model: desktop.showIcons ? PlasmaBackend.desktopItems : []
        flow: GridView.FlowTopToBottom
        layoutDirection: Qt.LeftToRight
        clip: true

        delegate: Item {
            id: iconDelegate
            required property var modelData
            width: 82
            height: 92

            Rectangle {
                anchors.fill: parent
                radius: PlasmaTheme.itemRadius
                color: mouse.containsMouse ? "#663daee9" : "transparent"
                border.color: mouse.containsMouse ? "#aa3daee9" : "transparent"
                border.width: 1
            }

            Image {
                id: icon
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 7
                width: 48
                height: 48
                source: modelData.icon
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: icon.bottom
                anchors.topMargin: 3
                horizontalAlignment: Text.AlignHCenter
                text: modelData.name
                color: "white"
                font.family: PlasmaTheme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: "#cc000000"
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
        MenuItem {
            text: "Create New Folder…"
            icon.name: "folder-new"
            enabled: desktop.showIcons
            onTriggered: PlasmaBackend.createDesktopFolder()
        }
        MenuItem {
            text: "Open Desktop in Dolphin"
            icon.name: "system-file-manager"
            enabled: desktop.showIcons
            onTriggered: PlasmaBackend.openDesktopFolder()
        }
        MenuSeparator {}
        MenuItem { text: "Refresh Desktop"; icon.name: "view-refresh"; onTriggered: PlasmaBackend.reloadDesktop() }
        MenuItem {
            text: "Configure Desktop and Wallpaper…"
            icon.name: "configure"
            onTriggered: desktop.settingsRequested()
        }
        MenuSeparator {}
        MenuItem { text: "Show KRunner"; icon.name: "system-search"; onTriggered: desktop.runnerRequested() }
    }
}
