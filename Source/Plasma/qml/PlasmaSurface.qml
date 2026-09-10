import QtQuick

Rectangle {
    id: surface

    property bool viewStyle: false
    property bool selected: false

    radius: PlasmaTheme.popupRadius
    color: selected ? PlasmaTheme.highlightSoft : (viewStyle ? PlasmaTheme.view : PlasmaTheme.panel)
    border.color: selected ? PlasmaTheme.highlight : PlasmaTheme.frame
    border.width: 1

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, surface.radius - 1)
        color: "transparent"
        border.color: PlasmaTheme.innerHighlight
        border.width: 1
        opacity: surface.selected ? 0.35 : 0.75
    }
}
