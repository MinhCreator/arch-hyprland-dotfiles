import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: dashboard
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; right: true }

    property bool showDashboard: false



    margins {
        top: 54
        bottom: 12
        right: showDashboard ? 12 : -600
    }
    implicitWidth: 380
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: dashboard.focusState
    
    onVisibleChanged: if (visible && showDashboard) focusItem.forceActiveFocus()

    Shortcut {
        sequence: "Escape"
        enabled: showDashboard
        onActivated: root.closeAllPopups()
        context: Qt.ApplicationShortcut
    }

    Behavior on margins.right { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    ListModel { id: persistentModel }

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        inlineReplySupported: true

        onNotification: (notif) => {
            console.log("NOTIFICATION RECEIVED:", JSON.stringify(notif))
            if (dashboard.doNotDisturb) return;
            
            popupModel.append({
                nSummary: notif.appName + (notif.summary ? ": " + notif.summary : ""),
                nBody:    notif.body || "",
                nImage:   notif.image || notif.appIcon || notif.appName || "",
                notification: notif
            })

            persistentModel.append({
                notifId: notif.id,
                appName: notif.appName,
                summary: notif.summary,
                body: notif.body,
                image: notif.image || notif.appIcon || notif.appName || "",
                notification: notif
            })
        }
    }

    Component.onCompleted: {
        if (notifServer.notifications) {
            var existing = notifServer.notifications.values
            for (var i = 0; i < existing.length; i++) {
                persistentModel.append({
                    notifId: existing[i].id,
                    appName: existing[i].appName,
                    summary: existing[i].summary,
                    body: existing[i].body,
                    image: existing[i].image || existing[i].appIcon || existing[i].appName || "",
                    notification: existing[i]
                })
            }
        }
        ppFindProc.running = true
        volProc.running = true
        brightProc.running = true
        updateTime()
    }

    property color bg:      root.zyuTheme.bar_bg
    property color fg:      root.zyuTheme.bar_fg
    property color accent:  root.zyuTheme.accent
    property color col1:    root.zyuTheme.col1
    property color col2:    root.zyuTheme.col2
    property color col3:    root.zyuTheme.col3
    property color muted:   root.zyuTheme.muted
    property color surface: root.zyuTheme.widget_bg

    property bool doNotDisturb: false

    readonly property string fontFam:    "Google Sans, Sans-Serif"
    readonly property string iconFont:   "JetBrainsMono Nerd Font"
    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell"
    readonly property string ppDir:      configPath + "/assets/pp/"

    property int volVal:    50
    property bool volMuted: false
    property int brightVal: 100
    property string clockTime: "00:00"
    property string clockAmpm: "AM"
    property string clockDate: "Loading..."

    property var ppFiles:    []
    property bool ppPickerOpen: false
    property string ppActualPath: ""

    function getCapitalizedUser() {
        var user = Quickshell.env("USER")
        if (!user) return "Priyam"
        var cap = user.charAt(0).toUpperCase() + user.slice(1)
        return cap
    }

    function updateTime() {
        var d = new Date()
        var hh = d.getHours()
        var mm = d.getMinutes()
        var ampm = hh >= 12 ? "PM" : "AM"
        hh = hh % 12
        hh = hh ? hh : 12
        var mmStr = mm < 10 ? "0" + mm : mm
        var hhStr = hh < 10 ? "0" + hh : hh
        clockTime = hhStr + ":" + mmStr
        clockAmpm = ampm
        clockDate = d.toLocaleDateString(Qt.locale(), "dddd, d MMMM yyyy")
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: updateTime()
    }



    Connections {
        target: root.dashboardState
        function onShowChanged() {
            dashboard.showDashboard = root.dashboardState.show
            if (root.dashboardState.show) {
                focusTimer.start()
            } else {
                focusTimer.stop()
                releaseTimer.stop()
                dashboard.focusState = WlrKeyboardFocus.None
            }
        }
    }

    Connections {
        target: root
        function onMusicVisibleChanged() { if (root.musicVisible) root.dashboardState.show = false }
        function onWifiVisibleChanged()  { if (root.wifiVisible)  root.dashboardState.show = false }
        function onBtVisibleChanged()    { if (root.btVisible)    root.dashboardState.show = false }
        function onBatVisibleChanged()   { if (root.batVisible)   root.dashboardState.show = false }
        function onTrayVisibleChanged()  { if (root.trayVisible)  root.dashboardState.show = false }
        function onWallpaperVisibleChanged() { if (root.wallpaperVisible) root.dashboardState.show = false }
    }

    Process {
        id: ppFindProc
        command: ["bash", "-c", "ls -t " + dashboard.ppDir + "*.jpg " + dashboard.ppDir + "*.png " + dashboard.ppDir + "*.gif 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => {
                var f = data.trim()
                if (f.length > 0) dashboard.ppActualPath = f
            }
        }
    }

    property int focusState: WlrKeyboardFocus.None

    Timer {
        id: focusTimer
        interval: 50; repeat: false
        onTriggered: {
            dashboard.focusState = WlrKeyboardFocus.Exclusive
            focusItem.forceActiveFocus()
            releaseTimer.start()
        }
    }
    Timer {
        id: releaseTimer
        interval: 100; repeat: false
        onTriggered: {
            dashboard.focusState = WlrKeyboardFocus.OnDemand
        }
    }

    Item {
        id: focusItem
        anchors.fill: parent
        focus: showDashboard
        onFocusChanged: if (focus) forceActiveFocus()

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (dashboard.ppPickerOpen) dashboard.ppPickerOpen = false
                else {
                    dashboardState.show = false
                    dashboard.showDashboard = false
                }
                event.accepted = true
            } else if (event.key === Qt.Key_M) {
                dashboard.ppPickerOpen = !dashboard.ppPickerOpen
                if (dashboard.ppPickerOpen) {
                    dashboard.ppFiles = []
                    ppListProc.tempFiles = []
                    ppListProc.running = true
                }
                event.accepted = true
            }
        }

        Rectangle {
            width: parent.width
            height: 610
            anchors.verticalCenter: parent.verticalCenter
            color: dashboard.bg
            radius: 24
            border.color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            Behavior on color { ColorAnimation { duration: 300 } }

            ColumnLayout {
                id: mainLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // ── Profile ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: dashboard.ppPickerOpen ? 220 : 80
                    color: dashboard.surface
                    radius: 16
                    border.color: Qt.rgba(255, 255, 255, 0.03)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 200 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            // Avatar
                            Item {
                                width: 56; height: 56

                                Image {
                                    id: pfpImage
                                    anchors.centerIn: parent
                                    width: 56; height: 56
                                    source: dashboard.ppActualPath !== "" ? "file://" + dashboard.ppActualPath : ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    cache: false
                                    asynchronous: true
                                    sourceSize.width: 112; sourceSize.height: 112
                                    visible: false
                                }
                                Rectangle {
                                    id: pfpMask
                                    anchors.centerIn: parent
                                    width: 56; height: 56
                                    radius: 28
                                    visible: false
                                }
                                OpacityMask {
                                    anchors.centerIn: parent
                                    width: 56; height: 56
                                    source: pfpImage
                                    maskSource: pfpMask
                                    visible: pfpImage.status === Image.Ready
                                }
                                Rectangle {
                                    anchors.fill: parent; radius: 28
                                    color: "transparent"
                                    border.width: 2; border.color: dashboard.accent
                                    z: 1
                                    Behavior on border.color { ColorAnimation { duration: 300 } }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: Quickshell.env("USER").charAt(0).toUpperCase()
                                    color: dashboard.accent
                                    font.pixelSize: 22; font.bold: true
                                    font.family: dashboard.fontFam
                                    visible: pfpImage.status !== Image.Ready
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        dashboard.ppPickerOpen = !dashboard.ppPickerOpen
                                        if (dashboard.ppPickerOpen) {
                                            dashboard.ppFiles = []
                                            ppListProc.tempFiles = []
                                            ppListProc.running = true
                                        }
                                    }
                                }
                            }

                            // User info
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: dashboard.getCapitalizedUser()
                                    color: dashboard.fg
                                    font.pixelSize: 20; font.bold: true
                                    font.family: dashboard.fontFam
                                }
                                Text {
                                    id: uptimeText
                                    text: "uptime..."
                                    color: dashboard.muted
                                    font.pixelSize: 12
                                    font.family: dashboard.fontFam
                                }
                            }
                        }

                        // PP Picker grid
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Qt.rgba(0, 0, 0, 0.2)
                            radius: 10
                            visible: dashboard.ppPickerOpen
                            clip: true

                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 6
                                contentWidth: width
                                contentHeight: ppGrid.implicitHeight
                                clip: true

                                GridLayout {
                                    id: ppGrid
                                    width: parent.width
                                    columns: 5
                                    rowSpacing: 6; columnSpacing: 6

                                    Repeater {
                                        model: dashboard.ppFiles

                                        Item {
                                            width: 44; height: 44

                                            Image {
                                                id: thumbImg
                                                anchors.centerIn: parent
                                                width: 44; height: 44
                                                source: "file://" + modelData
                                                fillMode: Image.PreserveAspectCrop
                                                smooth: false
                                                cache: true
                                                asynchronous: true
                                                sourceSize.width: 48; sourceSize.height: 48
                                                visible: false
                                            }
                                            Rectangle {
                                                id: thumbMask
                                                anchors.centerIn: parent
                                                width: 44; height: 44
                                                radius: 22
                                                visible: false
                                            }
                                            OpacityMask {
                                                anchors.centerIn: parent
                                                width: 44; height: 44
                                                source: thumbImg
                                                maskSource: thumbMask
                                                visible: thumbImg.status === Image.Ready
                                            }
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 44; height: 44
                                                radius: 22
                                                color: Qt.rgba(1,1,1,0.07)
                                                visible: thumbImg.status !== Image.Ready
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    dashboard.ppActualPath = modelData
                                                    dashboard.ppPickerOpen = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Process {
                                id: ppListProc
                                property var tempFiles: []
                                command: ["bash", "-c", "find " + dashboard.ppDir + " -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' \\) | sort"]
                                stdout: SplitParser {
                                    onRead: data => {
                                        var f = data.trim()
                                        if (f.length > 0) {
                                            ppListProc.tempFiles.push(f)
                                        }
                                    }
                                }
                                onExited: {
                                    dashboard.ppFiles = ppListProc.tempFiles
                                    ppListProc.tempFiles = []
                                }
                            }
                        }
                    }
                }

                // ── Clock Card ───────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 86
                    color: dashboard.surface
                    radius: 16
                    border.color: Qt.rgba(255, 255, 255, 0.03)
                    border.width: 1

                    ColumnLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        spacing: 4

                        RowLayout {
                            spacing: 8
                            Text {
                                text: dashboard.clockTime
                                color: dashboard.accent
                                font.family: dashboard.fontFam
                                font.pixelSize: 34
                                font.weight: Font.Bold
                            }
                            Text {
                                text: dashboard.clockAmpm
                                color: dashboard.fg
                                font.family: dashboard.fontFam
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                Layout.alignment: Qt.AlignBottom
                                Layout.bottomMargin: 6
                            }
                        }
                        Text {
                            text: dashboard.clockDate
                            color: dashboard.fg
                            font.family: dashboard.fontFam
                            font.pixelSize: 13
                            opacity: 0.8
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            openClocksProc.running = false
                            openClocksProc.running = true
                        }
                    }
                }

                // ── Volume + Brightness ───────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 96
                    color: dashboard.surface
                    radius: 16
                    border.color: Qt.rgba(255, 255, 255, 0.03)
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        // Volume slider row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                text: dashboard.volMuted ? "󰝟" : "󰕾"
                                color: dashboard.volMuted ? dashboard.muted : dashboard.accent
                                font.pixelSize: 18
                                font.family: dashboard.iconFont
                                Layout.preferredWidth: 20
                                horizontalAlignment: Text.AlignHCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        muteToggleProc.running = false
                                        muteToggleProc.running = true
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 6; radius: 3
                                color: Qt.rgba(255, 255, 255, 0.08)
                                Rectangle {
                                    id: volBar
                                    width: parent.width * dashboard.volVal / 100
                                    height: parent.height; radius: 3; color: dashboard.volMuted ? dashboard.muted : dashboard.accent
                                }
                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: dashboard.volMuted ? dashboard.muted : dashboard.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, volBar.width - 6)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        var p = Math.max(0, Math.min(100, Math.round((mouse.x / parent.width) * 100)))
                                        dashboard.volVal = p
                                        volSetProc.command = ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p/100).toFixed(2)]
                                        volSetProc.running = true
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var p = Math.max(0, Math.min(100, Math.round((mouse.x / parent.width) * 100)))
                                            dashboard.volVal = p
                                            volSetProc.command = ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p/100).toFixed(2)]
                                            volSetProc.running = true
                                        }
                                    }
                                }
                                Process { id: volSetProc }
                            }
                            Text {
                                text: dashboard.volVal + "%"
                                color: dashboard.fg
                                font.family: dashboard.fontFam
                                font.pixelSize: 12
                                Layout.preferredWidth: 32
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        // Brightness slider row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                text: "󰃠"
                                color: dashboard.accent
                                font.pixelSize: 18
                                font.family: dashboard.iconFont
                                Layout.preferredWidth: 20
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 6; radius: 3
                                color: Qt.rgba(255, 255, 255, 0.08)
                                Rectangle {
                                    id: brightBar
                                    width: parent.width * dashboard.brightVal / 100
                                    height: parent.height; radius: 3; color: dashboard.accent
                                }
                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: dashboard.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, brightBar.width - 6)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        var p = Math.max(1, Math.min(100, Math.round((mouse.x / parent.width) * 100)))
                                        dashboard.brightVal = p
                                        brightSetProc.command = ["bash", "-c", "brightnessctl set " + p + "%"]
                                        brightSetProc.running = true
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var p = Math.max(1, Math.min(100, Math.round((mouse.x / parent.width) * 100)))
                                            dashboard.brightVal = p
                                            brightSetProc.command = ["bash", "-c", "brightnessctl set " + p + "%"]
                                            brightSetProc.running = true
                                        }
                                    }
                                }
                                Process { id: brightSetProc }
                            }
                            Text {
                                text: dashboard.brightVal + "%"
                                color: dashboard.fg
                                font.family: dashboard.fontFam
                                font.pixelSize: 12
                                Layout.preferredWidth: 32
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }



                // ── Notifications Card (stretches to fill height) ──────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: dashboard.surface
                    radius: 16
                    border.color: Qt.rgba(255, 255, 255, 0.03)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 300 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        // Header row
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Notifications"
                                color: dashboard.fg
                                font.pixelSize: 13; font.bold: true
                                font.family: dashboard.fontFam
                            }
                            Item { Layout.fillWidth: true }

                            // DND button
                            Rectangle {
                                width: 24; height: 24; radius: 6
                                color: dashboard.doNotDisturb
                                    ? Qt.rgba(dashboard.col1.r, dashboard.col1.g, dashboard.col1.b, 0.25)
                                    : (dndMa.containsMouse ? Qt.rgba(255,255,255,0.08) : "transparent")
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: dashboard.doNotDisturb ? "󰂛" : "󰂚"
                                    color: dashboard.doNotDisturb ? dashboard.col1 : dashboard.muted
                                    font.pixelSize: 13
                                    font.family: dashboard.iconFont
                                }
                                MouseArea {
                                    id: dndMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dashboard.doNotDisturb = !dashboard.doNotDisturb
                                }
                                Rectangle {
                                    visible: dndMa.containsMouse
                                    anchors.right: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.rightMargin: 6
                                    width: dndTip.implicitWidth + 10
                                    height: 20; radius: 4
                                    color: "#333333"
                                    Text {
                                        id: dndTip
                                        anchors.centerIn: parent
                                        text: dashboard.doNotDisturb ? "DND On" : "Do Not Disturb"
                                        color: "#ffffff"
                                        font.pixelSize: 9
                                        font.family: dashboard.fontFam
                                    }
                                }
                            }

                            // Clear all button
                            Rectangle {
                                width: 24; height: 24; radius: 6
                                visible: persistentModel.count > 0
                                color: clearMa.containsMouse ? Qt.rgba(255,255,255,0.1) : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    color: dashboard.muted
                                    font.pixelSize: 13
                                    font.family: dashboard.iconFont
                                }
                                MouseArea {
                                    id: clearMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        for (var i = persistentModel.count - 1; i >= 0; i--) {
                                            var item = persistentModel.get(i)
                                            if (item && item.notification) {
                                                item.notification.dismiss()
                                            }
                                        }
                                        persistentModel.clear()
                                    }
                                }
                            }
                        }

                        // Warning banner when DND is active
                        Rectangle {
                            Layout.fillWidth: true
                            height: 24; radius: 6
                            visible: dashboard.doNotDisturb
                            color: Qt.rgba(dashboard.col1.r, dashboard.col1.g, dashboard.col1.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "Do not disturb mode is on"
                                color: dashboard.col1
                                font.pixelSize: 10
                                font.family: dashboard.fontFam
                            }
                        }

                        Flickable {
                            id: notifFlickable
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: persistentModel.count > 0 ? notifCol.implicitHeight : 0
                            visible: persistentModel.count > 0
                            clip: true

                            maximumFlickVelocity: 5000
                            flickDeceleration: 750

                            NumberAnimation {
                                id: scrollAnim
                                target: notifFlickable
                                property: "contentY"
                                duration: 150
                                easing.type: Easing.OutQuad
                            }

                            MouseArea {
                                anchors.fill: parent
                                propagateComposedEvents: true
                                onPressed: function(mouse) { mouse.accepted = false }
                                onReleased: function(mouse) { mouse.accepted = false }
                                onClicked: function(mouse) { mouse.accepted = false }
                                onDoubleClicked: function(mouse) { mouse.accepted = false }
                                onWheel: function(wheel) {
                                    var step = 120
                                    var maxScroll = Math.max(0, notifFlickable.contentHeight - notifFlickable.height)
                                    var newY = notifFlickable.contentY
                                    if (wheel.angleDelta.y > 0) {
                                        newY = Math.max(0, newY - step)
                                    } else {
                                        newY = Math.min(maxScroll, newY + step)
                                    }
                                    
                                    scrollAnim.stop()
                                    scrollAnim.to = newY
                                    scrollAnim.start()
                                    wheel.accepted = true
                                }
                            }

                            // Notifications list
                            Column {
                                id: notifCol
                                width: parent.width
                                spacing: 6
                                visible: persistentModel.count > 0

                                Repeater {
                                    model: persistentModel
                                    Rectangle {
                                        id: persistDelegate
                                        readonly property var notifObj: model.notification
                                        width: notifCol.width
                                        height: notifRow.implicitHeight + 12
                                        radius: 8
                                        color: Qt.rgba(255, 255, 255, 0.03)

                                        RowLayout {
                                            id: notifRow
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 8

                                            Item {
                                                width: 32; height: 32
                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 6
                                                    color: Qt.rgba(dashboard.accent.r, dashboard.accent.g, dashboard.accent.b, 0.25)
                                                    visible: !model.image
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰂚"
                                                        color: dashboard.accent
                                                        font.pixelSize: 14; font.bold: true
                                                        font.family: dashboard.iconFont
                                                    }
                                                }
                                                IconImage {
                                                    anchors.fill: parent
                                                    source: {
                                                        if (model.image === "") return "";
                                                        if (model.image.indexOf("://") !== -1) return model.image;
                                                        if (model.image.startsWith("/")) return "file://" + model.image;
                                                        return Quickshell.iconPath(model.image, true);
                                                    }
                                                    visible: !!model.image
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    text: model.summary || model.appName || "Notification"
                                                    color: dashboard.fg
                                                    font.pixelSize: 11; font.bold: true
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                    font.family: dashboard.fontFam
                                                }
                                                Text {
                                                    text: model.body || ""
                                                    color: dashboard.muted
                                                    font.pixelSize: 10
                                                    wrapMode: Text.WordWrap
                                                    Layout.fillWidth: true
                                                    visible: (model.body || "") !== ""
                                                    font.family: dashboard.fontFam
                                                    maximumLineCount: 3
                                                    elide: Text.ElideRight
                                                }
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 4
                                                    visible: notifObj && notifObj.actions && notifObj.actions.length > 0
                                                    Repeater {
                                                        model: notifObj ? notifObj.actions : []
                                                        Rectangle {
                                                            Layout.preferredHeight: 20
                                                            Layout.fillWidth: true
                                                            color: actionMa.containsMouse ? Qt.rgba(255,255,255,0.1) : Qt.rgba(255,255,255,0.05)
                                                            radius: 4
                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: modelData.text
                                                                color: dashboard.fg
                                                                font.pixelSize: 10
                                                                font.family: dashboard.fontFam
                                                            }
                                                            MouseArea {
                                                                id: actionMa
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                onClicked: {
                                                                    modelData.invoke()
                                                                    notifObj.dismiss()
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    visible: notifObj && notifObj.hasInlineReply
                                                    TextField {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 24
                                                        placeholderText: notifObj ? (notifObj.inlineReplyPlaceholder || "Reply...") : ""
                                                        color: dashboard.fg
                                                        background: Rectangle { color: Qt.rgba(255,255,255,0.05); radius: 4 }
                                                        font.pixelSize: 10
                                                        font.family: dashboard.fontFam
                                                        onAccepted: {
                                                            if (text !== "") {
                                                                    notifObj.sendInlineReply(text)
                                                                    text = ""
                                                                    notifObj.dismiss()
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                width: 18; height: 18; radius: 4
                                                color: closeMa.containsMouse ? Qt.rgba(255,255,255,0.1) : "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "✕"
                                                    color: dashboard.muted
                                                    font.pixelSize: 9
                                                    font.family: dashboard.fontFam
                                                }
                                                MouseArea {
                                                    id: closeMa
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        try {
                                                            if (model.notification) {
                                                                model.notification.dismiss()
                                                            }
                                                        } catch(e) {
                                                            console.log("Error dismissing notification: " + e)
                                                        }
                                                        persistentModel.remove(index)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Placeholder item that fills remaining vertical space when empty
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: persistentModel.count === 0

                            Column {
                                id: emptyStateCol
                                anchors.centerIn: parent
                                spacing: 12
                                width: parent.width

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "󰂛"
                                    color: dashboard.accent // Matugen accent color!
                                    font.pixelSize: 52
                                    font.family: dashboard.iconFont
                                    opacity: 0.6
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "No notifications"
                                    color: dashboard.fg // Matugen foreground color!
                                    font.pixelSize: 14
                                    font.family: dashboard.fontFam
                                    font.weight: Font.DemiBold
                                    opacity: 0.8
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Update timer ────────────────────────────────────────────────
    Timer {
        interval: 2000; running: showDashboard; repeat: true
        onTriggered: {
            if (!volProc.running)       volProc.running = true
            if (!brightProc.running)    brightProc.running = true
            if (!uptimeProc.running)    uptimeProc.running = true
        }
    }

    // ── System processes ───────────────────────────────────────────────
    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100), ($3 == \"[MUTED]\" ? \"muted\" : \"unmuted\")}'"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var parts = data.trim().split(" ")
                if (parts.length >= 2) {
                    dashboard.volVal = parseInt(parts[0]) || 0
                    dashboard.volMuted = (parts[1] === "muted")
                }
            }
        }
    }
    Process {
        id: muteToggleProc
        command: ["bash", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"]
        onExited: {
            volProc.running = false
            volProc.running = true
        }
    }
    Process {
        id: brightProc
        command: ["bash", "-c", "brightnessctl -m | awk -F, '{gsub(/%/,\"\"); print $4}'"]
        stdout: SplitParser { onRead: data => dashboard.brightVal = parseInt(data) || 100 }
    }
    Process {
        id: uptimeProc
        command: ["bash", "-c", "uptime -p | sed 's/up //'"]
        stdout: SplitParser { onRead: data => uptimeText.text = data.trim() }
    }
    Process {
        id: fetchEventsProc
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                eventsModel.clear()
                try {
                    var list = JSON.parse(data)
                    for (var i = 0; i < list.length; i++) {
                        eventsModel.append(list[i])
                    }
                } catch(e) {
                    console.log("Error parsing events: " + e)
                }
            }
        }
    }
    Process {
        id: openCalendarProc
        command: ["gnome-calendar"]
    }
    Process {
        id: openClocksProc
        command: ["gnome-clocks"]
    }

    ListModel { id: popupModel }

    PanelWindow {
        id: popupWindow
        visible: popupModel.count > 0
        exclusionMode: ExclusionMode.Ignore
        focusable: false
        color: "transparent"
        anchors { bottom: true; right: true }
        margins { bottom: 20; right: 20 }
        implicitWidth: 320
        implicitHeight: popupCol.implicitHeight + 20
        WlrLayershell.layer: WlrLayer.Overlay

        Column {
            id: popupCol
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            spacing: 8
            width: parent.width

            Repeater {
                model: popupModel
                Rectangle {
                    id: popupDelegate
                    readonly property int notifIndex: index
                    readonly property var notifObj: model.notification
                    width: 320
                    height: popRow.implicitHeight + 20
                    radius: 14
                    color: Qt.rgba(dashboard.bg.r, dashboard.bg.g, dashboard.bg.b, 0.95)
                    border.color: Qt.rgba(dashboard.accent.r, dashboard.accent.g, dashboard.accent.b, 0.25)
                    border.width: 1

                    Timer {
                        interval: 5000; running: true; repeat: false
                        onTriggered: popupModel.remove(index)
                    }

                    RowLayout {
                        id: popRow
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        anchors.leftMargin: 14; anchors.rightMargin: 10
                        spacing: 10

                        Item {
                            width: 32; height: 32
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: Qt.rgba(dashboard.accent.r, dashboard.accent.g, dashboard.accent.b, 0.25)
                                visible: model.nImage === ""
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰂚"
                                    color: dashboard.accent
                                    font.pixelSize: 16; font.bold: true
                                    font.family: dashboard.iconFont
                                }
                            }
                            IconImage {
                                anchors.fill: parent
                                source: {
                                    if (model.nImage === "") return "";
                                    if (model.nImage.indexOf("://") !== -1) return model.nImage;
                                    if (model.nImage.startsWith("/")) return "file://" + model.nImage;
                                    return Quickshell.iconPath(model.nImage, true);
                                }
                                visible: model.nImage !== ""
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: model.nSummary
                                color: dashboard.fg
                                font.pixelSize: 11; font.bold: true
                                font.family: dashboard.fontFam
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: model.nBody !== ""
                                text: model.nBody
                                color: dashboard.muted
                                font.pixelSize: 10
                                font.family: dashboard.fontFam
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                visible: notifObj && notifObj.actions && notifObj.actions.length > 0
                                Repeater {
                                    model: notifObj ? notifObj.actions : []
                                    Rectangle {
                                        Layout.preferredHeight: 24
                                        Layout.fillWidth: true
                                        color: popActionMa.containsMouse ? Qt.rgba(255,255,255,0.1) : Qt.rgba(255,255,255,0.05)
                                        radius: 6
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.text
                                            color: dashboard.fg
                                            font.pixelSize: 10
                                            font.family: dashboard.fontFam
                                        }
                                        MouseArea {
                                            id: popActionMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                modelData.invoke()
                                                notifObj.dismiss()
                                                popupModel.remove(notifIndex)
                                            }
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                visible: notifObj && notifObj.hasInlineReply
                                TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    placeholderText: notifObj ? (notifObj.inlineReplyPlaceholder || "Reply...") : ""
                                    color: dashboard.fg
                                    background: Rectangle { color: Qt.rgba(255,255,255,0.05); radius: 6 }
                                    font.pixelSize: 10
                                    font.family: dashboard.fontFam
                                    onAccepted: {
                                        if (text !== "") {
                                            notifObj.sendInlineReply(text)
                                            text = ""
                                            notifObj.dismiss()
                                            popupModel.remove(notifIndex)
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 18; height: 18; radius: 4
                            color: popCloseMa.containsMouse ? Qt.rgba(255,255,255,0.1) : "transparent"
                            Text { anchors.centerIn: parent; text: "✕"; color: dashboard.muted; font.pixelSize: 9; font.family: dashboard.fontFam }
                            MouseArea {
                                id: popCloseMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popupModel.remove(notifIndex)
                            }
                        }
                    }
                }
            }
        }
    }
}
