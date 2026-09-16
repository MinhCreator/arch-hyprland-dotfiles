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
    property bool panelVisible: false

    // IMPORTANT: Make sure this points to the absolute path of the script in your config!
    readonly property string scriptPath: Quickshell.configPath + "/scripts/kdeconnect-helper.sh"

    Process {
        id: pollProcess
        command: ["bash", kdeService.scriptPath]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    let jsonStr = data.trim();
                    if (jsonStr === "") return;
                    let parsed = JSON.parse(jsonStr);
                    
                    kdeService.isConnected = parsed.connected;
                    if (parsed.connected) {
                        kdeService.deviceId = parsed.id;
                        kdeService.batteryLevel = parsed.battery;
                        kdeService.isCharging = parsed.charging;
                        kdeService.notifications = parsed.notifications;
                    } else {
                        kdeService.notifications = [];
                    }
                } catch (e) {
                    console.log("KDEConnectService Parse Error: " + e);
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 5000 // Efficient 5s polling interval
        repeat: true
        running: true
        onTriggered: {
            if (!pollProcess.running) {
                pollProcess.running = true;
            }
        }
    }

    Process {
        id: actionProcess
        running: false
    }

    Component.onCompleted: {
        pollProcess.running = true;
    }

    function togglePanel() {
        panelVisible = !panelVisible;
    }

    function ringDevice() {
        if (!deviceId) return;
        actionProcess.command = ["kdeconnect-cli", "-d", deviceId, "--ring"];
        actionProcess.running = true;
    }

    function sendClipboard() {
        if (!deviceId) return;
        actionProcess.command = ["bash", "-c",
            "dbus-send --dest=org.kde.kdeconnect " +
            "/modules/kdeconnect/devices/" + deviceId + " " +
            "org.kde.kdeconnect.device.clipboard.sendClipboard " +
            "string:\"$(wl-paste)\""]
        actionProcess.running = true;
    }

    function sendText(text) {
        if (!deviceId) return;
        actionProcess.command = ["kdeconnect-cli", "-d", deviceId, "--ping-msg", text];
        actionProcess.running = true;
    }

    function sendFile() {
        if (!deviceId) return;
        // Zenity dialog for file selection
        actionProcess.command = ["bash", "-c", "FILE=$(zenity --file-selection --title='Select File to Send'); if [ -n \"$FILE\" ]; then kdeconnect-cli -d " + deviceId + " --share \"$FILE\"; fi"];
        actionProcess.running = true;
    }
}