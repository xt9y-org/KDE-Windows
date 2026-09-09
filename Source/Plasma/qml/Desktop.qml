import QtQuick
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
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#232a31" }
            GradientStop { position: 0.55; color: "#20262c" }
            GradientStop { position: 1.0; color: "#171a1d" }
        }
    }

    Rectangle {
        width: Math.min(parent.width * 0.58, 900)
        height: width
        radius: width / 2
        anchors.centerIn: parent
        color: "#123daee9"
        border.width: 1
        border.color: "#183daee9"
    }
}
