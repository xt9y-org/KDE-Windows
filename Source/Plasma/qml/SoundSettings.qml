import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 12

    Label {
        text: "Sound"
        color: PlasmaTheme.text
        font.family: PlasmaTheme.fontFamily
        font.pixelSize: 20
        font.bold: true
    }
    Label {
        text: "Playback Devices"
        color: PlasmaTheme.secondaryText
        font.pixelSize: 11
    }

    PlasmaSurface {
        Layout.fillWidth: true
        Layout.preferredHeight: 104
        viewStyle: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: PlasmaBackend.audioAvailable ? "Default output device" : "No default audio output"
                    color: PlasmaTheme.text
                    font.bold: true
                    Layout.fillWidth: true
                }
                Label {
                    text: PlasmaBackend.muted ? "Muted" : PlasmaBackend.volume + "%"
                    color: PlasmaBackend.muted ? PlasmaTheme.negative : PlasmaTheme.secondaryText
                }
            }

            RowLayout {
                Layout.fillWidth: true
                PlasmaIconButton {
                    icon.name: PlasmaBackend.muted ? "audio-volume-muted" : "audio-volume-high"
                    enabled: PlasmaBackend.audioAvailable
                    onClicked: PlasmaBackend.toggleMute()
                }
                Slider {
                    id: volumeSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: PlasmaBackend.volume
                    enabled: PlasmaBackend.audioAvailable
                    onMoved: PlasmaBackend.setVolume(Math.round(value))
                }
                Label {
                    text: PlasmaBackend.volume + "%"
                    color: PlasmaTheme.text
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
