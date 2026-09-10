import QtQuick
import QtQuick.Controls

ItemDelegate {
    id: control

    property bool current: false

    hoverEnabled: true
    implicitHeight: 38
    palette.buttonText: current ? PlasmaTheme.highlightedText : PlasmaTheme.text
    palette.highlightedText: PlasmaTheme.highlightedText
    palette.highlight: PlasmaTheme.highlight

    background: Rectangle {
        radius: PlasmaTheme.itemRadius
        color: control.current ? PlasmaTheme.highlight : control.down ? PlasmaTheme.buttonPressed : control.hovered ? PlasmaTheme.buttonHover : "transparent"
    }
}
