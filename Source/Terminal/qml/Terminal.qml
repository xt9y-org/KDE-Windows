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
    color: "#17191b"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            color: "#25292d"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Label {
                    text: TerminalSession.running ? "PowerShell" : "Session ended"
                    color: "#eff0f1"
                    font.bold: true
                    Layout.fillWidth: true
                }

                ToolButton {
                    text: "Clear"
                    onClicked: TerminalSession.clear()
                }

                ToolButton {
                    text: TerminalSession.running ? "Restart" : "Start"
                    onClicked: TerminalSession.start()
                }
            }
        }

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: output
                readOnly: true
                text: TerminalSession.output
                color: "#eff0f1"
                selectionColor: "#3daee9"
                selectedTextColor: "white"
                font.family: "Cascadia Mono"
                font.pixelSize: 13
                wrapMode: TextEdit.NoWrap
                background: Rectangle { color: "#17191b" }
                onTextChanged: cursorPosition = length
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: "#202428"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Label {
                    text: ">"
                    color: "#3daee9"
                    font.family: "Cascadia Mono"
                    font.pixelSize: 15
                }

                TextField {
                    id: input
                    Layout.fillWidth: true
                    enabled: TerminalSession.running
                    placeholderText: TerminalSession.running ? "Command" : "Start a session to enter commands"
                    font.family: "Cascadia Mono"
                    font.pixelSize: 13
                    selectByMouse: true
                    background: Rectangle {
                        radius: 6
                        color: "#2a2f34"
                        border.color: input.activeFocus ? "#3daee9" : "#41484f"
                    }
                    Keys.onReturnPressed: {
                        if (text.length === 0)
                            TerminalSession.sendLine("")
                        else
                            TerminalSession.sendLine(text)
                        text = ""
                    }
                    Keys.onEscapePressed: text = ""
                }

                ToolButton {
                    text: "^C"
                    enabled: TerminalSession.running
                    onClicked: TerminalSession.sendText("\u0003")
                }
            }
        }
    }

    Component.onCompleted: input.forceActiveFocus()
}
