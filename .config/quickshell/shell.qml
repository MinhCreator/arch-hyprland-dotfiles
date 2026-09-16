//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root
    property alias zyuTheme: zyuTheme
    property alias dashboardState: dashboardState
    property alias logoutState: logoutState
    property alias batteryService: batServiceLoader.item
    property alias kdeConnectService: kdeConnectServiceLoader.item
    property alias btPanel: btPanelLoader.item
    property alias wifiPanel: wifiPanelLoader.item

    // ── ALL Visibility Properties ──
    property string selectedPlayerBus: ""
    property bool musicVisible: false
    property bool wifiVisible: false
    property bool btVisible: false
    property bool batVisible: false
    property bool trayVisible: false
    property bool wallpaperVisible: false
    property bool emojiclipVisible: false
    property bool kdeConnectVisible: false
    property bool pdfVisible: false
    property bool githubVisible: false
    property bool focusMode: false
    property real trayButtonRightOffset: 228
    property real kdeConnectButtonRightOffset: 228
    property real batteryButtonRightOffset: 228
    property real bluetoothButtonRightOffset: 228
    property real wifiButtonRightOffset: 228
    property real githubButtonRightOffset: 228
    property real dashboardButtonRightOffset: 228
    onFocusModeChanged: {
        if (focusMode) closeAllPopups()
        const msg = focusMode ? "Focus Mode Enabled" : "Focus Mode Disabled"
        const icon = focusMode ? "eye-close-symbolic" : "eye-open-symbolic"
        const cmd = `notify-send -i ${icon} "Quickshell" "${msg}"`
        const proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["bash", "-c", "' + cmd + '"] }', root)
        proc.running = true
    }

    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell"
    property string rofiBgSource: "file://" + Quickshell.env("HOME") + "/.config/rofi/rofi-bg.jpg"
    readonly property string compPath: configPath + "/components"

    // ── Toggle Helper ──
    function closeAllPopups() {
        musicVisible     = false
        wifiVisible      = false
        btVisible        = false
        batVisible       = false
        trayVisible      = false
        wallpaperVisible = false
        emojiclipVisible = false
        kdeConnectVisible = false
        pdfVisible       = false
        githubVisible    = false
        if (typeof dashboardState !== 'undefined') dashboardState.show = false
    }

    function togglePanel(panel) {
        musicVisible     = (panel === "music")     ? !musicVisible     : false
        wifiVisible      = (panel === "wifi")      ? !wifiVisible      : false
        btVisible        = (panel === "bt")        ? !btVisible        : false
        batVisible       = (panel === "bat")       ? !batVisible       : false
        trayVisible      = (panel === "tray")      ? !trayVisible      : false
        wallpaperVisible = (panel === "wallpaper") ? !wallpaperVisible : false
        emojiclipVisible = (panel === "emojiclip") ? !emojiclipVisible : false
        kdeConnectVisible = (panel === "kdeconnect") ? !kdeConnectVisible : false
        pdfVisible       = (panel === "pdf")       ? !pdfVisible       : false
        githubVisible    = (panel === "github")    ? !githubVisible    : false

        if (typeof dashboardState !== 'undefined') {
            dashboardState.show = (panel === "dashboard") ? !dashboardState.show : false
        }
    }

    QtObject {
        id: zyuTheme
        property bool floating_feel: true
        property color bar_bg:    "#08110d"
        property color bar_fg:    "#d8f3df"
        property color accent:    "#7ac79f"
        property color widget_bg: "#14211b"
        property int bar_height: 50
        property int rounding:   15
        property font mainFont: Qt.font({family: "JetBrainsMono Nerd Font", pixelSize: 14, bold: true})

        // Dashboard specific colors
        property color col1:    "#ffb4ab"
        property color col2:    "#7ac79f"
        property color col3:    "#bbc3ff"
        property color muted:   "#90909a"
    }

    QtObject {
        id: dashboardState
        property bool show: false
    }

    QtObject {
        id: logoutState
        property bool show: false
    }

    IpcHandler {
        target: "dashboard"
        function toggle() {
            root.dashboardState.show = !root.dashboardState.show
        }
    }

    IpcHandler {
        target: "emojiclip"
        function toggle() {
            root.togglePanel("emojiclip")
        }
    }

    IpcHandler {
        target: "focus"
        function toggle() {
            root.focusMode = !root.focusMode
        }
    }

    IpcHandler {
        target: "music"
        function toggle() {
            root.togglePanel("music")
        }
    }

    IpcHandler {
        target: "wifi"
        function toggle() {
            root.togglePanel("wifi")
        }
    }

    IpcHandler {
        target: "bt"
        function toggle() {
            root.togglePanel("bt")
        }
    }

    IpcHandler {
        target: "kdeconnect"
        function toggle() {
            root.togglePanel("kdeconnect")
        }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle() {
            root.togglePanel("wallpaper")
        }
    }

    IpcHandler {
        target: "pdf"
        function toggle() {
            root.togglePanel("pdf")
        }
    }

    IpcHandler {
        target: "github"
        function toggle() {
            root.togglePanel("github")
        }
    }

    IpcHandler {
        target: "theme"
        function reload() {
            colorsFile.reload()
            colorsFile.loadColors()
            root.rofiBgSource = "file://" + Quickshell.env("HOME") + "/.config/rofi/rofi-bg.jpg?t=" + Date.now()
        }
    }

    FileView {
        id: colorsFile
        path: configPath + "/Colors/colors.json"
        watchChanges: true
        onFileChanged: {
            reload()
            loadColors()
        }
        onLoadedChanged: {
            if (loaded) {
                loadColors()
            }
        }

        function loadColors() {
            try {
                var content = text()
                if (content === "") return;
                var c = JSON.parse(content)
                if (c.background)         zyuTheme.bar_bg    = c.background
                if (c.on_surface)         zyuTheme.bar_fg    = c.on_surface
                if (c.primary)            zyuTheme.accent    = c.primary
                if (c.surface_container)  zyuTheme.widget_bg = c.surface_container
                if (c.tertiary)           zyuTheme.col1      = c.tertiary
                if (c.secondary)          zyuTheme.col2      = c.secondary
                if (c.primary_fixed_dim)  zyuTheme.col3      = c.primary_fixed_dim
                if (c.on_surface_variant) zyuTheme.muted     = c.on_surface_variant
            } catch(e) {
                console.log("Error parsing colors.json: " + e)
            }
        }
    }

    Loader {
        id: batServiceLoader
        source: compPath + "/BatteryService.qml"
    }

    Loader {
    id: kdeConnectServiceLoader
    source: compPath + "/KDEConnect/KDEConnectService.qml"
    onLoaded: console.log("KDE service loaded, isConnected:", item.isConnected)
    }

    // ── Core UI ──
    Loader { source: compPath + "/Bar/bar.qml" }
    Loader { source: compPath + "/Clock.qml" }
    // Loader { source: compPath + "/linux.qml" }

    // ── Popup Panels ──
    Loader { source: compPath + "/Dashboard/Dashboard.qml" }
    Loader { source: compPath + "/MusicPanel.qml" }
    Loader { source: compPath + "/BatteryPanel.qml" }
    Loader { id: btPanelLoader; source: compPath + "/BluetoothPanel.qml" }
    Loader { id: wifiPanelLoader; source: compPath + "/WifiPanel.qml" }
    Loader { source: compPath + "/TrayPanel.qml" } // <-- Loads the popup!
    Loader { source: compPath + "/KDEConnect/KDEConnectPanel.qml" }

    Loader {
        active: root.emojiclipVisible
        source: compPath + "/Launcher/EmojiClip.qml"
    }

    Loader { source: compPath + "/wall/wall.qml" }
    Loader { source: compPath + "/pdf/pdf_opener.qml" }

    Loader {
        source: compPath + "/github/GithubPanel.qml"
    }

    Loader {
        source: compPath + "/BatteryPopup.qml"
        active: root.batteryService ? root.batteryService.showWarning : false
    }

    // Preload & cache the Rofi background image in system RAM & GPU pipeline
    Image {
        id: rofiBgCache
        source: root.rofiBgSource
        x: -9999; y: -9999
        width: 400; height: 250
        cache: true
        asynchronous: true
    }
}
