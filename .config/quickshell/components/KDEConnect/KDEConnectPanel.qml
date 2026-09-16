import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: kdePanel
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { 
        top: root.kdeConnectVisible ? 54 : -kdePanel.implicitHeight - 50; 
        right: Math.max(16, root.kdeConnectButtonRightOffset - (kdePanel.implicitWidth / 2)) 
    }
    implicitWidth: 380
    implicitHeight: mainLayout.implicitHeight + 40
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.kdeConnectVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: true

    Behavior on margins.top { 
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic } 
    }

    property var svc: root.kdeConnectService
    property color primary: zyuTheme.accent
    property color textMain: zyuTheme.bar_fg
    property color textMuted: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.6)
    property color cardBg: zyuTheme.widget_bg
    property color glassBorder: Qt.rgba(1, 1, 1, 0.06)

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: zyuTheme.bar_bg
        border.color: glassBorder
        border.width: 1
        focus: true

        Keys.onEscapePressed: root.kdeConnectVisible = false

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                height: 72
                radius: 14
                color: cardBg
                border.color: glassBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Rectangle {
                        width: 40; height: 40; radius: 10
                        color: Qt.rgba(primary.r, primary.g, primary.b, 0.15)
                        Text {
                            anchors.centerIn: parent
                            text: "󰏲"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            color: primary
                        }
                    }

                    ColumnLayout {
                        spacing: 3
                        Text {
                            text: svc ? svc.deviceName : "—"
                            color: textMain
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        RowLayout {
                            spacing: 5
                            Rectangle {
                                width: 7; height: 7; radius: 4
                                color: svc && svc.isConnected ? "#a6e3a1" : "#f38ba8"
                            }
                            Text {
                                text: svc && svc.isConnected ? "Connected" : "Disconnected"
                                color: textMuted
                                font.pixelSize: 12
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Column {
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: svc ? svc.batteryLevel + "%" : "—"
                            color: textMain
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: svc && svc.isCharging ? "⚡" : "🔋"
                            font.pixelSize: 14
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: svc && svc.notifications && svc.notifications.length > 0

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Notifications"
                        color: textMuted
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        color: primary
                        Text {
                            anchors.centerIn: parent
                            text: svc ? svc.unreadCount : "0"
                            color: zyuTheme.bar_bg
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.min(notifList.contentHeight + 12, 220)
                    radius: 12
                    color: cardBg
                    border.color: glassBorder
                    border.width: 1
                    clip: true

                    ListView {
                        id: notifList
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        model: svc ? svc.notifications : []
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 52; radius: 8
                            color: "transparent"
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                Rectangle {
                                    width: 28; height: 28; radius: 6
                                    color: Qt.rgba(primary.r, primary.g, primary.b, 0.15)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰂚"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        color: primary
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        text: modelData.appName || ""
                                        color: textMain
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.ticker || modelData.title || ""
                                        color: textMuted
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                component ActionButton: Rectangle {
                    id: btnRoot
                    property string label: ""
                    property string ico: ""
                    signal activated()

                    Layout.fillWidth: true
                    height: 44; radius: 22
                    color: abMa.containsMouse
                        ? Qt.rgba(primary.r, primary.g, primary.b, 0.2)
                        : cardBg
                    border.color: glassBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: btnRoot.ico
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: primary
                        }
                        Text {
                            text: btnRoot.label
                            color: textMain
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    MouseArea {
                        id: abMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btnRoot.activated()
                    }
                }

                ActionButton { label: "Ring Device";    ico: "󰂚"; onActivated: if (svc) svc.ringDevice() }
                ActionButton { label: "Send Clipboard"; ico: "󰆒"; onActivated: if (svc) svc.sendClipboard() }
                ActionButton { label: "Send Text";      ico: "󰍦"; onActivated: if (svc) svc.sendText("Ping from Quickshell!") }
                ActionButton { label: "Send File";      ico: "󰈤"; onActivated: if (svc) svc.sendFile() }
            }
        }
    }
}
