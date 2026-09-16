import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: githubPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { 
        top: root.githubVisible ? 54 : -githubPanel.implicitHeight - 50 
        right: Math.max(16, root.githubButtonRightOffset - (githubPanel.implicitWidth / 2))
    }
    implicitHeight: 240
    implicitWidth: 780
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.githubVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Behavior on margins.top { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    
    readonly property color bg:      zyuTheme.bar_bg
    readonly property color fg:      zyuTheme.bar_fg
    readonly property color accent:  zyuTheme.accent
    readonly property color widgetBg: zyuTheme.widget_bg
    readonly property color muted:   Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.4)

    property string username: "Priyam792"
    property string githubScript: Quickshell.env("HOME") + "/.config/quickshell/components/github/github_helper.sh"
    property double refreshTimestamp: Date.now()
    property string commitCount: "0"
    property bool showRepos: false
    property var repoModel: []
    property var rectsModel: []

    // Helper function to format dates for tooltip
    function formatDate(dateStr) {
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var parts = dateStr.split("-");
        if (parts.length === 3) {
            var year = parts[0];
            var monthIndex = parseInt(parts[1]) - 1;
            var day = parseInt(parts[2]);
            return months[monthIndex] + " " + day + ", " + year;
        }
        return dateStr;
    }

    // JS XML parser to read rect positions, date and contributions from SVG
    function loadSvgData() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + Quickshell.env("HOME") + "/.cache/quickshell/github_contributions.svg", true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    parseSvg(xhr.responseText);
                }
            }
        }
        xhr.send();
    }

    function parseSvg(text) {
        var model = [];
        var regex = /<rect[^>]*style="[^"]*fill:([^;"]*)[^"]*"[^>]*data-score="([^"]*)"[^>]*data-date="([^"]*)"[^>]*x="([^"]*)"[^>]*y="([^"]*)"/g;
        var match;
        while ((match = regex.exec(text)) !== null) {
            model.push({
                fillColor: match[1],
                score: parseInt(match[2]),
                date: match[3],
                xPos: parseFloat(match[4]),
                yPos: parseFloat(match[5])
            });
        }
        githubPanel.rectsModel = model;
    }

    // Asynchronous reader for contribution count
    Process {
        id: readCountProc
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/github_commit_count.txt"]
        stdout: SplitParser {
            onRead: data => {
                githubPanel.commitCount = data.trim()
            }
        }
    }

    // Asynchronous reader for repositories JSON
    Process {
        id: readReposProc
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/github_repos.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    githubPanel.repoModel = JSON.parse(data)
                } catch(e) {
                    console.log("Error parsing repos:", e)
                }
            }
        }
    }

    // Asynchronous script update runner
    Process {
        id: githubUpdateProc
        command: ["bash", githubScript]
        onExited: {
            refreshTimestamp = Date.now()
            readCountProc.running = true
            readReposProc.running = true
            loadSvgData()
        }
    }

    // Listen to visibility state changes to trigger animations and background updates
    Connections {
        target: root
        function onGithubVisibleChanged() {
            if (root.githubVisible) {
                mainItem.forceActiveFocus()
                readCountProc.running = true
                readReposProc.running = true
                githubUpdateProc.running = true
                loadSvgData()
            }
        }
    }

    Item {
        id: mainItem
        anchors.fill: parent
        focus: root.githubVisible

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.githubVisible = false
                event.accepted = true
            }
        }

        Rectangle {
            width: 780
            height: 240
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(githubPanel.bg.r, githubPanel.bg.g, githubPanel.bg.b, 0.94)
            radius: 18
            border.color: githubPanel.widgetBg
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 36; height: 36; radius: 12
                        color: Qt.rgba(githubPanel.accent.r, githubPanel.accent.g, githubPanel.accent.b, 0.15)
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: githubPanel.accent
                            font.pixelSize: 20
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: githubPanel.showRepos ? "GitHub Repositories" : "GitHub Contributions"
                            color: githubPanel.fg
                            font.pixelSize: 15; font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        Text {
                            text: "@" + githubPanel.username + " • " + githubPanel.commitCount + " contributions last year"
                            color: githubPanel.muted
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Action Buttons
                    RowLayout {
                        spacing: 12
                        
                        // Repos Toggle
                        Rectangle {
                            width: 100; height: 30; radius: 8
                            color: reposMa.containsMouse || githubPanel.showRepos ? Qt.rgba(githubPanel.accent.r, githubPanel.accent.g, githubPanel.accent.b, 0.15) : Qt.rgba(1,1,1,0.06)
                            border.color: reposMa.containsMouse || githubPanel.showRepos ? githubPanel.accent : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: githubPanel.showRepos ? " Chart" : " Repos"
                                color: reposMa.containsMouse || githubPanel.showRepos ? githubPanel.accent : githubPanel.fg
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                id: reposMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    githubPanel.showRepos = !githubPanel.showRepos
                                    if (githubPanel.showRepos) {
                                        readReposProc.running = true
                                    }
                                }
                            }
                        }

                        // Open Profile
                        Rectangle {
                            width: 100; height: 30; radius: 8
                            color: openMa.containsMouse ? Qt.rgba(githubPanel.accent.r, githubPanel.accent.g, githubPanel.accent.b, 0.15) : Qt.rgba(1,1,1,0.06)
                            border.color: openMa.containsMouse ? githubPanel.accent : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: "󰌷 Profile"
                                color: openMa.containsMouse ? githubPanel.accent : githubPanel.fg
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                id: openMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/" + githubPanel.username])
                            }
                        }

                        // Reload Button (matching wifi/bluetooth)
                        Text {
                            id: reloadIcon
                            text: "󰑐"
                            color: reloadMa.containsMouse ? githubPanel.accent : githubPanel.muted
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RotationAnimation on rotation {
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 1000
                                running: githubUpdateProc.running
                            }

                            MouseArea {
                                id: reloadMa
                                anchors.fill: parent
                                anchors.margins: -8
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!githubUpdateProc.running) {
                                        githubUpdateProc.running = true
                                    }
                                }
                            }
                        }
                    }
                }

                // Graph/Repos Container
                Rectangle {
                    id: graphContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(0, 0, 0, 0.2)
                    radius: 12
                    clip: false

                    // Wrapper item to center, scale, and overlay hover targets on top of the SVG
                    Item {
                        id: chartWrapper
                        visible: !githubPanel.showRepos
                        anchors.centerIn: parent
                        width: 663
                        height: 104
                        scale: 1.08

                        Image {
                            id: graphImage
                            anchors.fill: parent
                            source: "file://" + Quickshell.env("HOME") + "/.cache/quickshell/github_contributions.svg?t=" + githubPanel.refreshTimestamp
                            fillMode: Image.Stretch
                            cache: false
                            asynchronous: true
                            
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        // Interactive MouseAreas positioned at the exact coordinates of the SVG squares
                        Repeater {
                            model: githubPanel.rectsModel

                            delegate: Item {
                                x: modelData.xPos
                                y: modelData.yPos
                                width: 10
                                height: 10

                                MouseArea {
                                    id: squareMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onEntered: {
                                        var scoreStr = modelData.score === 0 ? "No" : modelData.score
                                        tooltipText.text = scoreStr + (modelData.score === 1 ? " contribution" : " contributions") + " on " + formatDate(modelData.date)
                                        
                                        // Map relative coordinates to main window to position tooltip
                                        var p = mapToItem(mainItem, width / 2, -6)
                                        tooltip.x = p.x - tooltip.width / 2
                                        tooltip.y = p.y - tooltip.height
                                        tooltip.visible = true
                                    }
                                    onExited: {
                                        tooltip.visible = false
                                    }
                                }
                            }
                        }
                    }

                    GridView {
                        id: reposGrid
                        visible: githubPanel.showRepos
                        anchors.fill: parent
                        anchors.margins: 10
                        cellWidth: reposGrid.width / 2
                        cellHeight: 56
                        model: githubPanel.repoModel
                        clip: true

                        delegate: Rectangle {
                            width: reposGrid.cellWidth - 8
                            height: reposGrid.cellHeight - 6
                            radius: 8
                            color: repoItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)
                            border.color: repoItemMa.containsMouse ? githubPanel.accent : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }

                            MouseArea {
                                id: repoItemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["xdg-open", modelData.url])
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    
                                    RowLayout {
                                        spacing: 6
                                        Text {
                                            text: modelData.name
                                            color: githubPanel.fg
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.family: "JetBrainsMono Nerd Font"
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: reposGrid.cellWidth * 0.65
                                        }
                                        
                                        // Language badge
                                        Text {
                                            text: modelData.lang
                                            color: githubPanel.muted
                                            font.pixelSize: 8
                                            font.family: "JetBrainsMono Nerd Font"
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        text: modelData.description || "No description provided."
                                        color: githubPanel.fg
                                        opacity: 0.5
                                        font.pixelSize: 9
                                        font.family: "JetBrainsMono Nerd Font"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                // Stars
                                RowLayout {
                                    spacing: 2
                                    visible: modelData.stars > 0
                                    Text {
                                        text: "󰓎"
                                        color: "#f9e2af"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                    }
                                    Text {
                                        text: modelData.stars
                                        color: githubPanel.fg
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Custom Github Tooltip popup overlay
        Rectangle {
            id: tooltip
            visible: false
            width: tooltipText.implicitWidth + 16
            height: tooltipText.implicitHeight + 10
            color: "#1e1e2e"
            radius: 6
            border.color: githubPanel.accent
            border.width: 1
            z: 1000

            Text {
                id: tooltipText
                anchors.centerIn: parent
                color: "#cdd6f4"
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
                font.bold: true
            }
        }
    }
}
