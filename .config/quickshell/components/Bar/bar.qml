import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: barWindow
        property var modelData

        anchors { top: true; left: true; right: true }
        margins {
            top: 8
            left: 8
            right: 8
        }
        implicitHeight: 38
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top

        visible: {
            if (root.focusMode) return false;
            const activeWs = Hyprland.focusedMonitor?.activeWorkspace
            return activeWs ? activeWs.id > 0 : true
        }

        readonly property bool hasMusic: {
            var players = Mpris.players.values
            if (!players || players.length === 0) return false
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === MprisPlaybackState.Playing ||
                    players[i].playbackState === MprisPlaybackState.Paused) return true
            }
            return false
        }

        readonly property bool isPlaying: {
            var players = Mpris.players.values
            if (!players || players.length === 0) return false
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === MprisPlaybackState.Playing) return true
            }
            return false
        }

        readonly property var activePlayer: {
            var players = Mpris.players.values
            if (!players || players.length === 0) return null
            if (root.selectedPlayerBus !== "") {
                for (var i = 0; i < players.length; i++) {
                    if (players[i].dbusName === root.selectedPlayerBus) return players[i]
                }
            }
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
            }
            return players.length > 0 ? players[0] : null
        }

        property var animPlayer: null
        property string animTitle: ""
        property string animArtist: ""
        property bool scrollCooldown: false

        Timer {
            id: taskbarScrollTimer
            interval: 350
            repeat: false
            onTriggered: barWindow.scrollCooldown = false
        }

        Connections {
            target: barWindow.activePlayer
            ignoreUnknownSignals: true
            function onTrackTitleChanged() {
                barWindow.animTitle = barWindow.activePlayer ? (barWindow.activePlayer.trackTitle || "") : ""
            }
            function onTrackArtistChanged() {
                barWindow.animArtist = barWindow.activePlayer ? (barWindow.activePlayer.trackArtist || "") : ""
            }
        }
        
        Process {
            id: writePlayerProc
        }

        onActivePlayerChanged: {
            barSwitchAnimation.start()
            if (activePlayer) {
                writePlayerProc.running = false
                var shortName = activePlayer.dbusName.replace("org.mpris.MediaPlayer2.", "")
                writePlayerProc.command = ["bash", "-c", "echo '" + shortName + "' > /tmp/current_mpris_player"]
                writePlayerProc.running = true
            } else {
                writePlayerProc.running = false
                writePlayerProc.command = ["bash", "-c", "echo '' > /tmp/current_mpris_player"]
                writePlayerProc.running = true
            }
        }
        
        SequentialAnimation {
            id: barSwitchAnimation
            NumberAnimation { target: mediaWidget; property: "opacity"; to: 0.0; duration: 150 }
            ScriptAction {
                script: {
                    barWindow.animPlayer = barWindow.activePlayer
                    barWindow.animTitle = barWindow.activePlayer ? (barWindow.activePlayer.trackTitle || "") : ""
                    barWindow.animArtist = barWindow.activePlayer ? (barWindow.activePlayer.trackArtist || "") : ""
                }
            }
            NumberAnimation { target: mediaWidget; property: "opacity"; to: 1.0; duration: 200 }
        }

        Component.onCompleted: {
            barWindow.animPlayer = barWindow.activePlayer
            barWindow.animTitle = barWindow.activePlayer ? (barWindow.activePlayer.trackTitle || "") : ""
            barWindow.animArtist = barWindow.activePlayer ? (barWindow.activePlayer.trackArtist || "") : ""
            if (activePlayer) {
                writePlayerProc.running = false
                var shortName = activePlayer.dbusName.replace("org.mpris.MediaPlayer2.", "")
                writePlayerProc.command = ["bash", "-c", "echo '" + shortName + "' > /tmp/current_mpris_player"]
                writePlayerProc.running = true
            }
        }

        Connections {
            target: barWindow
            function onWidthChanged() {
                if (typeof trayButton !== 'undefined') trayButton.updateOffset()
                if (typeof kdeConnectButton !== 'undefined') kdeConnectButton.updateOffset()
                if (typeof batteryButton !== 'undefined') batteryButton.updateOffset()
                if (typeof bluetoothButton !== 'undefined') bluetoothButton.updateOffset()
                if (typeof wifiButton !== 'undefined') wifiButton.updateOffset()
                if (typeof githubButton !== 'undefined') githubButton.updateOffset()
                if (typeof dashboardButton !== 'undefined') dashboardButton.updateOffset()
            }
        }

        Item {
            id: barRect
            anchors.fill: parent

            // ── SECTION 1: Left Widget (Clock + Workspaces Capsule) ──
            Rectangle {
                id: leftWidget
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                height: 30
                width: leftLayout.implicitWidth + 24
                color: zyuTheme.bar_bg
                radius: zyuTheme.rounding
                border.color: Qt.rgba(1,1,1,0.04)
                border.width: 1

                Row {
                    id: leftLayout
                    anchors.centerIn: parent
                    spacing: 16

                    // Clock HH:MM
                    Row {
                        spacing: 3
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            id: hourText
                            color: zyuTheme.bar_fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13; font.bold: true
                            function updateTime() { text = new Date().getHours().toString().padStart(2, '0') }
                            Component.onCompleted: updateTime()
                        }
                        Text {
                            text: ":"
                            color: zyuTheme.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13; font.bold: true
                            opacity: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: minText
                            color: zyuTheme.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13; font.bold: true
                            function updateTime() { text = new Date().getMinutes().toString().padStart(2, '0') }
                            Component.onCompleted: updateTime()
                        }
                        Timer {
                            interval: 1000; running: true; repeat: true
                            onTriggered: { hourText.updateTime(); minText.updateTime() }
                        }
                    }

                    // Workspaces
                    Row {
                        id: wsRow
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        property int activeWorkspaceId: Hyprland.focusedMonitor?.activeWorkspace?.id || 1
                        property int lastActiveWorkspaceId: 1
                        property string moveDirection: "right"

                        onActiveWorkspaceIdChanged: {
                            if (activeWorkspaceId > 0 && lastActiveWorkspaceId > 0 && activeWorkspaceId !== lastActiveWorkspaceId) {
                                if (activeWorkspaceId > lastActiveWorkspaceId) {
                                    moveDirection = "right";
                                } else {
                                    moveDirection = "left";
                                }
                                lastActiveWorkspaceId = activeWorkspaceId;
                            }
                        }

                        Repeater {
                            model: Hyprland.workspaces
                            delegate: Item {
                                id: wsDelegate
                                width: 22; height: 22
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.id > 0
                                property int canvasSize: 18
                                property int textSize: 9
                                property bool isActive: modelData.id === Hyprland.focusedMonitor?.activeWorkspace?.id

                                // Pac-Man (Active Workspace)
                                Canvas {
                                    id: pacmanCanvas
                                    anchors.centerIn: parent
                                    width: wsDelegate.canvasSize; height: wsDelegate.canvasSize
                                    property real mouthAngle: 15
                                    property string dir: wsRow.moveDirection
                                    property color themeAccent: zyuTheme.accent
                                    property color themeBg: zyuTheme.bar_bg
                                    
                                    opacity: wsDelegate.isActive ? 1.0 : 0.0
                                    scale: wsDelegate.isActive ? 1.0 : 0.5
                                    visible: opacity > 0.0
                                    
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                    property bool activeState: wsDelegate.isActive
                                    onActiveStateChanged: {
                                        if (activeState) {
                                            chompAnim.restart();
                                        } else {
                                            chompAnim.stop();
                                            mouthAngle = 15;
                                        }
                                    }

                                    onDirChanged: requestPaint()
                                    onThemeAccentChanged: requestPaint()
                                    onThemeBgChanged: requestPaint()

                                    Component.onCompleted: {
                                        if (activeState) {
                                            chompAnim.start();
                                        }
                                    }

                                    SequentialAnimation {
                                        id: chompAnim
                                        NumberAnimation { target: pacmanCanvas; property: "mouthAngle"; from: 15; to: 50; duration: 120; easing.type: Easing.InOutQuad }
                                        NumberAnimation { target: pacmanCanvas; property: "mouthAngle"; from: 50; to: 15; duration: 120; easing.type: Easing.InOutQuad }
                                        NumberAnimation { target: pacmanCanvas; property: "mouthAngle"; from: 15; to: 50; duration: 120; easing.type: Easing.InOutQuad }
                                        NumberAnimation { target: pacmanCanvas; property: "mouthAngle"; from: 50; to: 15; duration: 120; easing.type: Easing.InOutQuad }
                                    }

                                    onMouthAngleChanged: requestPaint()

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        var cx = width / 2;
                                        var cy = height / 2;
                                        var r = Math.min(width, height) / 2 - 0.5;

                                        ctx.save();
                                        ctx.translate(cx, cy);
                                        
                                        var angle = (dir === "right") ? 0 : Math.PI;
                                        ctx.rotate(angle);

                                        ctx.fillStyle = themeAccent;
                                        ctx.beginPath();
                                        ctx.moveTo(0, 0);

                                        var startAngle = (mouthAngle / 2) * Math.PI / 180;
                                        var endAngle = (360 - mouthAngle / 2) * Math.PI / 180;

                                        ctx.arc(0, 0, r, startAngle, endAngle);
                                        ctx.closePath();
                                        ctx.fill();

                                        ctx.restore();
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.id
                                        color: pacmanCanvas.themeBg
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: wsDelegate.textSize
                                        font.bold: true
                                        renderType: Text.NativeRendering
                                    }
                                }

                                // Ghost (Inactive Workspace)
                                Canvas {
                                    id: ghostCanvas
                                    anchors.centerIn: parent
                                    width: wsDelegate.canvasSize; height: wsDelegate.canvasSize
                                    property bool isHovered: wsMouseArea.containsMouse
                                    property color themeAccent: zyuTheme.accent
                                    property color themeFg: zyuTheme.bar_fg
                                    property color themeBg: zyuTheme.bar_bg
                                    
                                    opacity: wsDelegate.isActive ? 0.0 : 1.0
                                    scale: wsDelegate.isActive ? 0.5 : 1.0
                                    visible: opacity > 0.0
                                    
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                    onIsHoveredChanged: {
                                        requestPaint();
                                        if (!isHovered) {
                                            ghostCanvas.rotation = 0;
                                        }
                                    }

                                    onThemeAccentChanged: requestPaint()
                                    onThemeFgChanged: requestPaint()
                                    onThemeBgChanged: requestPaint()

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        var w = width;
                                        var h = height;
                                        var cx = w / 2;
                                        var r = w / 2;
                                        var th = h * 0.16;
                                        var s = w / 6;

                                        var bodyColor = isHovered 
                                            ? themeAccent 
                                            : Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.35);

                                        ctx.fillStyle = bodyColor;
                                        ctx.beginPath();
                                        ctx.moveTo(0, r);
                                        ctx.arc(cx, r, r, Math.PI, 0, false);
                                        ctx.lineTo(w, h);

                                        ctx.lineTo(w - s, h - th);
                                        ctx.lineTo(w - 2 * s, h);
                                        ctx.lineTo(w - 3 * s, h - th);
                                        ctx.lineTo(w - 4 * s, h);
                                        ctx.lineTo(w - 5 * s, h - th);
                                        ctx.lineTo(0, h);
                                        ctx.closePath();
                                        ctx.fill();

                                        var eyeY = r - h * 0.04;

                                        if (isHovered) {
                                            ctx.fillStyle = themeBg;
                                            ctx.fillRect(w * 0.25, eyeY - w * 0.06, w * 0.12, w * 0.12);
                                            ctx.fillRect(w * 0.63, eyeY - w * 0.06, w * 0.12, w * 0.12);

                                            ctx.strokeStyle = themeBg;
                                            ctx.lineWidth = w * 0.06;
                                            ctx.beginPath();
                                            ctx.moveTo(w * 0.25, r + h * 0.16);
                                            ctx.lineTo(w * 0.375, r + h * 0.08);
                                            ctx.lineTo(w * 0.5, r + h * 0.16);
                                            ctx.lineTo(w * 0.625, r + h * 0.08);
                                            ctx.lineTo(w * 0.75, r + h * 0.16);
                                            ctx.stroke();
                                        }
                                    }

                                    rotation: 0

                                    SequentialAnimation {
                                        id: wiggleAnim
                                        running: ghostCanvas.isHovered
                                        loops: Animation.Infinite

                                        NumberAnimation { target: ghostCanvas; property: "rotation"; from: 0; to: 8; duration: 60; easing.type: Easing.Linear }
                                        NumberAnimation { target: ghostCanvas; property: "rotation"; from: 8; to: -8; duration: 120; easing.type: Easing.Linear }
                                        NumberAnimation { target: ghostCanvas; property: "rotation"; from: -8; to: 0; duration: 60; easing.type: Easing.Linear }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: -1
                                        text: modelData.id
                                        color: ghostCanvas.isHovered ? ghostCanvas.themeBg : ghostCanvas.themeFg
                                        visible: !ghostCanvas.isHovered
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: wsDelegate.textSize
                                        font.bold: true
                                        renderType: Text.NativeRendering
                                    }
                                }

                                MouseArea {
                                    id: wsMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // ── SECTION 2: Center Widget (Media / Music Capsule) ──
            Rectangle {
                id: mediaWidget
                anchors.centerIn: parent
                height: 30
                visible: barWindow.hasMusic
                width: mediaLayout.implicitWidth + 16
                radius: 8
                color: Qt.rgba(
                    zyuTheme.bar_bg.r * 0.82 + zyuTheme.accent.r * 0.18,
                    zyuTheme.bar_bg.g * 0.82 + zyuTheme.accent.g * 0.18,
                    zyuTheme.bar_bg.b * 0.82 + zyuTheme.accent.b * 0.18,
                    0.90
                )
                border.color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.35)
                border.width: 1
                clip: true

                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    id: musicMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            if (barWindow.animPlayer && barWindow.animPlayer.canTogglePlaying) barWindow.animPlayer.togglePlaying();
                        } else {
                            root.togglePanel("music");
                        }
                    }
                    onWheel: function(wheel) {
                        if (barWindow.scrollCooldown) return;
                        if (barWindow.animPlayer) {
                            var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                            if (delta > 0) {
                                barWindow.scrollCooldown = true;
                                taskbarScrollTimer.start();
                                if (barWindow.animPlayer.canGoPrevious) barWindow.animPlayer.previous();
                            } else if (delta < 0) {
                                barWindow.scrollCooldown = true;
                                taskbarScrollTimer.start();
                                if (barWindow.animPlayer.canGoNext) barWindow.animPlayer.next();
                            }
                        }
                    }
                }

                RowLayout {
                    id: mediaLayout
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // Artwork
                    Rectangle {
                        width: 20; height: 20; radius: 4
                        color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.1)
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: 20; height: 20; radius: 4
                            }
                        }
                        Image {
                            anchors.fill: parent
                            source: barWindow.activePlayer ? (barWindow.activePlayer.trackArtUrl || "") : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                        }
                    }

                    // Details (Title / Artist)
                    Column {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0
                        Item {
                            id: titleContainer
                            width: Math.min(titleText.implicitWidth, 120)
                            height: 12
                            clip: true
                            Text {
                                id: titleText
                                text: barWindow.animTitle
                                color: root.musicVisible ? zyuTheme.accent : zyuTheme.bar_fg
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10; font.bold: true
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            SequentialAnimation {
                                running: musicMa.containsMouse && titleText.implicitWidth > titleContainer.width
                                loops: Animation.Infinite
                                PauseAnimation { duration: 2000 }
                                NumberAnimation {
                                    target: titleText
                                    property: "x"
                                    to: titleContainer.width - titleText.implicitWidth
                                    duration: Math.max(1000, (titleText.implicitWidth - titleContainer.width) * 40)
                                    easing.type: Easing.Linear
                                }
                                PauseAnimation { duration: 2000 }
                                PropertyAction { target: titleText; property: "x"; value: 0 }
                                onStopped: titleText.x = 0
                            }
                        }
                        Item {
                            id: artistContainer
                            width: Math.min(artistText.implicitWidth, 120)
                            height: 10
                            clip: true
                            visible: barWindow.animArtist !== ""
                            Text {
                                id: artistText
                                text: barWindow.animArtist
                                color: zyuTheme.bar_fg
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 8
                                opacity: 0.5
                            }
                            SequentialAnimation {
                                running: musicMa.containsMouse && artistText.implicitWidth > artistContainer.width
                                loops: Animation.Infinite
                                PauseAnimation { duration: 2000 }
                                NumberAnimation {
                                    target: artistText
                                    property: "x"
                                    to: artistContainer.width - artistText.implicitWidth
                                    duration: Math.max(1000, (artistText.implicitWidth - artistContainer.width) * 40)
                                    easing.type: Easing.Linear
                                }
                                PauseAnimation { duration: 2000 }
                                PropertyAction { target: artistText; property: "x"; value: 0 }
                                onStopped: artistText.x = 0
                            }
                        }
                    }

                    // Prev Button
                    Rectangle {
                        width: 18; height: 18; radius: 4
                        color: prevMa.containsMouse ? Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.08) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            color: zyuTheme.bar_fg
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                        }
                        MouseArea {
                            id: prevMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (barWindow.activePlayer && barWindow.activePlayer.canGoPrevious) barWindow.activePlayer.previous()
                        }
                    }

                    // Play/Pause Button
                    Rectangle {
                        width: 20; height: 20; radius: 10
                        color: zyuTheme.accent
                        Text {
                            anchors.centerIn: parent
                            text: barWindow.isPlaying ? "󰏤" : "󰐊"
                            color: zyuTheme.bar_bg
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (barWindow.activePlayer && barWindow.activePlayer.canTogglePlaying) barWindow.activePlayer.togglePlaying()
                        }
                    }

                    // Next Button
                    Rectangle {
                        width: 18; height: 18; radius: 4
                        color: nextMa.containsMouse ? Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.08) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            color: zyuTheme.bar_fg
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                        }
                        MouseArea {
                            id: nextMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (barWindow.activePlayer && barWindow.activePlayer.canGoNext) barWindow.activePlayer.next()
                        }
                    }
                }
            }

            // ── SECTION 3: Right Widget (System Utilities Capsule) ──
            Rectangle {
                id: rightWidget
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                height: 30
                width: rightLayout.implicitWidth + 24
                color: zyuTheme.bar_bg
                radius: zyuTheme.rounding
                border.color: Qt.rgba(1,1,1,0.04)
                border.width: 1

                Row {
                    id: rightLayout
                    anchors.centerIn: parent
                    spacing: 4

                    // System Tray Drawer Button
                    Item {
                        id: trayButton
                        width: 32; height: 32
                        
                        onXChanged: updateOffset()
                        onWidthChanged: updateOffset()
                        Component.onCompleted: updateOffset()
                        
                        Connections {
                            target: barWindow
                            function onWidthChanged() { trayButton.updateOffset() }
                        }
                        
                        function updateOffset() {
                            var pt = trayButton.mapToItem(null, 0, 0)
                            root.trayButtonRightOffset = barWindow.width - pt.x - (trayButton.width / 2) + 8
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: trayMa.containsMouse || root.trayVisible ? 28 : 0
                            height: width; radius: 6
                            color: root.trayVisible
                                ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.18)
                                : Qt.rgba(1,1,1,0.07)
                            Behavior on width  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color  { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: root.trayVisible ? "" : ""
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: root.trayVisible
                                ? zyuTheme.accent
                                : Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b,
                                          trayMa.containsMouse ? 0.8 : 0.4)
                        }
                        MouseArea {
                            id: trayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePanel("tray")
                        }
                    }

                    // KDE Connect Button
                    Item {
                        id: kdeConnectButton
                        width: 32; height: 32
                        visible: root.kdeConnectService ? root.kdeConnectService.isConnected : false
                        onXChanged: updateOffset()
                        onWidthChanged: updateOffset()
                        Component.onCompleted: updateOffset()
                        function updateOffset() {
                            var pt = mapToItem(null, 0, 0)
                            root.kdeConnectButtonRightOffset = barWindow.width - pt.x - (width / 2) + 8
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: kdeMa.containsMouse || root.kdeConnectVisible ? 28 : 0
                            height: width; radius: 6
                            color: root.kdeConnectVisible
                                ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.18)
                                : Qt.rgba(1,1,1,0.07)
                            Behavior on width  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "󰏲"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                            color: root.kdeConnectVisible
                                ? zyuTheme.accent
                                : Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, kdeMa.containsMouse ? 0.8 : 0.4)
                        }
                        Rectangle {
                            visible: root.kdeConnectService ? root.kdeConnectService.unreadCount > 0 : false
                            width: 12; height: 12; radius: 6
                            color: zyuTheme.accent
                            anchors.top: parent.top; anchors.right: parent.right
                            anchors.topMargin: 0; anchors.rightMargin: 0
                            Text {
                                anchors.centerIn: parent
                                text: root.kdeConnectService ? root.kdeConnectService.unreadCount : ""
                                color: zyuTheme.bar_bg
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                        MouseArea {
                            id: kdeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePanel("kdeconnect")
                        }
                    }

                    // Battery Button
                    Item {
                        id: batteryButton
                        width: 36; height: 32
                        onXChanged: updateOffset()
                        onWidthChanged: updateOffset()
                        Component.onCompleted: updateOffset()
                        function updateOffset() {
                            var pt = mapToItem(null, 0, 0)
                            root.batteryButtonRightOffset = barWindow.width - pt.x - (width / 2) + 8
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: batBarMa.containsMouse || root.batVisible ? 32 : 0
                            height: 28; radius: 6
                            color: root.batVisible ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.18) : Qt.rgba(1,1,1,0.07)
                            Behavior on width  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                        readonly property color batColor: {
                            if (root.batteryService && root.batteryService.charging) return "#a6e3a1";
                            if (root.batteryService && root.batteryService.capacity <= 20) return "#f38ba8";
                            if (root.batteryService && root.batteryService.powerProfile === "performance") return "#a6e3a1";
                            if (root.batteryService && root.batteryService.powerProfile === "balanced") return "#f9e2af";
                            return zyuTheme.bar_fg;
                        }
                        readonly property string batIcon: {
                            if (root.batteryService && root.batteryService.charging) return "\uf140b";
                            if (root.batteryService && root.batteryService.capacity <= 20) return "\ueb2d";
                            return "";
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.batIcon
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: parent.parent.batColor
                                visible: text !== ""
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (root.batteryService ? root.batteryService.capacity : "--") + "%"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                font.bold: true
                                color: parent.parent.batColor
                            }
                        }
                        MouseArea {
                            id: batBarMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePanel("bat")
                        }
                    }

                    // Bluetooth Button
                    Item {
                        id: bluetoothButton
                        width: 32; height: 32
                        onXChanged: updateOffset()
                        onWidthChanged: updateOffset()
                        Component.onCompleted: updateOffset()
                        function updateOffset() {
                            var pt = mapToItem(null, 0, 0)
                            root.bluetoothButtonRightOffset = barWindow.width - pt.x - (width / 2) + 8
                        }
                        readonly property bool isConnected: root.btPanel && root.btPanel.connectedDevice !== ""
                        Rectangle {
                            anchors.centerIn: parent
                            width: btMa.containsMouse || root.btVisible ? 28 : 0
                            height: width; radius: 6
                            color: root.btVisible
                                ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.18)
                                : Qt.rgba(1,1,1,0.07)
                            Behavior on width  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.isConnected ? root.btPanel.connectedIcon : "󰂯"
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                                color: root.btVisible || parent.parent.isConnected
                                    ? zyuTheme.accent
                                    : Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, btMa.containsMouse ? 0.8 : 0.4)
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: parent.parent.isConnected && root.btPanel.connectedBattery !== -1
                                text: parent.parent.isConnected ? root.btPanel.connectedBattery + "%" : ""
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7
                                color: zyuTheme.accent
                                opacity: 0.8
                            }
                        }
                        MouseArea {
                            id: btMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePanel("bt")
                        }
                    }

                    // Wi-Fi Button
                    Item {
                        id: wifiButton
                        width: 32; height: 32
                        onXChanged: updateOffset()
                        onWidthChanged: updateOffset()
                        Component.onCompleted: updateOffset()
                        function updateOffset() {
                            var pt = mapToItem(null, 0, 0)
                            root.wifiButtonRightOffset = barWindow.width - pt.x - (width / 2) + 8
                        }
                        readonly property bool isConnected: root.wifiPanel && root.wifiPanel.currentSSID !== ""
                        Rectangle {
                            anchors.centerIn: parent
                            width:  wifiMa.containsMouse || root.wifiVisible ? 28 : 0
                            height: width; radius: 6
                            color: root.wifiVisible
                                ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.18)
                                : Qt.rgba(1,1,1,0.07)
                            Behavior on width  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                        readonly property string wifiIcon: {
                            if (!isConnected) return "󰤮";
                            const signal = root.wifiPanel.wifiSignal;
                            if (signal > 75) return "󰤨";
                            if (signal > 50) return "󰤥";
                            if (signal > 25) return "󰤢";
                            return "󰤟";
                        }
                        Text {
                            anchors.centerIn: parent
                            text: parent.wifiIcon
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                            color: root.wifiVisible || parent.isConnected
                                ? zyuTheme.accent
                                : Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, wifiMa.containsMouse ? 0.8 : 0.4)
                        }
                        MouseArea {
                            id: wifiMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePanel("wifi")
                        }
                    }

                    // GitHub Button
                    Item {
                        id: githubButton
                        width: 32; height: 32
                        onXChanged: updateOffset()
                        onWidthChanged: updateOffset()
                        Component.onCompleted: updateOffset()
                        function updateOffset() {
                            var pt = mapToItem(null, 0, 0)
                            root.githubButtonRightOffset = barWindow.width - pt.x - (width / 2) + 8
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: githubMa.containsMouse || root.githubVisible ? 28 : 0
                            height: width; radius: 6
                            color: root.githubVisible
                                ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.18)
                                : Qt.rgba(1,1,1,0.07)
                            Behavior on width  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
                            color: root.githubVisible
                                ? zyuTheme.accent
                                : Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b,
                                               githubMa.containsMouse ? 0.8 : 0.4)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            id: githubMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePanel("github")
                        }
                    }

                    // Dashboard Button
                    Item {
                        id: dashboardButton
                        width: 32; height: 32
                        onXChanged: updateOffset()
                        onWidthChanged: updateOffset()
                        Component.onCompleted: updateOffset()
                        function updateOffset() {
                            var pt = mapToItem(null, 0, 0)
                            root.dashboardButtonRightOffset = barWindow.width - pt.x - (width / 2) + 8
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: dashMa.containsMouse ? 28 : 0; height: width; radius: 6
                            color: Qt.rgba(1,1,1,0.07)
                            Behavior on width  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "󰕮"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                            color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b,
                                           dashMa.containsMouse ? 0.8 : 0.4)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            id: dashMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePanel("dashboard")
                        }
                    }
                }
            }
        }
    }
}
