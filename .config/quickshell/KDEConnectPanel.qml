import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: kdePanel
    property var service

    exclusionMode: ExclusionMode.Ignore
    
    anchors { top: true; right: true }
    margins {
        top: service.panelVisible ? 65 : -(kdePanel.implicitHeight + 20)
        right: 20
    }
    
    opacity: service.panelVisible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 200 } }
    
    implicitWidth: 400
    implicitHeight: mainLayout.implicitHeight + 40
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: service.panelVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    Behavior on margins.top { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    
    property color surface: Qt.rgba(0.04, 0.05, 0.04, 0.92)
    property color surfaceVariant: Qt.darker(surface, 1.2)
    property color primary: "#A3D9A5"
    property color onPrimary: "#003912"
    property color textMain: "#E8F5E9"
    property color textMuted: Qt.rgba(0.91, 0.96, 0.91, 0.6)
    property color glassBorder: Qt.rgba(1, 1, 1, 0.08)

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(0.04, 0.05, 0.04, 0.85) // Glass effect
        border.color: glassBorder
        border.width: 1

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // Header
            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 16
                color: surfaceVariant
                border.color: glassBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Rectangle {
                        width: 48
                        height: 48
                        radius: 12
                        color: Qt.rgba(primary.r, primary.g, primary.b, 0.1)

                        Image {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: "image://icon/smartphone"
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: service.deviceName
                            color: textMain
                            font.pixelSize: 18
                            font.bold: true
                        }
                        RowLayout {
                            spacing: 6
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: service.isConnected ? primary : "red"
                            }
                            Text {
                                text: service.isConnected ? "Connected" : "Disconnected"
                                color: textMuted
                                font.pixelSize: 13
                            }
                        }
                    }

                    Item { Layout.fillWidth: true } // spacer

                    RowLayout {
                        spacing: 4
                        Text {
                            text: service.batteryLevel + "%"
                            color: textMain
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Image {
                            source: service.isCharging ? "image://icon/battery-charging" : "image://icon/battery"
                            width: 18
                            height: 18
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }
            }

            // Notifications
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                visible: service.notifications.length > 0

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Notifications"
                        color: textMuted
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: primary
                        Text {
                            anchors.centerIn: parent
                            text: service.unreadCount
                            color: onPrimary
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.min(notifList.contentHeight + 16, 250)
                    radius: 16
                    color: surfaceVariant
                    border.color: glassBorder
                    border.width: 1
                    clip: true

                    ListView {
                        id: notifList
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4
                        model: service.notifications
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 60
                            radius: 8
                            color: "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Image {
                                    source: "image://icon/" + modelData.appName.toLowerCase().replace(/ /g, "-")
                                    width: 24
                                    height: 24
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        text: modelData.appName
                                        color: textMain
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Text {
                                        text: modelData.ticker || modelData.title
                                        color: textMuted
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Actions Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 12
                columnSpacing: 12

                component ActionButton: Rectangle {
                    id: btnRoot
                    property string text
                    property string icon
                    property color bgColor: surfaceVariant
                    property color fgColor: textMain
                    signal clicked()

                    Layout.fillWidth: true
                    height: 48
                    radius: 24
                    color: bgColor
                    border.color: glassBorder
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Image {
                            source: btnRoot.icon
                            width: 16
                            height: 16
                        }
                        Text {
                            text: btnRoot.text
                            color: btnRoot.fgColor
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btnRoot.clicked()
                    }
                }

                ActionButton {
                    text: "Ring Device"
                    icon: "image://icon/audio-volume-high"
                    bgColor: Qt.rgba(primary.r, primary.g, primary.b, 0.15)
                    fgColor: primary
                    onClicked: service.ringDevice()
                }
                ActionButton {
                    text: "Send Clipboard"
                    icon: "image://icon/edit-paste"
                    onClicked: service.sendClipboard()
                }
                ActionButton {
                    text: "Send Text"
                    icon: "image://icon/dialog-messages"
                    onClicked: service.sendText("Ping from Quickshell!")
                }
                ActionButton {
                    text: "Send File"
                    icon: "image://icon/document-send"
                    onClicked: service.sendFile()
                }
            }
        }
    }
}