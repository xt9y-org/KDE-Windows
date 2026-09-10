import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: terminal
    visible: true
    width: 980
    height: 640
    minimumWidth: 560
    minimumHeight: 360
    title: "Konsole"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "#eff0f1"

    property color breezeWindow: "#eff0f1"
    property color breezeText: "#232629"
    property color breezeSecondary: "#5f6265"
    property color breezeHighlight: "#3daee9"
    property color breezeFrame: "#b9c0c4"
    property color terminalBackground: "#1b1e20"
    property color terminalForeground: "#eff0f1"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: titleBar
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: terminal.breezeWindow
            border.color: terminal.breezeFrame
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 2

                Rectangle {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    radius: 3
                    color: terminal.breezeHighlight
                    Label {
                        anchors.centerIn: parent
                        text: ">_"
                        color: "white"
                        font.pixelSize: 7
                        font.bold: true
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Konsole"
                    color: terminal.breezeText
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Noto Sans"
                    font.pixelSize: 11
                }

                ToolButton {
                    Layout.preferredWidth: 34
                    Layout.fillHeight: true
                    icon.name: "window-minimize"
                    onClicked: terminal.showMinimized()
                }
                ToolButton {
                    Layout.preferredWidth: 34
                    Layout.fillHeight: true
                    icon.name: terminal.visibility === Window.Maximized ? "window-restore" : "window-maximize"
                    onClicked: terminal.visibility === Window.Maximized ? terminal.showNormal() : terminal.showMaximized()
                }
                ToolButton {
                    Layout.preferredWidth: 34
                    Layout.fillHeight: true
                    icon.name: "window-close"
                    onClicked: terminal.close()
                }
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: 104
                acceptedButtons: Qt.LeftButton
                onPressed: terminal.startSystemMove()
                onDoubleClicked: terminal.visibility === Window.Maximized ? terminal.showNormal() : terminal.showMaximized()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: terminal.breezeWindow
            border.color: terminal.breezeFrame
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                spacing: 0

                ToolButton { text: "File"; flat: true }
                ToolButton { text: "Edit"; flat: true }
                ToolButton { text: "View"; flat: true }
                ToolButton { text: "Settings"; flat: true }
                ToolButton { text: "Help"; flat: true }
                Item { Layout.fillWidth: true }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: "#f5f6f7"
            border.color: terminal.breezeFrame
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 170
                    Layout.fillHeight: true
                    color: terminal.breezeWindow
                    border.color: terminal.breezeHighlight
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 4
                        Label {
                            text: TerminalSession.running ? "PowerShell" : "Session ended"
                            color: terminal.breezeText
                            font.family: "Noto Sans"
                            font.pixelSize: 10
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        ToolButton {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            icon.name: "window-close"
                            enabled: false
                        }
                    }
                }

                ToolButton {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    icon.name: "list-add"
                    onClicked: TerminalSession.start()
                    ToolTip.visible: hovered
                    ToolTip.text: "New Tab"
                }
                Item { Layout.fillWidth: true }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: terminal.terminalBackground

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                ScrollView {
                    id: scroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: output
                        readOnly: true
                        text: TerminalSession.output
                        color: terminal.terminalForeground
                        selectionColor: terminal.breezeHighlight
                        selectedTextColor: "white"
                        font.family: "Cascadia Mono"
                        font.pixelSize: 13
                        wrapMode: TextEdit.NoWrap
                        leftPadding: 10
                        rightPadding: 10
                        topPadding: 8
                        bottomPadding: 8
                        background: Rectangle { color: terminal.terminalBackground }
                        onTextChanged: cursorPosition = length
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: terminal.terminalBackground
                    border.color: "#34393e"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 6

                        Label {
                            text: ">"
                            color: terminal.breezeHighlight
                            font.family: "Cascadia Mono"
                            font.pixelSize: 14
                        }

                        TextField {
                            id: input
                            Layout.fillWidth: true
                            enabled: TerminalSession.running
                            placeholderText: TerminalSession.running ? "" : "Session ended"
                            color: terminal.terminalForeground
                            placeholderTextColor: "#7f8c8d"
                            font.family: "Cascadia Mono"
                            font.pixelSize: 13
                            selectByMouse: true
                            background: Rectangle { color: "transparent" }
                            Keys.onReturnPressed: {
                                TerminalSession.sendLine(text)
                                text = ""
                            }
                            Keys.onEscapePressed: text = ""
                        }

                        ToolButton {
                            Layout.preferredWidth: 34
                            text: "^C"
                            enabled: TerminalSession.running
                            onClicked: TerminalSession.sendText("\u0003")
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            color: terminal.breezeWindow
            border.color: terminal.breezeFrame
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                Label {
                    text: TerminalSession.running ? "PowerShell — ConPTY" : "Session ended"
                    color: terminal.breezeSecondary
                    font.family: "Noto Sans"
                    font.pixelSize: 9
                    Layout.fillWidth: true
                }
                ToolButton {
                    Layout.preferredHeight: 22
                    text: "Clear"
                    onClicked: TerminalSession.clear()
                }
            }
        }
    }

    Component.onCompleted: input.forceActiveFocus()
}
