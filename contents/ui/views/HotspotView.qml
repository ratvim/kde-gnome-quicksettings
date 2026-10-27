import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * HotspotView.qml - GNOME-style Mobile Hotspot Sub-View (Plasma 6)
 * Displays Hotspot active status, SSID, password, and quick-jump to system settings.
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property bool hotspotEnabled: false
    property string hotspotSsid: ""
    property string hotspotPassword: ""
    property bool showPassword: false

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"

    signal backClicked()
    signal toggleHotspot()
    signal refreshClicked()
    signal openSettingsClicked()

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header with Back button & Master Hotspot Switch
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
                text: "Wi-Fi Hotspot"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
            }

            // Master Hotspot Switch (On = Active, Off = Disabled)
            Switch {
                checked: root.hotspotEnabled
                onToggled: root.toggleHotspot()
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
                if (root.hotspotEnabled) {
                    return "Broadcasting Wi-Fi network. Other devices can connect using the credentials below:"
                }
                return "Share your internet connection with other devices over Wi-Fi. (Client Wi-Fi will pause while broadcasting)."
            }
            font.pixelSize: 11
            color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            wrapMode: Text.WordWrap
        }

        // Active State Details Cards (SSID and Password)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: visible ? -1 : 0
            visible: root.hotspotEnabled
            spacing: 8

            // 1. Network Name (SSID) Card
            Rectangle {
                Layout.fillWidth: true
                height: 56
                radius: 14
                color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.03)
                border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
                border.width: 1

                // Left Icon Badge
                Rectangle {
                    id: ssidBadge
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
                        source: "network-wireless-hotspot-symbolic"
                        fallback: "network-wireless-symbolic"
                    }
                }

                // Right Status Badge
                Rectangle {
                    id: activeBadge
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 64
                    height: 28
                    radius: 14
                    color: root.isDarkTheme ? Qt.rgba(46, 194, 126, 0.15) : Qt.rgba(46, 194, 126, 0.12)
                    border.color: "#2ec27e"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: "#2ec27e"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Active"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: "#2ec27e"
                        }
                    }
                }

                // Middle Text: Network Name
                Column {
                    anchors.left: ssidBadge.right
                    anchors.leftMargin: 12
                    anchors.right: activeBadge.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Network Name (SSID)"
                        font.pixelSize: 10
                        color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.hotspotSsid || "Hotspot"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        elide: Text.ElideRight
                    }
                }
            }

            // 2. Wi-Fi Password Card
            Rectangle {
                Layout.fillWidth: true
                height: 56
                radius: 14
                color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.03)
                border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
                border.width: 1

                // Left Icon Badge
                Rectangle {
                    id: passBadge
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 10
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: "system-lock-screen-symbolic"
                        fallback: "system-lock-screen-symbolic"
                    }
                }

                // Right Show/Hide Action Button
                Rectangle {
                    id: showPassBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 64
                    height: 28
                    radius: 14
                    color: passMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10))
                                                   : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.12)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.showPassword ? "Hide" : "Show"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    }

                    MouseArea {
                        id: passMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showPassword = !root.showPassword
                    }
                }

                // Middle Text: Password
                Column {
                    anchors.left: passBadge.right
                    anchors.leftMargin: 12
                    anchors.right: showPassBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Wi-Fi Password"
                        font.pixelSize: 10
                        color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: {
                            if (!root.hotspotPassword) return "None (Open Network)"
                            return root.showPassword ? root.hotspotPassword : "••••••••••••"
                        }
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        font.family: root.showPassword ? "monospace" : "default"
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Inactive State Card (when Hotspot is off)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: visible ? -1 : 0
            visible: !root.hotspotEnabled
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
                    source: "network-wireless-hotspot-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.35
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Hotspot is Inactive"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.8
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.hotspotSsid ? ("Configured network: " + root.hotspotSsid) : "Flip the switch above to start broadcasting."
                    font.pixelSize: 11
                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                }
            }
        }

        // Footer Actions: Open KDE Hotspot System Settings
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                Layout.fillWidth: true
                text: "Hotspot Configuration..."
                icon.name: "settings-configure-symbolic"
                onClicked: root.openSettingsClicked()
            }
        }
    }

    Component.onCompleted: root.refreshClicked()
}

