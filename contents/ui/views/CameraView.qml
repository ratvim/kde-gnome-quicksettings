import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * CameraView.qml - GNOME-style Camera Privacy & Active Application Sub-View (Plasma 6)
 * Displays applications currently using or streaming from the camera with kill/stop controls.
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property bool cameraBlocked: false
    property var cameraApps: []

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"

    signal backClicked()
    signal toggleCamera()
    signal refreshClicked()
    signal stopApp(int pid)

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header with Back button & Master Privacy Switch
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: backMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "go-previous-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backClicked()
                }
            }

            Text {
                text: "Camera Access"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
            }

            // Camera Master Privacy Switch (On = Allowed / Available, Off = Blocked)
            Switch {
                checked: !root.cameraBlocked
                onToggled: root.toggleCamera()
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }

        // Subtitle explanation
        Text {
            Layout.fillWidth: true
            text: {
                if (root.cameraBlocked) {
                    return "Camera access is blocked. Applications cannot access the webcam hardware."
                }
                if (root.cameraApps && root.cameraApps.length > 0) {
                    return "Applications currently accessing or streaming from the camera:"
                }
                return "No applications are currently using the camera."
            }
            font.pixelSize: 11
            color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            wrapMode: Text.WordWrap
        }

        // Applications List (when active apps exist)
        ListView {
            id: appsList
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: visible ? -1 : 0
            clip: true
            visible: !root.cameraBlocked && (root.cameraApps && root.cameraApps.length > 0)
            model: (!root.cameraBlocked && root.cameraApps) ? root.cameraApps : []
            spacing: 8

            delegate: Rectangle {
                id: appCard
                width: appsList.width
                height: 56
                radius: 14
                color: itemMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06))
                                             : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.03))
                border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
                border.width: 1

                // 1. Left App Icon Badge
                Rectangle {
                    id: appIconBadge
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 10
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: modelData.icon || "camera-web-symbolic"
                        fallback: "camera-web-symbolic"
                    }
                }

                // 2. Right Action Button (Stop) - locked rigidly to parent.right
                Rectangle {
                    id: stopBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 64
                    height: 28
                    radius: 14
                    color: stopMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(0.9, 0.2, 0.2, 0.25) : Qt.rgba(0.9, 0.2, 0.2, 0.15))
                                                   : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))
                    border.color: stopMouse.containsMouse ? "#e01b24" : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Stop"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: stopMouse.containsMouse ? "#ff5c57" : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
                    }

                    MouseArea {
                        id: stopMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.pid) {
                                root.stopApp(modelData.pid)
                            }
                        }
                    }
                }

                // 3. Middle Text Column: bound between appIconBadge and stopBtn with explicit elide
                Column {
                    anchors.left: appIconBadge.right
                    anchors.leftMargin: 12
                    anchors.right: stopBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: modelData.name || "Camera Application"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        elide: Text.ElideRight
                    }

                    Row {
                        width: parent.width
                        spacing: 5

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: "#2ec27e"
                        }

                        Text {
                            text: modelData.details || "In Use"
                            font.pixelSize: 11
                            color: "#2ec27e"
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    anchors.rightMargin: 80
                    hoverEnabled: true
                }
            }
        }

        // Empty state when unblocked but no apps active
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: visible ? -1 : 0
            visible: !root.cameraBlocked && (!root.cameraApps || root.cameraApps.length === 0)
            color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.02)
            radius: 14
            border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    width: 36
                    height: 36
                    source: "camera-web-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.35
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No Active Applications"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.8
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No apps are currently streaming or accessing video."
                    font.pixelSize: 11
                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                }
            }
        }

        // State display when Camera is Blocked
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: visible ? -1 : 0
            visible: root.cameraBlocked
            color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.02)
            radius: 14
            border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    width: 36
                    height: 36
                    source: "camera-off-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.35
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Camera Access is Blocked"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.8
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Flip the switch above to restore webcam access."
                    font.pixelSize: 11
                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                }
            }
        }

        // Footer Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                Layout.fillWidth: true
                text: "Refresh Active Apps"
                icon.name: "view-refresh-symbolic"
                onClicked: root.refreshClicked()
            }
        }
    }

    Component.onCompleted: root.refreshClicked()
}
