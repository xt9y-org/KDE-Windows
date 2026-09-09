import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: calendar
    visible: false
    width: 360
    height: 360
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"

    property int panelX: 0
    property int panelY: 0
    property int panelWidth: 0
    property date shownMonth: new Date()
    signal dismissed()

    x: panelX + panelWidth - width - 8
    y: panelY - height - 8

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

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#f223272b"
        border.color: "#5a596168"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                ToolButton { text: "‹"; onClicked: calendar.shiftMonth(-1) }
                Label {
                    Layout.fillWidth: true
                    text: Qt.formatDate(calendar.shownMonth, "MMMM yyyy")
                    horizontalAlignment: Text.AlignHCenter
                    color: "#eff0f1"
                    font.pixelSize: 17
                    font.bold: true
                }
                ToolButton { text: "›"; onClicked: calendar.shiftMonth(1) }
            }

            DayOfWeekRow {
                Layout.fillWidth: true
                locale: Qt.locale()
                delegate: Label {
                    required property var model
                    text: model.shortName
                    color: "#9da5ab"
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

                delegate: Rectangle {
                    required property var model
                    color: model.today ? "#3daee9" : "transparent"
                    radius: 7
                    opacity: model.month === monthGrid.month ? 1.0 : 0.45

                    Label {
                        anchors.centerIn: parent
                        text: model.day
                        color: model.today ? "white" : "#eff0f1"
                    }
                }
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                text: "Today"
                onClicked: calendar.shownMonth = new Date()
            }
        }
    }
}
