import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: btPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { 
        top: root.btVisible ? 54 : -btPanel.implicitHeight - 50 
        right: Math.max(16, root.bluetoothButtonRightOffset - (btPanel.implicitWidth / 2)) 
    }
    implicitHeight: 440
    implicitWidth: 340
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.btVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    onVisibleChanged: if (visible && root.btVisible) forceActiveFocus()

    Shortcut {
        sequence: "Escape"
        enabled: root.btVisible
        onActivated: root.closeAllPopups()
        context: Qt.ApplicationShortcut
    }

    Behavior on margins.top { 
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic } 
    }

    readonly property color bg:      zyuTheme.bar_bg
    readonly property color fg:      zyuTheme.bar_fg
    readonly property color accent:  zyuTheme.accent
    readonly property color muted:   Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.4)
    readonly property color danger:  "#f38ba8"

    property bool btEnabled:   false
    property var btDevices: []
    property bool btScanning: false
    property string connectedDevice: ""
    property int connectedBattery: -1
    property string connectedIcon: "󰂯"

    property string lastDevice: "INITIALIZING"
    property bool initialBtChecked: false
    
    onConnectedDeviceChanged: {
        if (!initialBtChecked) {
            initialBtChecked = true
            lastDevice = connectedDevice
            return
        }
        
        if (connectedDevice !== lastDevice) {
            if (connectedDevice !== "" && lastDevice === "") {
                btNotifyProc.send(connectedDevice, "Connected", "bluetooth-symbolic")
            } else if (connectedDevice === "" && lastDevice !== "") {
                btNotifyProc.send("Bluetooth", "Disconnected", "bluetooth-symbolic")
            }
            lastDevice = connectedDevice
        }
    }
    
    property bool initialEnabledChecked: false
    property bool startupCooldown: true

    Timer {
        id: startupCooldownTimer
        interval: 3000
        running: true
        repeat: false
        onTriggered: btPanel.startupCooldown = false
    }

    onBtEnabledChanged: {
        if (!initialEnabledChecked) {
            initialEnabledChecked = true
            return
        }

        // Save state to file
        writeBtStateProc.stateVal = btEnabled ? "enabled" : "disabled"
        writeBtStateProc.running = true

        if (!startupCooldown) {
            if (btEnabled) {
                btNotifyProc.send("Bluetooth Enabled", "Bluetooth is on", "bluetooth-symbolic")
            } else {
                btNotifyProc.send("Bluetooth Disabled", "Bluetooth is off", "bluetooth-symbolic")
            }
        }
    }

    function refreshBt() {
        if (btScanning) return;
        btDevices = []
        btScanning = true
        btStatusProc.running = true
        btCurrentProc.running = true
        btInfoProc.running = true
        btScanProc.running = true
    }

    Timer {
        id: btPollingTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            btStatusProc.running = true
            btCurrentProc.running = true
            btInfoProc.running = true
        }
    }

    Component.onCompleted: {
        restoreBtStateProc.running = true
        refreshBt()
    }

    // --- Bluetooth Processes ---

    Process {
        id: btStatusProc
        command: ["bash", "-c", "bluetoothctl show | grep 'Powered: yes' >/dev/null && echo 'enabled' || echo 'disabled'"]
        stdout: SplitParser { onRead: data => btPanel.btEnabled = data.trim() === "enabled" }
    }

    Process {
        id: btCurrentProc
        command: ["bash", "-c", "bluetoothctl devices Connected | head -n 1 | awk '{sub(/^[^ ]+ [^ ]+ /, \"\"); print; found=1} END {if (!found) print \"disconnected\"}'"]
        stdout: SplitParser { 
            onRead: data => {
                var name = data.trim()
                if (name === "" || name === "disconnected") {
                    btPanel.connectedDevice = ""
                    btPanel.connectedBattery = -1
                    btPanel.connectedIcon = "󰂯"
                } else {
                    btPanel.connectedDevice = name
                    btInfoProc.running = true
                }
            }
        }
    }

    Process {
        id: btInfoProc
        command: ["bash", "-c", "bluetoothctl info | grep -E 'Battery Percentage|Icon'"]
        stdout: SplitParser {
            onRead: data => {
                var lines = data.split('\n')
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.includes("Battery Percentage")) {
                        var bat = line.match(/\((\d+)\)/)
                        if (bat) btPanel.connectedBattery = parseInt(bat[1])
                    }
                    if (line.includes("Icon")) {
                        var icon = line.split(":")[1].trim()
                        if (icon === "audio-card" || icon === "audio-headset") btPanel.connectedIcon = "󰋋"
                        else if (icon === "phone") btPanel.connectedIcon = "󰏲"
                        else if (icon === "audio-headphones") btPanel.connectedIcon = "󰋋"
                        else if (icon === "input-mouse") btPanel.connectedIcon = "󰍽"
                        else btPanel.connectedIcon = "󰂯"
                    }
                }
            }
        }
    }

    Process {
        id: btScanProc
        command: ["bash", "-c", "bluetoothctl --timeout 5 scan on >/dev/null; bluetoothctl devices"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split(" ")
                if (parts.length < 3) return
                var mac = parts[1]
                var name = parts.slice(2).join(" ")
                
                var current = btPanel.btDevices.slice()
                for (var i = 0; i < current.length; i++) { if (current[i].mac === mac) return }
                current.push({ name: name, mac: mac })
                btPanel.btDevices = current
            }
        }
        onExited: btPanel.btScanning = false
    }

    Process {
        id: writeBtStateProc
        property string stateVal: ""
        command: ["bash", "-c", "mkdir -p ~/.config/quickshell/state && echo '" + stateVal + "' > ~/.config/quickshell/state/bluetooth-state"]
    }

    Process {
        id: restoreBtStateProc
        command: ["bash", "-c", "cat ~/.config/quickshell/state/bluetooth-state 2>/dev/null || echo 'enabled'"]
        stdout: SplitParser {
            onRead: data => {
                var savedState = data.trim()
                if (savedState === "disabled") {
                    btOffProc.running = true
                } else if (savedState === "enabled") {
                    btOnProc.running = true
                }
            }
        }
    }

    Process {
        id: btOffProc
        command: ["bluetoothctl", "power", "off"]
        onExited: btPanel.refreshBt()
    }

    Process {
        id: btOnProc
        command: ["bluetoothctl", "power", "on"]
        onExited: btPanel.refreshBt()
    }

    Process {
        id: btToggleProc
        command: ["bash", "-c", btPanel.btEnabled ? "bluetoothctl power off" : "bluetoothctl power on"]
        onExited: btPanel.refreshBt()
    }

    Process {
        id: btConnectProc
        property string mac: ""
        command: ["bash", "-c", "bluetoothctl connect " + mac]
        onExited: btPanel.refreshBt()
    }

    Process {
        id: btDisconnectProc
        command: ["bash", "-c", "bluetoothctl disconnect"]
        onExited: { btPanel.connectedDevice = "" }
    }

    Process {
        id: btNotifyProc
        function send(summary, body, icon) {
            command = ["notify-send", "-i", icon, summary, body]
            running = true
        }
    }

    // --- UI Structure ---

    Item {
        anchors.fill: parent
        focus: root.btVisible

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.btVisible = false
                event.accepted = true
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(btPanel.bg.r, btPanel.bg.g, btPanel.bg.b, 0.92)
            radius: 18
            border.color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 36; height: 36; radius: 12
                        color: Qt.rgba(btPanel.accent.r, btPanel.accent.g, btPanel.accent.b, 0.15)
                        Text {
                            anchors.centerIn: parent
                            text: "󰂯"
                            color: btPanel.accent
                            font.pixelSize: 20
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Bluetooth"
                            color: btPanel.fg
                            font.pixelSize: 15; font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        Text {
                            text: btPanel.btEnabled ? (btPanel.connectedDevice !== "" ? "Connected" : "On") : "Off"
                            color: btPanel.muted
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Toggle Switch
                    Rectangle {
                        width: 48; height: 26; radius: 13
                        color: btPanel.btEnabled ? btPanel.accent : Qt.rgba(0.3, 0.3, 0.3, 0.5)
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Rectangle {
                            width: 22; height: 22; radius: 11; y: 2
                            x: btPanel.btEnabled ? 24 : 2
                            color: btPanel.bg
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: btToggleProc.running = true
                        }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: 8
                        color: closeMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: btPanel.muted
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.btVisible = false
                        }
                    }
                }

                // Connected Device Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: 14
                    color: Qt.rgba(btPanel.accent.r, btPanel.accent.g, btPanel.accent.b, 0.08)
                    border.color: Qt.rgba(btPanel.accent.r, btPanel.accent.g, btPanel.accent.b, 0.2)
                    border.width: 1
                    visible: btPanel.connectedDevice !== ""

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14; anchors.rightMargin: 14
                        spacing: 12

                        Text {
                            text: "󰂱"
                            color: btPanel.accent
                            font.pixelSize: 16
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: btPanel.connectedDevice
                                color: btPanel.fg
                                font.pixelSize: 13; font.bold: true
                                font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            width: 28; height: 28; radius: 8
                            color: btDiscMa.containsMouse ? Qt.rgba(btPanel.danger.r, btPanel.danger.g, btPanel.danger.b, 0.15) : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: btDiscMa.containsMouse ? btPanel.danger : btPanel.muted
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                id: btDiscMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: btDisconnectProc.running = true
                            }
                        }
                    }
                }

                // Available Devices List
                RowLayout {
                    Layout.fillWidth: true
                    visible: btPanel.btEnabled
                    Text {
                        text: "Devices Found"
                        color: btPanel.muted
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Item { Layout.fillWidth: true }
                    
                    // FIXED RELOAD BUTTON
                    Text {
                        text: "󰑐"
                        color: reloadMa.containsMouse ? btPanel.accent : btPanel.muted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        Behavior on color { ColorAnimation { duration: 150 } }

                        // Spinning Animation while scanning
                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1000
                            running: btPanel.btScanning
                        }

                        MouseArea { 
                            id: reloadMa
                            anchors.fill: parent
                            anchors.margins: -8 // Expands the clickable area
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: btPanel.refreshBt() 
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(0, 0, 0, 0.15)
                    radius: 14
                    clip: true

                    ListView {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        model: btPanel.btDevices
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 48
                            radius: 12
                            color: btItemMa.containsMouse ? Qt.rgba(btPanel.accent.r, btPanel.accent.g, btPanel.accent.b, 0.08) : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                Text { text: "󰂯"; color: btPanel.accent; font.family: "JetBrainsMono Nerd Font" }
                                Text {
                                    text: modelData.name
                                    color: btPanel.fg
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: btItemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    btConnectProc.mac = modelData.mac
                                    btConnectProc.running = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
