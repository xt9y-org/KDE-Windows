import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: settings
    visible: false
    width: 940
    height: 680
    minimumWidth: 760
    minimumHeight: 520
    property var displayData: PlasmaBackend.primaryDisplay
    x: (displayData && displayData.x !== undefined ? displayData.x : Screen.virtualX) +
       Math.round(((displayData && displayData.width ? displayData.width : Screen.width) - width) / 2)
    y: (displayData && displayData.y !== undefined ? displayData.y : Screen.virtualY) +
       Math.round(((displayData && displayData.height ? displayData.height : Screen.height) - height) / 2)
    flags: Qt.Window | Qt.FramelessWindowHint
    title: "System Settings"
    color: PlasmaTheme.window

    signal dismissed()
    property int page: 0
    property string navigationSearch: ""

    readonly property var pages: [
        { "name": "Quick Settings", "icon": "configure", "page": 0, "group": "" },
        { "name": "Display & Monitor", "icon": "preferences-desktop-display", "page": 1, "group": "Input & Output" },
        { "name": "Sound", "icon": "audio-volume-high", "page": 4, "group": "" },
        { "name": "Bluetooth", "icon": "preferences-system-bluetooth", "page": 3, "group": "Connected Devices" },
        { "name": "Wi-Fi & Internet", "icon": "network-wireless", "page": 2, "group": "Networking" },
        { "name": "Appearance", "icon": "preferences-desktop-theme", "page": 0, "group": "Appearance & Style" },
        { "name": "Virtual Desktops", "icon": "preferences-desktop-virtual", "page": 6, "group": "Workspace" },
        { "name": "Power Management", "icon": "battery", "page": 5, "group": "System" }
    ]

    function matchesNavigation(name) {
        return navigationSearch.length === 0 || name.toLowerCase().indexOf(navigationSearch.toLowerCase()) >= 0
    }

    onVisibleChanged: if (visible) requestActivate()
    Keys.onEscapePressed: dismissed()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: titleBar
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: PlasmaTheme.window
            border.color: PlasmaTheme.frame
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 4

                Rectangle {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    radius: 3
                    color: PlasmaTheme.highlight
                    Label {
                        anchors.centerIn: parent
                        text: "K"
                        color: PlasmaTheme.highlightedText
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "System Settings"
                    color: PlasmaTheme.text
                    font.family: PlasmaTheme.fontFamily
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }

                PlasmaIconButton {
                    implicitWidth: 34
                    implicitHeight: 28
                    icon.name: "window-minimize"
                    onClicked: settings.showMinimized()
                }
                PlasmaIconButton {
                    implicitWidth: 34
                    implicitHeight: 28
                    icon.name: settings.visibility === Window.Maximized ? "window-restore" : "window-maximize"
                    onClicked: settings.visibility === Window.Maximized ? settings.showNormal() : settings.showMaximized()
                }
                PlasmaIconButton {
                    implicitWidth: 34
                    implicitHeight: 28
                    icon.name: "window-close"
                    onClicked: settings.dismissed()
                }
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: 106
                acceptedButtons: Qt.LeftButton
                onPressed: settings.startSystemMove()
                onDoubleClicked: settings.visibility === Window.Maximized ? settings.showNormal() : settings.showMaximized()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 235
                Layout.fillHeight: true
                color: PlasmaTheme.window
                border.color: PlasmaTheme.frame
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 7
                    spacing: 5

                    TextField {
                        id: navSearch
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        placeholderText: "Search…"
                        text: settings.navigationSearch
                        onTextChanged: settings.navigationSearch = text
                        selectByMouse: true
                        color: PlasmaTheme.text
                        placeholderTextColor: PlasmaTheme.secondaryText
                        font.family: PlasmaTheme.fontFamily
                        font.pixelSize: 11
                        background: Rectangle {
                            radius: PlasmaTheme.itemRadius
                            color: PlasmaTheme.view
                            border.color: navSearch.activeFocus ? PlasmaTheme.highlight : PlasmaTheme.frame
                            border.width: navSearch.activeFocus ? 2 : 1
                        }
                    }

                    ListView {
                        id: navigation
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: settings.pages
                        spacing: 0

                        delegate: Item {
                            required property var modelData
                            required property int index
                            width: navigation.width
                            height: visible ? (modelData.group.length > 0 ? 55 : 36) : 0
                            visible: settings.matchesNavigation(modelData.name)

                            Column {
                                anchors.fill: parent
                                spacing: 1

                                Label {
                                    visible: modelData.group.length > 0
                                    height: visible ? 19 : 0
                                    width: parent.width
                                    text: modelData.group
                                    color: PlasmaTheme.secondaryText
                                    font.family: PlasmaTheme.fontFamily
                                    font.pixelSize: 9
                                    verticalAlignment: Text.AlignBottom
                                    leftPadding: 6
                                }

                                PlasmaListDelegate {
                                    width: parent.width
                                    height: 35
                                    current: settings.page === modelData.page &&
                                             ((modelData.page !== 0) || index === 0 || settings.navigationSearch.length > 0)
                                    text: modelData.name
                                    icon.name: modelData.icon
                                    icon.width: 17
                                    icon.height: 17
                                    display: AbstractButton.TextBesideIcon
                                    onClicked: settings.page = modelData.page
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: PlasmaTheme.view
                border.color: PlasmaTheme.frame
                border.width: 1

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    currentIndex: settings.page

                    AppearanceSettings {}
                    DisplaySettings {}
                    NetworkSettings {}
                    BluetoothSettings {}
                    SoundSettings {}
                    PowerSettings {}
                    VirtualDesktopSettings {}
                }
            }
        }
    }
}
