import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: musicPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true }
    margins {
        top: root.musicVisible ? 54 : -musicPanel.implicitHeight - 50
    }
    
    implicitHeight: musicPanel.activePlayersList.length > 1 ? 118 : 106
    implicitWidth: 460
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: musicPanel.focusState

    Shortcut {
        sequence: "Escape"
        enabled: root.musicVisible
        onActivated: root.closeAllPopups()
        context: Qt.ApplicationShortcut
    }

    Behavior on margins.top { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    // ── Colors (zyuTheme) ──
    readonly property color walBackground: zyuTheme.bar_bg
    readonly property color walForeground: zyuTheme.bar_fg
    readonly property color walColor5:     zyuTheme.accent
    readonly property color walColor8:     Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.5)

    // ── MPRIS (Multi-source managed) ──
    readonly property var activePlayersList: {
        var players = Mpris.players.values
        var active = []
        if (!players) return active
        for (var i = 0; i < players.length; i++) {
            var p = players[i]
            if (p.playbackState === MprisPlaybackState.Playing || 
                p.playbackState === MprisPlaybackState.Paused ||
                (p.trackTitle && p.trackTitle !== "")) {
                active.push(p)
            }
        }
        return active
    }
    property int selectedPlayerIndex: 0
    
    // Auto-focus on active playback transitions
    property var lastPlayingStates: ({})
    onActivePlayersListChanged: {
        for (var i = 0; i < activePlayersList.length; i++) {
            var p = activePlayersList[i]
            var bus = p.dbusName || ("player-" + i)
            var wasPlaying = lastPlayingStates[bus] || false
            var isNowPlaying = p.playbackState === MprisPlaybackState.Playing
            if (isNowPlaying && !wasPlaying) {
                selectedPlayerIndex = i
            }
            lastPlayingStates[bus] = isNowPlaying
        }
        if (selectedPlayerIndex >= activePlayersList.length) {
            selectedPlayerIndex = Math.max(0, activePlayersList.length - 1)
        }
    }
    
    readonly property var player: (activePlayersList && activePlayersList.length > 0) ? activePlayersList[selectedPlayerIndex] : null
    property bool scrollActive: false

    onPlayerChanged: {
        root.selectedPlayerBus = player ? (player.dbusName || player.name || player.identity || "") : ""
        if (player) {
            player.positionChanged()
            trackPosition = player.position
        } else {
            trackPosition = 0
        }
    }

    readonly property bool hasTrack:     player !== null && (player.playbackState === MprisPlaybackState.Playing || player.playbackState === MprisPlaybackState.Paused)
    readonly property bool isPlaying:    player !== null && player.playbackState === MprisPlaybackState.Playing
    readonly property string trackTitle:  player ? (player.trackTitle  || "") : ""
    readonly property string trackArtist: player ? (player.trackArtist || "") : ""
    readonly property string trackAlbum:  player ? (player.trackAlbum  || "") : ""
    readonly property string artUrl:      player ? (player.trackArtUrl || "") : ""
    readonly property real trackLength:   player ? (player.length || 0) : 0
    property real trackPosition: 0

    // Seek tracking to prevent rubber-banding/jumping delay
    property bool isSeeking: false

    // ── Helpers ──
    function formatTime(seconds) {
        if (seconds < 0) return "0:00"
        var mins = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    Timer {
        id: scrollResetTimer
        interval: 120; repeat: false
        onTriggered: musicPanel.scrollActive = false
    }

    Timer {
        interval: 1000
        running: root.musicVisible && musicPanel.isPlaying && !musicPanel.isSeeking
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (musicPanel.player) {
                musicPanel.player.positionChanged()
                musicPanel.trackPosition = musicPanel.player.position
            }
        }
    }

    Timer {
        id: seekReleaseTimer
        interval: 500
        repeat: false
        onTriggered: musicPanel.isSeeking = false
    }

    // ── Focus handling ──
    property int focusState: WlrKeyboardFocus.None

    Connections {
        target: root
        function onMusicVisibleChanged() {
            if (root.musicVisible) {
                focusTimer.start()
            } else {
                focusTimer.stop()
                releaseTimer.stop()
                musicPanel.focusState = WlrKeyboardFocus.None
            }
        }
    }
    Timer { 
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: { 
            musicPanel.focusState = WlrKeyboardFocus.Exclusive
            releaseTimer.start() 
        } 
    }
    Timer { 
        id: releaseTimer
        interval: 100
        repeat: false
        onTriggered: { 
            musicPanel.focusState = WlrKeyboardFocus.OnDemand
            mainItem.forceActiveFocus()
        } 
    }

    // ── UI ──
    Item {
        id: mainItem
        anchors.fill: parent
        focus: root.musicVisible

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.musicVisible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Space) {
                if (musicPanel.player && musicPanel.player.canTogglePlaying) musicPanel.player.togglePlaying()
                event.accepted = true
            } else if (event.key === Qt.Key_N) {
                if (musicPanel.player && musicPanel.player.canGoNext) musicPanel.player.next()
                event.accepted = true
            } else if (event.key === Qt.Key_P) {
                if (musicPanel.player && musicPanel.player.canGoPrevious) musicPanel.player.previous()
                event.accepted = true
            }
        }

        // Main Card
        Rectangle {
            width: 460
            height: parent.height
            color: Qt.rgba(musicPanel.walBackground.r, musicPanel.walBackground.g, musicPanel.walBackground.b, 0.95)
            radius: 18
            border.color: Qt.rgba(musicPanel.walForeground.r, musicPanel.walForeground.g, musicPanel.walForeground.b, 0.1)
            border.width: 1
            clip: true

            // MouseArea to switch sources on scroll hover
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    if (musicPanel.activePlayersList.length <= 1) return
                    
                    var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                    if (Math.abs(delta) < 15) return
                    
                    scrollResetTimer.restart()
                    if (musicPanel.scrollActive) return
                    
                    if (delta > 0) {
                        if (musicPanel.selectedPlayerIndex > 0) {
                            musicPanel.scrollActive = true
                            musicPanel.selectedPlayerIndex = musicPanel.selectedPlayerIndex - 1
                        }
                    } else if (delta < 0) {
                        if (musicPanel.selectedPlayerIndex < musicPanel.activePlayersList.length - 1) {
                            musicPanel.scrollActive = true
                            musicPanel.selectedPlayerIndex = musicPanel.selectedPlayerIndex + 1
                        }
                    }
                }
            }

            ListView {
                id: playerListView
                anchors.fill: parent
                orientation: ListView.Horizontal
                snapMode: ListView.SnapOneItem
                highlightRangeMode: ListView.StrictlyEnforceRange
                clip: true
                model: musicPanel.activePlayersList
                currentIndex: musicPanel.selectedPlayerIndex
                interactive: false
                highlightMoveDuration: 250
                
                delegate: Item {
                    width: 460
                    height: playerListView.height
                    
                    readonly property var p: modelData
                    readonly property bool isActive: index === musicPanel.selectedPlayerIndex
                    readonly property real positionVal: isActive ? musicPanel.trackPosition : p.position

                    // Compact Android Media Notification Layout
                    RowLayout {
                        anchors.fill: parent
                        anchors.topMargin: 10
                        anchors.bottomMargin: musicPanel.activePlayersList.length > 1 ? 18 : 10
                        anchors.leftMargin: 10
                        anchors.rightMargin: 14
                        spacing: 14
                        
                        // Album Art
                        Rectangle {
                            id: compactArtWrapper
                            Layout.preferredWidth: 86
                            Layout.preferredHeight: 86
                            radius: 12
                            color: Qt.rgba(musicPanel.walColor5.r, musicPanel.walColor5.g, musicPanel.walColor5.b, 0.1)
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: 86
                                    height: 86
                                    radius: 12
                                }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                visible: compactArt.status !== Image.Ready
                                text: "󰎆"
                                color: Qt.rgba(musicPanel.walColor5.r, musicPanel.walColor5.g, musicPanel.walColor5.b, 0.3)
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 36
                            }
                            Image {
                                id: compactArt
                                anchors.fill: parent
                                visible: p.trackArtUrl !== ""
                                source: p.trackArtUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 86
                                sourceSize.height: 86
                            }
                        }
                        
                        // Details Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 1
                            
                            // Title
                            Text {
                                text: p.trackTitle || "Nothing Playing"
                                color: musicPanel.walForeground
                                font.pixelSize: 13; font.bold: true
                                font.family: "JetBrainsMono Nerd Font"
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            
                            // Artist
                            Text {
                                text: p.trackArtist || "Unknown Artist"
                                color: musicPanel.walColor5
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            
                            // Progress Row (Time Labels on the sides)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                
                                Text {
                                    text: musicPanel.formatTime(positionVal)
                                    color: musicPanel.walColor8
                                    font.pixelSize: 9
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                
                                // Seekable Progress Bar with Thumb
                                Rectangle {
                                    id: progressBarTrack
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 3
                                    radius: 1.5
                                    color: Qt.rgba(musicPanel.walForeground.r, musicPanel.walForeground.g, musicPanel.walForeground.b, 0.1)
                                    
                                    Rectangle {
                                        id: progressFill
                                        width: parent.width * (p.length > 0 ? Math.min(1.0, Math.max(0.0, positionVal / p.length)) : 0)
                                        height: parent.height
                                        radius: 1.5
                                        color: musicPanel.walColor5
                                    }
                                    
                                    // Progress Thumb (Filled Circle)
                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        color: musicPanel.walColor5
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: progressFill.width - width / 2
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        
                                        function updatePosition(mouseX) {
                                            if (p.length > 0 && p.canSeek) {
                                                musicPanel.isSeeking = true
                                                seekReleaseTimer.stop()
                                                
                                                var clampedX = Math.max(0, Math.min(progressBarTrack.width, mouseX));
                                                var targetPos = (clampedX / progressBarTrack.width) * p.length;
                                                musicPanel.trackPosition = targetPos;
                                            }
                                        }
                                        
                                        onPressed: updatePosition(mouse.x)
                                        onPositionChanged: {
                                            if (pressed) {
                                                updatePosition(mouse.x);
                                            }
                                        }
                                        onReleased: {
                                            if (p.length > 0 && p.canSeek) {
                                                p.position = musicPanel.trackPosition;
                                                seekReleaseTimer.start()
                                            } else {
                                                musicPanel.isSeeking = false
                                            }
                                        }
                                    }
                                }
                                
                                Text {
                                    text: musicPanel.formatTime(p.length)
                                    color: musicPanel.walColor8
                                    font.pixelSize: 9
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                            
                            // Controls Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 28
                                Layout.alignment: Qt.AlignHCenter
                                
                                Item { Layout.fillWidth: true }
                                
                                // Previous
                                Text {
                                    text: "󰒮"
                                    color: musicPanel.walForeground
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"
                                    opacity: p.canGoPrevious ? 0.8 : 0.3
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: p.canGoPrevious
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (p.canGoPrevious) p.previous()
                                    }
                                }
                                
                                // Play/Pause
                                Text {
                                    text: p.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                                    color: musicPanel.walColor5
                                    font.pixelSize: 18
                                    font.family: "JetBrainsMono Nerd Font"
                                    opacity: p.canTogglePlaying ? 1.0 : 0.3
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: p.canTogglePlaying
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (p.canTogglePlaying) p.togglePlaying()
                                    }
                                }
                                
                                // Next
                                Text {
                                    text: "󰒭"
                                    color: musicPanel.walForeground
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"
                                    opacity: p.canGoNext ? 0.8 : 0.3
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: p.canGoNext
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (p.canGoNext) p.next()
                                    }
                                }
                                
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }

            // Interactive source indicator dots
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                visible: musicPanel.activePlayersList.length > 1

                Repeater {
                    model: musicPanel.activePlayersList.length
                    delegate: Rectangle {
                        width: index === musicPanel.selectedPlayerIndex ? 12 : 6
                        height: 6
                        radius: 3
                        color: index === musicPanel.selectedPlayerIndex ? musicPanel.walColor5 : Qt.rgba(musicPanel.walForeground.r, musicPanel.walForeground.g, musicPanel.walForeground.b, 0.25)
                        
                        Behavior on width { NumberAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
