import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: main
    visible: root.pdfVisible
    implicitWidth: Screen.width
    implicitHeight: Screen.height
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.pdfVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property color bgMain:       root.zyuTheme.bar_bg
    readonly property color accent:       root.zyuTheme.accent
    readonly property color borderCol:    root.zyuTheme.widget_bg
    readonly property color textMain:     root.zyuTheme.bar_fg
    readonly property string activeFont:  "JetBrains Mono"
    readonly property string pdfPath:     Quickshell.env("HOME") + "/Documents/PDFs/"
    readonly property string pdfScript:   Quickshell.env("HOME") + "/.config/quickshell/components/pdf/pdf_helper.sh"

    Item {
        id: pdfRoot
        anchors.fill: parent
        focus: true

        Component.onCompleted: {
            pdfRoot.forceActiveFocus()
            Quickshell.execDetached(["bash", pdfScript, "--update"])
        }

        // Trigger updates when visible becomes true
        Connections {
            target: root
            function onPdfVisibleChanged() {
                if (root.pdfVisible) {
                    pdfRoot.forceActiveFocus()
                    Quickshell.execDetached(["bash", pdfScript, "--update"])
                }
            }
        }

        // Click outside the panel to close
        MouseArea {
            anchors.fill: parent
            onClicked: root.togglePanel("pdf")
        }

        Rectangle {
            id: mainPanel
            width: 1200; height: 750
            anchors.centerIn: parent
            color: bgMain
            radius: 16
            border.color: borderCol
            border.width: 2
            clip: true

            // Stop click propagation to background close area
            MouseArea {
                anchors.fill: parent
                onClicked: (event) => event.accepted = true
            }

            Item {
                id: header
                width: parent.width; height: 90

                Row {
                    anchors.left: parent.left; anchors.leftMargin: 35
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 15
                    Text { text: "󰈦"; font.pixelSize: 32; color: accent; font.family: "Symbols Nerd Font" }
                    Text { text: "PDF Library"; font.pixelSize: 24; font.bold: true; color: textMain; font.family: activeFont }
                }

                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 35
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110; height: 35; radius: 18; color: borderCol
                    Text {
                        anchors.centerIn: parent
                        text: folderModel.count + " documents"
                        font.pixelSize: 14; color: textMain; font.family: activeFont
                    }
                }
            }

            GridView {
                id: grid
                width: parent.width - 60; height: parent.height - 130
                anchors.top: header.bottom; anchors.topMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
                model: folderModel
                cellWidth: width / 5; cellHeight: 310
                clip: true
                cacheBuffer: 1000

                FolderListModel {
                    id: folderModel
                    folder: "file://" + pdfPath
                    showDirs: false
                    nameFilters: ["*.pdf"]
                }

                delegate: Item {
                    width: grid.cellWidth; height: grid.cellHeight

                    Rectangle {
                        id: card
                        width: parent.width - 16; height: parent.height - 16
                        anchors.centerIn: parent
                        radius: 12
                        color: grid.currentIndex === index ? borderCol : "transparent"
                        clip: true

                        border.width: 2
                        border.color: grid.currentIndex === index ? accent : borderCol

                        // Thumbnail container
                        Rectangle {
                            id: thumbContainer
                            width: parent.width; height: parent.height - 70
                            color: "#0a0a0a"
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: "file://" + Quickshell.env("HOME") + "/Documents/PDFs/.thumbs/" + fileName.replace(/\.pdf$/i, ".png")
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(300, 420)
                                visible: status === Image.Ready

                                // smooth transition when loaded
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }

                            // Fallback if thumbnail is loading or failed
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                visible: status !== Image.Ready

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "󰈦"
                                        font.pixelSize: 48
                                        color: accent
                                        font.family: "Symbols Nerd Font"
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Loading..."
                                        font.pixelSize: 12
                                        color: textMain
                                        font.family: activeFont
                                    }
                                }
                            }
                        }

                        // Title Container
                        Rectangle {
                            anchors.top: thumbContainer.bottom
                            width: parent.width; height: 70
                            color: grid.currentIndex === index ? borderCol : "transparent"

                            Text {
                                anchors.fill: parent
                                anchors.margins: 10
                                text: fileName.replace(/\.pdf$/i, "")
                                color: textMain
                                font.pixelSize: 13
                                font.bold: grid.currentIndex === index
                                font.family: activeFont
                                elide: Text.ElideRight
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                grid.currentIndex = index
                                pdfRoot.forceActiveFocus()
                            }
                            onDoubleClicked: openPDF(filePath)
                        }
                    }
                }
            }
        }

        Keys.onPressed: (event) => {
            if      (event.key === Qt.Key_Right || event.key === Qt.Key_L) grid.moveCurrentIndexRight()
            else if (event.key === Qt.Key_Left  || event.key === Qt.Key_H) grid.moveCurrentIndexLeft()
            else if (event.key === Qt.Key_Down  || event.key === Qt.Key_J) grid.moveCurrentIndexDown()
            else if (event.key === Qt.Key_Up    || event.key === Qt.Key_K) grid.moveCurrentIndexUp()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                let path = folderModel.get(grid.currentIndex, "filePath")
                if (path) openPDF(path)
            }
            else if (event.key === Qt.Key_Escape) root.togglePanel("pdf")
        }
    }

    function openPDF(path) {
        console.log("Opening PDF:", path)
        Quickshell.execDetached(["bash", pdfScript, "--open", path])
        root.togglePanel("pdf")
    }
}
