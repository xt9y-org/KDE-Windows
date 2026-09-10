import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: launcher
    objectName: "plasmaLauncher"
    width: 660
    height: 540
    x: panelX + PlasmaTheme.panelMargin
    y: panelY - height - 6
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    property int panelX: 0
    property int panelY: 0
    property int currentSection: 0
    signal dismissed()
    signal settingsRequested()

    readonly property var sections: [
        { "name": "Favorites", "icon": "bookmarks" },
        { "name": "Applications", "icon": "view-app-grid-symbolic" },
        { "name": "Computer", "icon": "computer" }
    ]

    function applicationModel() {
        if (search.text.length > 0)
            return PlasmaBackend.searchApplications(search.text)
        if (currentSection === 0)
            return Favorites.applications
        return PlasmaBackend.searchApplications("")
    }

    function launchEntry(entry) {
        if (!entry)
            return
        if (currentSection === 0 && search.text.length === 0)
            Favorites.launch(entry.id)
        else
            PlasmaBackend.launchApplication(entry.id)
        dismissed()
    }

    onVisibleChanged: {
        if (visible) {
            Favorites.reload()
            search.text = ""
            currentSection = 0
            search.forceActiveFocus()
        }
    }

    Keys.onEscapePressed: dismissed()

    PlasmaSurface {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: PlasmaTheme.spacing

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 38

                TextField {
                    id: search
                    anchors.fill: parent
                    leftPadding: 34
                    rightPadding: 10
                    placeholderText: "Search…"
                    selectByMouse: true
                    color: PlasmaTheme.text
                    placeholderTextColor: PlasmaTheme.secondaryText
                    font.family: PlasmaTheme.fontFamily
                    font.pixelSize: 13
                    Keys.onEscapePressed: launcher.dismissed()
                    Keys.onReturnPressed: {
                        const entries = launcher.applicationModel()
                        if (entries.length > 0)
                            launcher.launchEntry(entries[0])
                        else if (PlasmaBackend.runCommand(text))
                            launcher.dismissed()
                    }

                    background: Rectangle {
                        radius: PlasmaTheme.itemRadius
                        color: PlasmaTheme.view
                        border.color: search.activeFocus ? PlasmaTheme.highlight : PlasmaTheme.frame
                        border.width: search.activeFocus ? 2 : 1
                    }
                }

                Image {
                    anchors.left: parent.left
                    anchors.leftMargin: 9
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    source: "image://shell/path/search"
                    visible: false
                }

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 11
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⌕"
                    color: PlasmaTheme.secondaryText
                    font.pixelSize: 18
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: PlasmaTheme.separator
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                ColumnLayout {
                    Layout.preferredWidth: 166
                    Layout.fillHeight: true
                    spacing: 2

                    Repeater {
                        model: launcher.sections

                        delegate: PlasmaListDelegate {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            current: launcher.currentSection === index && search.text.length === 0
                            text: modelData.name
                            icon.name: modelData.icon
                            icon.width: 20
                            icon.height: 20
                            display: AbstractButton.TextBesideIcon
                            onClicked: {
                                search.text = ""
                                launcher.currentSection = index
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    PlasmaListDelegate {
                        Layout.fillWidth: true
                        text: "System Settings"
                        icon.name: "configure"
                        display: AbstractButton.TextBesideIcon
                        onClicked: {
                            launcher.dismissed()
                            launcher.settingsRequested()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: PlasmaTheme.separator
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    StackLayout {
                        anchors.fill: parent
                        currentIndex: launcher.currentSection === 2 && search.text.length === 0 ? 1 : 0

                        Item {
                            ListView {
                                id: appList
                                anchors.fill: parent
                                clip: true
                                spacing: 1
                                model: launcher.applicationModel()

                                delegate: PlasmaListDelegate {
                                    id: appDelegate
                                    required property var modelData
                                    width: appList.width
                                    height: 42
                                    text: modelData.name
                                    icon.source: "image://shell/path/" + encodeURIComponent(modelData.iconPath.length > 0 ? modelData.iconPath : modelData.executable)
                                    icon.width: 24
                                    icon.height: 24
                                    display: AbstractButton.TextBesideIcon
                                    onClicked: launcher.launchEntry(modelData)

                                    TapHandler {
                                        acceptedButtons: Qt.RightButton
                                        onTapped: favoriteMenu.popup()
                                    }

                                    Menu {
                                        id: favoriteMenu
                                        MenuItem {
                                            text: Favorites.isFavorite(modelData.id) ? "Remove from Favorites" : "Add to Favorites"
                                            onTriggered: Favorites.setFavorite(modelData.id, !Favorites.isFavorite(modelData.id))
                                        }
                                    }
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: appList.count === 0
                                text: search.text.length > 0 ? "No matches" : "No applications"
                                color: PlasmaTheme.secondaryText
                            }
                        }

                        ColumnLayout {
                            spacing: 2

                            PlasmaListDelegate {
                                Layout.fillWidth: true
                                text: "Dolphin File Manager"
                                icon.name: "system-file-manager"
                                display: AbstractButton.TextBesideIcon
                                onClicked: {
                                    PlasmaBackend.launchApplication("org.kde.dolphin")
                                    launcher.dismissed()
                                }
                            }
                            PlasmaListDelegate {
                                Layout.fillWidth: true
                                text: "System Settings"
                                icon.name: "configure"
                                display: AbstractButton.TextBesideIcon
                                onClicked: {
                                    launcher.dismissed()
                                    launcher.settingsRequested()
                                }
                            }
                            PlasmaListDelegate {
                                Layout.fillWidth: true
                                text: "Terminal"
                                icon.name: "utilities-terminal"
                                display: AbstractButton.TextBesideIcon
                                onClicked: {
                                    PlasmaBackend.launchApplication("org.kde.konsole")
                                    launcher.dismissed()
                                }
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: PlasmaTheme.separator
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Image {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        source: "image://shell/path/user-identity"
                        visible: false
                    }
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: PlasmaTheme.highlightSoft
                        Label {
                            anchors.centerIn: parent
                            text: "K"
                            color: PlasmaTheme.highlight
                            font.bold: true
                        }
                    }
                    Label {
                        text: "KDE Plasma"
                        color: PlasmaTheme.text
                        font.family: PlasmaTheme.fontFamily
                        font.pixelSize: 12
                    }
                }

                PlasmaIconButton {
                    icon.name: "system-lock-screen"
                    onClicked: { PlasmaBackend.lockSession(); launcher.dismissed() }
                    ToolTip.visible: hovered
                    ToolTip.text: "Lock"
                }
                PlasmaIconButton {
                    icon.name: "system-suspend"
                    onClicked: { PlasmaBackend.suspend(); launcher.dismissed() }
                    ToolTip.visible: hovered
                    ToolTip.text: "Sleep"
                }
                PlasmaIconButton {
                    icon.name: "system-log-out"
                    onClicked: PlasmaBackend.logOut()
                    ToolTip.visible: hovered
                    ToolTip.text: "Log Out"
                }
                PlasmaIconButton {
                    icon.name: "system-reboot"
                    onClicked: PlasmaBackend.restart()
                    ToolTip.visible: hovered
                    ToolTip.text: "Restart"
                }
                PlasmaIconButton {
                    icon.name: "system-shutdown"
                    onClicked: PlasmaBackend.shutDown()
                    ToolTip.visible: hovered
                    ToolTip.text: "Shut Down"
                }
            }
        }
    }
}
