import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * KdeConnectView.qml - Dedicated KDE Connect device management sub-view (Plasma 6)
 * Features:
 *   - Reachable & paired mobile/desktop devices
 *   - Live device battery percentage and charging state
 *   - Quick triggers: Ring Phone, Share File, SMS, SFTP Browse Storage, Ping
 *   - Device pairing / unpairing
 *   - Direct shortcut to KDE Connect configuration
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property var devicesModel: []
    property var backend: null

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"
    readonly property color accentTextColor: (Kirigami.Theme.highlightedTextColor !== undefined && Kirigami.Theme.highlightedTextColor.a > 0) ? Kirigami.Theme.highlightedTextColor : "#ffffff"

    signal backClicked()
    signal refreshClicked()
    signal ringClicked(string devId)
    signal pingClicked(string devId)
    signal shareClicked(string devId)
    signal smsClicked()
    signal browseClicked(string devId)
    signal pairClicked(string devId)
    signal unpairClicked(string devId)
    signal openSettingsClicked()

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header with Back, Title, Refresh, and Settings Button
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
                text: i18n("KDE Connect")
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
            }

            // Refresh Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: refreshMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                Kirigami.Icon {
                    id: refreshIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "view-refresh-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        refreshAnim.start()
                        root.refreshClicked()
                    }
                }

                RotationAnimation {
                    id: refreshAnim
                    target: refreshIcon
                    from: 0
                    to: 360
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }

            // Settings Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: settingsMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "settings-configure-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openSettingsClicked()
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }

        // Devices List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.devicesModel
            spacing: 10
            visible: Boolean(root.devicesModel && root.devicesModel.length > 0)

            delegate: Rectangle {
                id: deviceCard
                width: listView.width
                implicitHeight: cardCol.implicitHeight + 20
                radius: 14
                color: modelData.paired ? (root.isDarkTheme ? Qt.rgba(53/255, 132/255, 228/255, 0.18) : Qt.rgba(53/255, 132/255, 228/255, 0.10))
                                       : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
                border.color: modelData.paired ? (root.isDarkTheme ? Qt.rgba(53/255, 132/255, 228/255, 0.5) : Qt.rgba(53/255, 132/255, 228/255, 0.3))
                                              : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06))
                border.width: 1

                ColumnLayout {
                    id: cardCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // Top Device Info Row
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 38

                        // Device Type Badge
                        Rectangle {
                            id: devBadge
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38
                            height: 38
                            radius: 19
                            color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: {
                                    var t = (modelData.type || modelData.deviceType || "").toLowerCase()
                                    if (t === "tablet") return "tablet-symbolic"
                                    if (t === "laptop" || t === "desktop" || t === "computer") return "computer-symbolic"
                                    return "phone-symbolic"
                                }
                                isMask: true
                                color: root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
                            }
                        }

                        // Right Pair/Unpair button
                        Rectangle {
                            id: pairActionBtn
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 72
                            height: 28
                            radius: 14
                            color: pairBtnMouse.containsMouse
                                   ? (modelData.paired ? "#e74c3c" : root.accentColor)
                                   : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))

                            Text {
                                anchors.centerIn: parent
                                text: modelData.paired ? i18n("Unpair") : i18n("Pair")
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: pairBtnMouse.containsMouse ? "#ffffff" : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
                            }

                            MouseArea {
                                id: pairBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.paired) {
                                        root.unpairClicked(modelData.id)
                                    } else {
                                        root.pairClicked(modelData.id)
                                    }
                                }
                            }
                        }

                        // Middle Device Details
                        ColumnLayout {
                            anchors.left: devBadge.right
                            anchors.right: pairActionBtn.left
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: modelData.name || i18n("Unknown Device")
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true

                                Kirigami.Icon {
                                    visible: (typeof modelData.battery === "number" && modelData.battery >= 0)
                                    implicitWidth: 12
                                    implicitHeight: 12
                                    source: "battery-symbolic"
                                    isMask: true
                                    color: (modelData.battery <= 20) ? "#e74c3c" : (root.isDarkTheme ? "#9aa0a6" : "#606770")
                                }

                                Text {
                                    text: {
                                        var details = []
                                        if (typeof modelData.battery === "number" && modelData.battery >= 0) {
                                            details.push(modelData.battery + "%")
                                        }
                                        details.push(modelData.paired ? i18n("Paired") : i18n("Available"))
                                        return details.join(" • ")
                                    }
                                    font.pixelSize: 11
                                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    // Paired Device Action Buttons
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: 10
                        visible: modelData.paired
                        color: root.isDarkTheme ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(255, 255, 255, 0.45)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4

                            // 1. Ring Phone
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: ringMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Kirigami.Icon {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        source: "notifications-symbolic"
                                        isMask: true
                                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    }

                                    Text {
                                        text: i18n("Ring")
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    }
                                }

                                MouseArea {
                                    id: ringMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.ringClicked(modelData.id)
                                }
                            }

                            // 2. Share / Send File
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: shareMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Kirigami.Icon {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        source: "document-send-symbolic"
                                        fallback: Qt.resolvedUrl("../../icons/document-send-symbolic.svg")
                                        isMask: true
                                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    }

                                    Text {
                                        text: i18n("Share")
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    }
                                }

                                MouseArea {
                                    id: shareMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.shareClicked(modelData.id)
                                }
                            }

                            // 3. SMS Messaging
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: smsMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Kirigami.Icon {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        source: "chat-message-new-symbolic"
                                        fallback: Qt.resolvedUrl("../../icons/chat-message-new-symbolic.svg")
                                        isMask: true
                                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    }

                                    Text {
                                        text: i18n("SMS")
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    }
                                }

                                MouseArea {
                                    id: smsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.smsClicked()
                                }
                            }

                            // 4. Browse Storage SFTP
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: browseMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Kirigami.Icon {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        source: "folder-remote-symbolic"
                                        fallback: Qt.resolvedUrl("../../icons/folder-remote-symbolic.svg")
                                        isMask: true
                                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    }

                                    Text {
                                        text: i18n("Browse")
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    }
                                }

                                MouseArea {
                                    id: browseMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.browseClicked(modelData.id)
                                }
                            }

                            // 5. Ping Device
                            Rectangle {
                                implicitWidth: 32
                                Layout.fillHeight: true
                                radius: 8
                                color: pingMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    source: "network-transmit-receive-symbolic"
                                    fallback: Qt.resolvedUrl("../../icons/network-transmit-receive-symbolic.svg")
                                    isMask: true
                                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                }

                                MouseArea {
                                    id: pingMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.pingClicked(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Empty state when no KDE Connect devices are discovered
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: (!root.devicesModel || root.devicesModel.length === 0)
            Layout.alignment: Qt.AlignCenter
            spacing: 12

            Kirigami.Icon {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 48
                implicitHeight: 48
                source: "kdeconnect-symbolic"
                fallback: Qt.resolvedUrl("../../icons/kdeconnect-symbolic.svg")
                isMask: true
                color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("No Connected Devices")
                font.pixelSize: 14
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: i18n("Make sure your phone or tablet has the KDE Connect app open and is connected to the same Wi-Fi network.")
                font.pixelSize: 12
                color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                implicitWidth: 160
                implicitHeight: 34
                radius: 17
                color: pairNewMouse.containsMouse ? Qt.darker(root.accentColor, 1.15) : root.accentColor

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Kirigami.Icon {
                        implicitWidth: 14
                        implicitHeight: 14
                        source: "kdeconnect-symbolic"
                        fallback: Qt.resolvedUrl("../../icons/kdeconnect-symbolic.svg")
                        isMask: true
                        color: root.accentTextColor
                    }

                    Text {
                        text: i18n("Open KDE Connect")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: root.accentTextColor
                    }
                }

                MouseArea {
                    id: pairNewMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openSettingsClicked()
                }
            }
        }

        // Bottom Footer Button: Configure KDE Connect
        Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 12
            color: bottomBtnMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
            border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Kirigami.Icon {
                    implicitWidth: 16
                    implicitHeight: 16
                    source: "kdeconnect-symbolic"
                    fallback: Qt.resolvedUrl("../../icons/kdeconnect-symbolic.svg")
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                Text {
                    text: i18n("Configure KDE Connect")
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }
            }

            MouseArea {
                id: bottomBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openSettingsClicked()
            }
        }
    }
}
