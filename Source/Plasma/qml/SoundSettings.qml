import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 18

    Label { text: "Sound"; color: "#eff0f1"; font.pixelSize: 28; font.bold: true }
    Label {
        text: PlasmaBackend.audioAvailable ? "Default output device" : "No default audio output"
        color: "#d8dcdf"
        font.pixelSize: 16
    }

    RowLayout {
        Layout.fillWidth: true
        Button {
            text: PlasmaBackend.muted ? "Unmute" : "Mute"
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
        Label { text: PlasmaBackend.volume + "%"; color: "#eff0f1"; Layout.preferredWidth: 48 }
    }

    Item { Layout.fillHeight: true }
}
