import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: calendar
    visible: false
    width: 360
    height: 380
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    property int panelX: 0
    property int panelY: 0
    property int panelWidth: 0
    property date shownMonth: new Date()
    signal dismissed()

    x: panelX + panelWidth - width
    y: panelY - height - 6

    function shiftMonth(delta) {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + delta, 1)
    }

    onVisibleChanged: {
        if (visible) {
            shownMonth = new Date()
            requestActivate()
        }
    }

    Keys.onEscapePressed: dismissed()

    PlasmaSurface {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 38

                Label {
                    Layout.fillWidth: true
                    text: Qt.formatDate(calendar.shownMonth, "MMMM yyyy")
                    color: PlasmaTheme.text
                    font.family: PlasmaTheme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                }

                PlasmaIconButton {
                    icon.name: "go-previous"
                    onClicked: calendar.shiftMonth(-1)
                    ToolTip.visible: hovered
                    ToolTip.text: "Previous Month"
                }
                PlasmaIconButton {
                    icon.name: "go-next"
                    onClicked: calendar.shiftMonth(1)
                    ToolTip.visible: hovered
                    ToolTip.text: "Next Month"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: PlasmaTheme.separator
            }

            DayOfWeekRow {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                locale: Qt.locale()
                delegate: Label {
                    required property var model
                    text: model.shortName
                    color: PlasmaTheme.secondaryText
                    font.family: PlasmaTheme.fontFamily
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MonthGrid {
                id: monthGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                month: calendar.shownMonth.getMonth()
                year: calendar.shownMonth.getFullYear()
                locale: Qt.locale()

                delegate: Item {
                    required property var model

                    Rectangle {
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        radius: 15
                        color: model.today ? PlasmaTheme.highlight : "transparent"

                        Label {
                            anchors.centerIn: parent
                            text: model.day
                            color: model.today ? PlasmaTheme.highlightedText : PlasmaTheme.text
                            opacity: model.month === monthGrid.month ? 1.0 : 0.45
                            font.family: PlasmaTheme.fontFamily
                            font.pixelSize: 11
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
                Layout.preferredHeight: 34
                Label {
                    Layout.fillWidth: true
                    text: Qt.formatDate(new Date(), "dddd, d MMMM")
                    color: PlasmaTheme.secondaryText
                    font.family: PlasmaTheme.fontFamily
                    font.pixelSize: 11
                }
                Button {
                    text: "Today"
                    onClicked: calendar.shownMonth = new Date()
                }
            }
        }
    }
}
