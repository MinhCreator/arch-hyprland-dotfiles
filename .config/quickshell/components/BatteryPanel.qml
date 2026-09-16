import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: batPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    
    anchors { top: true; right: true }
    margins {
        top: root.batVisible ? 54 : -batPanel.implicitHeight - 50
        right: Math.max(16, root.batteryButtonRightOffset - (batPanel.implicitWidth / 2))
    }
    
    implicitWidth: 460
    implicitHeight: 210
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: batPanel.focusState

    Shortcut {
        sequence: "Escape"
        enabled: root.batVisible
        onActivated: root.closeAllPopups()
        context: Qt.ApplicationShortcut
    }

    Behavior on margins.top { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    // ── Theme Aliases (Matching MusicPanel exactly) ──
    readonly property color walBackground: zyuTheme.bar_bg
    readonly property color walForeground: zyuTheme.bar_fg
    readonly property color walColor5:     zyuTheme.accent
    readonly property color walColor8:     Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.5)

    // ── Dynamic Battery Links ──
    // Safely reads the global service we set up in shell.qml
    property int batVal: root.batteryService ? root.batteryService.capacity : 100
    property string batStatus: root.batteryService ? root.batteryService.status : "Unknown"

    // ── Power Profile State ──
    property string activeProfile: "balanced"

    // ── Focus Handling ──
    property int focusState: WlrKeyboardFocus.None

    Connections {
        target: root
        function onBatVisibleChanged() {
            if (root.batVisible) {
                focusTimer.start()
                getProfileProc.running = true // Refresh profile when opened
            } else {
                focusTimer.stop()
                releaseTimer.stop()
                batPanel.focusState = WlrKeyboardFocus.None
            }
        }
    }
    Timer { 
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: { 
            batPanel.focusState = WlrKeyboardFocus.Exclusive
            releaseTimer.start() 
        } 
    }
    Timer { 
        id: releaseTimer
        interval: 100
        repeat: false
        onTriggered: { 
            batPanel.focusState = WlrKeyboardFocus.OnDemand
            mainItem.forceActiveFocus()
        } 
    }

    // ── Processes for Power Profiles ──
    Process {
        id: getProfileProc
        command: ["bash", "-c", "powerprofilesctl get"]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim()
                if (p.length > 0) batPanel.activeProfile = p
            }
        }
    }

    Process {
        id: setProfileProc
        property string targetProfile: ""
        command: ["bash", "-c", "powerprofilesctl set " + targetProfile]
        onExited: getProfileProc.running = true
    }

    Component.onCompleted: getProfileProc.running = true

    // ── UI ──
    Item {
        id: mainItem
        anchors.fill: parent
        focus: root.batVisible

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.batVisible = false
                event.accepted = true
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            // ═══════════════════════════════════════
            // MAIN CARD
            // ═══════════════════════════════════════
            Rectangle {
                width: 460
                height: 200
                color: Qt.rgba(batPanel.walBackground.r, batPanel.walBackground.g, batPanel.walBackground.b, 0.92)
                radius: 18
                border.color: Qt.rgba(batPanel.walForeground.r, batPanel.walForeground.g, batPanel.walForeground.b, 0.1)
                border.width: 1
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    // Giant Battery Icon
                    Rectangle {
                        Layout.preferredWidth: 130
                        Layout.preferredHeight: 130
                        Layout.alignment: Qt.AlignVCenter
                        radius: 14
                        color: Qt.rgba(batPanel.walColor5.r, batPanel.walColor5.g, batPanel.walColor5.b, 0.1)
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: {
                                var cap = batPanel.batVal
                                var s = batPanel.batStatus
                                if (s === "Charging") return "󰂄"
                                if (cap >= 90) return "󰁹"
                                if (cap >= 70) return "󰂁"
                                if (cap >= 50) return "󰁿"
                                if (cap >= 30) return "󰁽"
                                return "󰁺"
                            }
                            color: batPanel.walColor5
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 60
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }

                    // Details + Controls
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Text {
                            text: batPanel.batVal + "% Remaining"
                            color: batPanel.walForeground
                            font.pixelSize: 18; font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            Layout.fillWidth: true
                        }
                        Text {
                            text: {
                                var s = batPanel.batStatus
                                if (s === "Charging") return "Plugged In - Charging"
                                if (s === "Full") return "Plugged In - Full"
                                if (s === "Discharging") return "Discharging - On Battery"
                                return "Status Unknown"
                            }
                            color: batPanel.walColor8
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            opacity: 0.8
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true } // Spacer

                        Text {
                            text: "Power Profile"
                            color: batPanel.walColor8
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                        }

                        // Power Mode Selector Buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // 1. Power Saver
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 8
                                color: batPanel.activeProfile === "power-saver" ? batPanel.walColor5 : (psMa.containsMouse ? Qt.rgba(batPanel.walColor5.r, batPanel.walColor5.g, batPanel.walColor5.b, 0.2) : Qt.rgba(1,1,1,0.08))
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                RowLayout {
                                    anchors.centerIn: parent; spacing: 6
                                    Text { text: "󰌪"; color: batPanel.activeProfile === "power-saver" ? batPanel.walBackground : batPanel.walForeground; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
                                    Text { text: "Saver"; color: batPanel.activeProfile === "power-saver" ? batPanel.walBackground : batPanel.walForeground; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; font.bold: true }
                                }
                                MouseArea {
                                    id: psMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { setProfileProc.targetProfile = "power-saver"; setProfileProc.running = true }
                                }
                            }

                            // 2. Balanced
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 8
                                color: batPanel.activeProfile === "balanced" ? batPanel.walColor5 : (balMa.containsMouse ? Qt.rgba(batPanel.walColor5.r, batPanel.walColor5.g, batPanel.walColor5.b, 0.2) : Qt.rgba(1,1,1,0.08))
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                RowLayout {
                                    anchors.centerIn: parent; spacing: 6
                                    Text { text: "󰗑"; color: batPanel.activeProfile === "balanced" ? batPanel.walBackground : batPanel.walForeground; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
                                    Text { text: "Balanced"; color: batPanel.activeProfile === "balanced" ? batPanel.walBackground : batPanel.walForeground; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; font.bold: true }
                                }
                                MouseArea {
                                    id: balMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { setProfileProc.targetProfile = "balanced"; setProfileProc.running = true }
                                }
                            }

                            // 3. Performance
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 8
                                color: batPanel.activeProfile === "performance" ? batPanel.walColor5 : (perfMa.containsMouse ? Qt.rgba(batPanel.walColor5.r, batPanel.walColor5.g, batPanel.walColor5.b, 0.2) : Qt.rgba(1,1,1,0.08))
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                RowLayout {
                                    anchors.centerIn: parent; spacing: 6
                                    Text { text: "󰓅"; color: batPanel.activeProfile === "performance" ? batPanel.walBackground : batPanel.walForeground; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
                                    Text { text: "Perform"; color: batPanel.activeProfile === "performance" ? batPanel.walBackground : batPanel.walForeground; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; font.bold: true }
                                }
                                MouseArea {
                                    id: perfMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { setProfileProc.targetProfile = "performance"; setProfileProc.running = true }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
