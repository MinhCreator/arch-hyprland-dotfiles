import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: kdeService

    property bool isConnected: false
    property string deviceId: ""
    property string deviceName: "ULTRON"
    property int batteryLevel: 0
    property bool isCharging: false
    property var notifications: []
    property int unreadCount: notifications.length

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/kdeconnect-helper.sh"

    Process {
        id: pollProcess
        command: ["bash", kdeService.scriptPath]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    let jsonStr = data.trim()
                    if (jsonStr === "") return
                    console.log("KDE poll:", jsonStr)
                    let parsed = JSON.parse(jsonStr)
                    kdeService.isConnected = parsed.connected
                    if (parsed.connected) {
                        kdeService.deviceId = parsed.id
                        kdeService.batteryLevel = parsed.battery
                        kdeService.isCharging = parsed.charging
                        kdeService.notifications = parsed.notifications
                    } else {
                        kdeService.notifications = []
                    }
                } catch (e) {
                    console.log("KDEConnectService Parse Error: " + e)
                }
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: { if (!pollProcess.running) pollProcess.running = true }
    }

    Process { id: actionProcess; running: false }

    Component.onCompleted: {
    console.log("KDEConnectService loaded, scriptPath:", scriptPath)
    pollProcess.running = true
    }

    function ringDevice() {
        if (!deviceId) return
        actionProcess.command = ["kdeconnect-cli", "-d", deviceId, "--ring"]
        actionProcess.running = true
    }

    function sendClipboard() {
        if (!deviceId) return
        actionProcess.command = ["bash", "-c",
            "dbus-send --dest=org.kde.kdeconnect " +
            "/modules/kdeconnect/devices/" + deviceId + " " +
            "org.kde.kdeconnect.device.clipboard.sendClipboard " +
            "string:\"$(wl-paste)\""]
        actionProcess.running = true
    }

    function sendText(text) {
        if (!deviceId) return
        actionProcess.command = ["kdeconnect-cli", "-d", deviceId, "--ping-msg", text]
        actionProcess.running = true
    }

    function sendFile() {
        if (!deviceId) return
        actionProcess.command = ["bash", "-c",
            "FILE=$(kdialog --getopenfilename ~); " +
            "if [ -n \"$FILE\" ]; then kdeconnect-cli -d " + deviceId + " --share \"$FILE\"; fi"]
        actionProcess.running = true
    }
}
