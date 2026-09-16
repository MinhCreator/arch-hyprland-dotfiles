import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: launcher
    visible: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }

    property string query: ""
    property var clipData: []

    // Styling (copied from Luna.qml)
    property color clrBackground:  "#151218"
    property color clrSurface:     "#211e24"
    property color clrPrimary:     "#d5bbfc"
    property color clrOnSurface:   "#e7e0e8"
    property color clrOnSurfaceVar:"#cbc4cf"
    property color clrOutline:     "#49454e"
    property color clrSurfaceHigh: "#2c292f"

    Process {
        id: colorProc
        command: ["bash", "-c", "cat " + Quickshell.env("HOME") + "/.config/quickshell/Colors/colors.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var c = JSON.parse(data)
                    launcher.clrBackground   = c.background             || launcher.clrBackground
                    launcher.clrSurface      = c.surface_container      || launcher.clrSurface
                    launcher.clrPrimary      = c.primary                || launcher.clrPrimary
                    launcher.clrOnSurface    = c.on_surface             || launcher.clrOnSurface
                    launcher.clrOnSurfaceVar = c.on_surface_variant     || launcher.clrOnSurfaceVar
                    launcher.clrOutline      = c.outline_variant        || launcher.clrOutline
                    launcher.clrSurfaceHigh  = c.surface_container_high || launcher.clrSurfaceHigh
                } catch(e) {}
            }
        }
    }

    Process {
        id: clipLoader
        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: data => {
                launcher.clipData = data.split("\n").filter(line => line.trim() !== "").map(line => {
                    let parts = line.split("\t");
                    return { id: parts[0], text: parts[1] || "" };
                });
            }
        }
    }

    function refreshClip() {
        clipLoader.running = false
        clipLoader.running = true
    }

    function handleSelection() {
        if (clipList.currentIndex === -1) return;
        let item = filtered.values[clipList.currentIndex];
        copyClipAndPaste(item.id);
        if (typeof root !== 'undefined') root.emojiclipVisible = false;
        else Qt.quit();
    }

    function copyClipAndPaste(id) {
        let cmd = "echo " + JSON.stringify(id) + " | cliphist decode | wl-copy && wtype -M ctrl -k v -m ctrl";
        copyProc.command = ["bash", "-c", cmd];
        copyProc.running = true;
    }

    Process { id: copyProc }

    Component.onCompleted: {
        colorProc.running = true
        refreshClip()
        fadeIn.start()
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (typeof root !== 'undefined') root.emojiclipVisible = false;
                else Qt.quit();
            }
        }
    }

    Rectangle {
        id: mainPanel
        anchors.centerIn: parent
        width: 600
        height: 500
        color: launcher.clrBackground
        radius: 16
        border.width: 1
        border.color: launcher.clrOutline
        opacity: 0
        scale: 0.95

        Behavior on color { ColorAnimation { duration: 300 } }

        NumberAnimation {
            id: fadeIn
            target: mainPanel
            properties: "opacity,scale"
            to: 1
            duration: 150
            easing.type: Easing.OutCubic
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                height: 32
                Layout.fillWidth: true
                radius: 8
                color: launcher.clrPrimary
                border.width: 1
                border.color: launcher.clrOutline
                
                Text {
                    anchors.centerIn: parent
                    text: "󰅌 Clipboard"
                    color: launcher.clrBackground
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 13
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 10
                color: launcher.clrSurface
                border.width: 1
                border.color: input.activeFocus ? launcher.clrPrimary : launcher.clrOutline
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 300 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: "󰍉"
                        color: launcher.clrPrimary
                        font.pixelSize: 18
                        font.family: "JetBrains Mono"
                    }

                    TextField {
                        id: input
                        Layout.fillWidth: true
                        placeholderText: "Search clipboard..."
                        font.pixelSize: 15
                        font.family: "JetBrains Mono"
                        color: launcher.clrOnSurface
                        focus: true
                        leftPadding: 0; rightPadding: 0
                        topPadding: 0; bottomPadding: 0
                        placeholderTextColor: launcher.clrOnSurfaceVar
                        background: Rectangle { color: "transparent" }

                        onTextChanged: {
                            launcher.query = text
                            clipList.currentIndex = filtered.values.length > 0 ? 0 : -1
                        }

                        Keys.onEscapePressed: {
                            if (typeof root !== 'undefined') root.emojiclipVisible = false;
                            else Qt.quit();
                        }
                        Keys.onPressed: event => {
                            const ctrl = event.modifiers & Qt.ControlModifier
                            
                            if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && ctrl)) {
                                event.accepted = true
                                if (clipList.currentIndex > 0) clipList.currentIndex--
                            } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && ctrl)) {
                                event.accepted = true
                                if (clipList.currentIndex < clipList.count - 1) clipList.currentIndex++
                            } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
                                event.accepted = true
                                launcher.handleSelection()
                            }
                        }
                    }
                }
            }

            ScriptModel {
                id: filtered
                values: {
                    const q = launcher.query.trim().toLowerCase()
                    if (q === "") return launcher.clipData;
                    return launcher.clipData.filter(c => c.text.toLowerCase().includes(q));
                }
            }

            ListView {
                id: clipList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: filtered.values
                currentIndex: count > 0 ? 0 : -1
                spacing: 4
                highlightMoveDuration: 0

                highlight: Rectangle {
                    radius: 8
                    color: launcher.clrSurfaceHigh
                }

                delegate: Item {
                    id: clipEntry
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 52

                    MouseArea {
                        anchors.fill: parent
                        onClicked: clipList.currentIndex = clipEntry.index
                        onDoubleClicked: launcher.handleSelection()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: "󰅌"
                            font.pixelSize: 18
                            color: launcher.clrPrimary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: modelData.text
                                color: clipList.currentIndex === index ? launcher.clrPrimary : launcher.clrOnSurface
                                font.pixelSize: 13
                                font.family: "JetBrains Mono"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
