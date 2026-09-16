import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: trayDrawer
    visible: true
    exclusionMode: ExclusionMode.Ignore
    
    property var activeMenu: null
    property int clickX: 10

    // --- Custom Menu Popup ---
    PanelWindow {
        id: customMenuPopup
        visible: trayDrawer.activeMenu !== null && root.trayVisible
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        focusable: true
        
        onVisibleChanged: {
            if (visible) {
                menuFocusTimer.start()
            } else {
                menuFocusTimer.stop()
            }
        }

        Timer {
            id: menuFocusTimer
            interval: 50
            repeat: false
            onTriggered: menuContainer.forceActiveFocus()
        }

        anchors { top: true; right: true }
        margins { 
            top: 104 
            right: trayDrawer.margins.right + trayDrawer.clickX 
        }
        
        implicitWidth: 200
        implicitHeight: Math.min(600, menuColumn.implicitHeight + 16)

        // Close menu when clicking outside
        MouseArea {
            anchors.fill: parent
            z: -1 // Behind the menu content
            hoverEnabled: true
            onEntered: menuContainer.forceActiveFocus()
            onClicked: trayDrawer.activeMenu = null
        }

        Shortcut {
            sequence: "Escape"
            enabled: customMenuPopup.visible
            onActivated: trayDrawer.activeMenu = null
            context: Qt.ApplicationShortcut
        }

        QsMenuOpener {
            id: menuOpener
            menu: trayDrawer.activeMenu
        }

        Rectangle {
            id: menuContainer
            anchors.fill: parent
            color: Qt.rgba(zyuTheme.bar_bg.r, zyuTheme.bar_bg.g, zyuTheme.bar_bg.b, 0.98)
            radius: zyuTheme.rounding
            border.color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.3)
            border.width: 1
            focus: true
            
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    trayDrawer.activeMenu = null
                    event.accepted = true
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: menuContainer.forceActiveFocus()
                onPositionChanged: {
                    if (!menuContainer.activeFocus) {
                        menuContainer.forceActiveFocus()
                    }
                }
                onPressed: (mouse) => { mouse.accepted = false }
                onReleased: (mouse) => { mouse.accepted = false }
                onClicked: (mouse) => { mouse.accepted = false }
            }

            Column {
                id: menuColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 2

                Repeater {
                    model: menuOpener.children
                    delegate: Rectangle {
                        width: parent.width
                        height: modelData.text === "" ? 10 : 26
                        radius: 4
                        color: (menuMa.containsMouse && modelData.text !== "") ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.15) : "transparent"
                        
                        // Separator line
                        Rectangle {
                            visible: modelData.text === ""
                            anchors.centerIn: parent
                            width: parent.width - 20
                            height: 1
                            color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.1)
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 8
                            visible: modelData.text !== ""
                            
                            Image {
                                width: 14; height: 14
                                anchors.verticalCenter: parent.verticalCenter
                                source: modelData.icon
                                visible: modelData.icon !== ""
                            }

                            Text {
                                Layout.fillWidth: true
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.text.replace(/&/g, "")
                                color: !modelData.enabled ? Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.4) 
                                       : (menuMa.containsMouse ? zyuTheme.accent : zyuTheme.bar_fg)
                                font.family: zyuTheme.mainFont.family
                                font.bold: zyuTheme.mainFont.bold
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            id: menuMa
                            anchors.fill: parent
                            hoverEnabled: modelData.text !== ""
                            enabled: modelData.text !== "" && modelData.enabled
                            onClicked: {
                                modelData.triggered()
                                trayDrawer.activeMenu = null
                            }
                        }
                    }
                }
            }
        }
        
        // Close menu if tray is hidden
        Connections {
            target: root
            function onTrayVisibleChanged() { if (!root.trayVisible) trayDrawer.activeMenu = null }
        }
    }

    anchors { top: true; right: true }
    margins {
        top: root.trayVisible ? 54 : -400
        right: root.trayButtonRightOffset - (trayDrawer.implicitWidth / 2)
    }
    
    implicitHeight: 44
    implicitWidth: Math.min(400, Math.max(60, trayItemsView.contentWidth + 20))
    color: "transparent"
    focusable: true
    
    Behavior on margins.top { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    
    WlrLayershell.layer: WlrLayer.Top 
    WlrLayershell.keyboardFocus: root.trayVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    onVisibleChanged: if (visible && root.trayVisible) forceActiveFocus()

    Shortcut {
        sequence: "Escape"
        enabled: root.trayVisible || trayDrawer.activeMenu !== null
        onActivated: root.closeAllPopups()
        context: Qt.ApplicationShortcut
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(zyuTheme.bar_bg.r, zyuTheme.bar_bg.g, zyuTheme.bar_bg.b, 0.95) 
        radius: 12
        border.color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.1)
        border.width: 1

        // Fallback icon so the drawer is NEVER completely empty
        Text {
            anchors.centerIn: parent
            visible: trayItemsView.count === 0
            text: "󰅙" 
            color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.3)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
        }

        ListView {
            id: trayItemsView
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6
            orientation: ListView.Horizontal
            layoutDirection: Qt.RightToLeft
            model: SystemTray.items
            
            delegate: Rectangle {
                id: trayItemDelegate
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter
                radius: 8
                color: trayMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Image {
                    anchors.centerIn: parent
                    width: 20; height: 20
                    source: modelData.icon
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: trayMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate(mouse.x, mouse.y)
                            root.trayVisible = false
                            trayDrawer.activeMenu = null
                        } else if (mouse.button === Qt.RightButton) {
                            trayDrawer.clickX = 10 + (index * 38)
                            trayDrawer.activeMenu = modelData.menu
                        } else if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate(mouse.x, mouse.y)
                            root.trayVisible = false
                            trayDrawer.activeMenu = null
                        }
                    }
                }
            }
        }
    }
}
