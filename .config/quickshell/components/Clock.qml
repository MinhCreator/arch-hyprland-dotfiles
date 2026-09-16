import Quickshell
import Quickshell.Wayland
import QtQuick
import Qt5Compat.GraphicalEffects 

ShellRoot {
    property color accentColor: "#ffffff"
    property string activeFont: "Google Sans Flex"

    PanelWindow {
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "clock-widget"
        WlrLayershell.exclusiveZone: -1 
        color: "transparent"

        // We use a simple Timer instead of SystemClock to ensure we grab the local JS Date
        Timer {
            id: clockTimer
            interval: 1000 // Update every second
            running: true
            repeat: true
            onTriggered: {
                // new Date() automatically grabs the system's local time (IST)
                var d = new Date()
                clock_time.text = Qt.formatTime(d, "H:mm")
                day_text.text = Qt.formatDate(d, "dddd").toUpperCase()
                date_text.text = Qt.formatDate(d, "d MMMM yyyy").toUpperCase()
            }
        }

        Rectangle {
            id: backgroundGuard
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            
            anchors.leftMargin: 80 
            anchors.bottomMargin: 15
            
            width: contentRow.width + 40
            height: contentRow.height + 30
            
            radius: 12
            color: "#44000000"
            border.color: "#11ffffff" 
            border.width: 1

            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: FastBlur {
                    radius: 30
                }
            }

            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: 20

                Text {
                    id: clock_time
                    // Initial load text
                    text: Qt.formatTime(new Date(), "H:mm")
                    font.family: activeFont
                    font.pixelSize: 64 
                    font.weight: Font.Bold
                    color: accentColor
                    antialiasing: true
                }

                Rectangle {
                    width: 1
                    height: clock_time.contentHeight * 0.6
                    color: accentColor
                    opacity: 0.2
                    anchors.verticalCenter: clock_time.verticalCenter
                }

                Column {
                    anchors.verticalCenter: clock_time.verticalCenter
                    spacing: 0

                    Text {
                        id: day_text
                        // Initial load text
                        text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                        font.family: activeFont
                        font.pixelSize: 25
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: accentColor
                    }

                    Text {
                        id: date_text
                        // Initial load text
                        text: Qt.formatDate(new Date(), "d MMMM yyyy").toUpperCase()
                        font.family: activeFont
                        font.pixelSize: 10
                        font.weight: Font.Normal
                        font.letterSpacing: 1
                        color: accentColor
                        opacity: 0.6
                    }
                }
            }
        }
    }
}
