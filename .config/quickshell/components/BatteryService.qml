import QtQuick
import Quickshell.Io

Item {
    id: root

    // Public properties that your UI can read
    property int capacity: 100
    property string status: "Unknown"
    property bool charging: false
    property bool showWarning: false
    property string warningLevel: "" // "low" or "critical"
    property bool dismissed: false

    // Thresholds
    readonly property int lowLevel: 20
    readonly property int criticalLevel: 10

    onStatusChanged: {
        if (status === "Charging") dismissed = false
    }

    Timer {
        interval: 5000 // Check every 5 seconds for real-time updates
        running: true
        repeat: true
        onTriggered: {
            batCapProc.running = true
            batStatProc.running = true
        }
        Component.onCompleted: {
            batCapProc.running = true
            batStatProc.running = true
            profileProc.running = true
        }
    }

    Process {
        id: profileProc
        command: ["bash", "-c", "powerprofilesctl get"]
        stdout: SplitParser {
            onRead: data => root.powerProfile = data.trim()
        }
    }

    // Process 1: Get Capacity (Foolproof Wildcard)
    Process {
        id: batCapProc
        command: ["bash", "-c", "cat /sys/class/power_supply/*/capacity 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseInt(data.trim())
                if (!isNaN(val)) {
                    root.capacity = val
                    root.checkBatteryState()
                }
            }
        }
    }

    // Process 2: Get Status (Foolproof Wildcard)
    Process {
        id: batStatProc
        command: ["bash", "-c", "cat /sys/class/power_supply/*/status 2>/dev/null | grep -v 'Unknown' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                var s = data.trim()
                if (s.length > 0) {
                    root.status = s
                    root.checkBatteryState()
                }
            }
        }
    }

    property string powerProfile: "balanced" // performance, balanced, power-saver

    function checkBatteryState() {
        root.charging = (status === "Charging" || status === "Full")
        
        if (status === "Discharging") {
            if (capacity <= criticalLevel) {
                if (warningLevel !== "critical") {
                    warningLevel = "critical"
                    dismissed = false
                }
                showWarning = !dismissed
            } else if (capacity <= lowLevel) {
                if (warningLevel !== "low") {
                    warningLevel = "low"
                    dismissed = false
                }
                showWarning = !dismissed
            } else {
                showWarning = false
                warningLevel = ""
                dismissed = false
            }
        } else if (status === "Charging" || status === "Full") {
            showWarning = false
            warningLevel = ""
            dismissed = false
        }
    }
}
