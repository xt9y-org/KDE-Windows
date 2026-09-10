import QtQuick
import QtQuick.Controls

ToolButton {
    id: control

    implicitWidth: 34
    implicitHeight: 34
    hoverEnabled: true
    display: AbstractButton.IconOnly
    icon.width: PlasmaTheme.iconSize
    icon.height: PlasmaTheme.iconSize
    icon.color: PlasmaTheme.text
    palette.buttonText: PlasmaTheme.text
    palette.highlight: PlasmaTheme.highlight
    palette.highlightedText: PlasmaTheme.highlightedText

    background: Rectangle {
        radius: PlasmaTheme.itemRadius
        color: control.down ? PlasmaTheme.buttonPressed : control.hovered ? PlasmaTheme.buttonHover : "transparent"
        border.width: control.activeFocus ? 1 : 0
        border.color: PlasmaTheme.highlight
    }
}
