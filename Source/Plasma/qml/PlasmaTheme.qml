pragma Singleton
import QtQuick

QtObject {
    id: theme

    property bool dark: false

    readonly property color window: dark ? "#232629" : "#eff0f1"
    readonly property color view: dark ? "#1b1e20" : "#fcfcfc"
    readonly property color panel: dark ? "#2a2e32" : "#eef1f4"
    readonly property color button: dark ? "#31363b" : "#f2f3f4"
    readonly property color buttonHover: dark ? "#3b4248" : "#dcecf5"
    readonly property color buttonPressed: dark ? "#45515a" : "#c9e3f1"
    readonly property color alternate: dark ? "#2a2f33" : "#f5f6f7"
    readonly property color frame: dark ? "#4f565d" : "#b9c0c4"
    readonly property color separator: dark ? "#454b50" : "#d1d5d8"
    readonly property color innerHighlight: dark ? "#22ffffff" : "#99ffffff"
    readonly property color text: dark ? "#eff0f1" : "#232629"
    readonly property color secondaryText: dark ? "#bdc3c7" : "#5f6265"
    readonly property color disabledText: dark ? "#7f8c8d" : "#7f8c8d"
    readonly property color highlight: "#3daee9"
    readonly property color highlightSoft: dark ? "#314b5a" : "#d9edf8"
    readonly property color highlightedText: "#ffffff"
    readonly property color positive: "#27ae60"
    readonly property color neutral: "#f67400"
    readonly property color negative: "#da4453"

    readonly property int panelHeight: 44
    readonly property int panelMargin: 4
    readonly property int popupRadius: 7
    readonly property int itemRadius: 4
    readonly property int smallSpacing: 4
    readonly property int spacing: 8
    readonly property int largeSpacing: 12
    readonly property int iconSize: 22
    readonly property int largeIconSize: 32
    readonly property string fontFamily: "Noto Sans"
}
