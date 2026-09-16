import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: batPopup
    
    // Only show when the service says to
    visible: batteryService.showWarning
    
    // Center it on the screen, or put it top-right
    anchors { top: true; right: true }
    margins { top: 54; right: 20 }
    
    implicitWidth: 300
    implicitHeight: 100
    
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay // Put it above everything

    Rectangle {
        width: 300
        height: 100
        radius: zyuTheme.rounding
        color: zyuTheme.bar_bg
        border.color: batteryService.warningLevel === "critical" ? "#f38ba8" : zyuTheme.accent
        border.width: 2

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text {
                text: batteryService.warningLevel === "critical" ? "󰂃" : "󰁻"
                color: batteryService.warningLevel === "critical" ? "#f38ba8" : zyuTheme.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 36
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                Text {
                    text: batteryService.warningLevel === "critical" ? "Battery Critical!" : "Battery Low"
                    color: zyuTheme.bar_fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: batteryService.capacity + "% remaining. Plug in charger."
                    color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.6)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }
            }
        }

        // Click to dismiss
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: batteryService.dismissed = true
        }
    }
}
