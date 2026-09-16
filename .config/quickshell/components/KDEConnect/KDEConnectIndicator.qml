import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    width: 32
    height: 32
    visible: KDEConnectService.isConnected

    property color iconColor: "#A3D9A5" // Matugen Primary fallback

    Image {
        id: phoneIcon
        anchors.centerIn: parent
        width: 18
        height: 18
        source: "image://icon/smartphone"
        fillMode: Image.PreserveAspectFit
    }

    Rectangle {
        visible: KDEConnectService.unreadCount > 0
        width: 14
        height: 14
        radius: 7
        color: iconColor
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 2

        Text {
            anchors.centerIn: parent
            text: KDEConnectService.unreadCount
            color: "#003912"
            font.pixelSize: 9
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: KDEConnectService.togglePanel()
    }
}
