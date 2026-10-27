import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * KdeConnectView.qml - KDE Connect device management and quick actions sub-view (Plasma 6)
 * Displays reachable & paired devices, device battery status, and direct action controls:
 *   - Ring Phone / Find Device
 *   - Send File / Share
 *   - SMS Messaging
 *   - Browse Device Storage (SFTP)
 *   - Send Ping Notification
 *   - Pair / Unpair
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property var devicesModel: []

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

        // Header with Back, Title, Refresh, and Settings
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
                text: "KDE Connect"
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

            // KDE Connect Settings App Button
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

        // Devices List or Empty State
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.devicesModel
            spacing: 12

            delegate: Rectangle {
                id: deviceCard
                width: listView.width
                implicitHeight: cardCol.implicitHeight + 20
                radius: 16
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
                            color: modelData.paired ? (root.isDarkTheme ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22) : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12))
                                                    : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08))

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: {
                                    if (modelData.type === "tablet") return "tablet-symbolic"
                                    if (modelData.type === "laptop" || modelData.type === "desktop") return "computer-symbolic"
                                    return "phone-symbolic"
                                }
                                isMask: true
                                color: modelData.paired ? root.accentColor : (root.isDarkTheme ? "#f6f8fa" : "#1a1a1a")
                            }
                        }

                        // Pair / Unpair Action Button - locked rigidly to parent.right
                        Rectangle {
                            id: pairActionBtn
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 72
                            height: 28
                            radius: 14
                            color: pairBtnMouse.containsMouse ? (modelData.paired ? "#e74c3c" : root.accentColor)
                                                              : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))

                            Text {
                                anchors.centerIn: parent
                                text: modelData.paired ? "Unpair" : "Pair"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: pairBtnMouse.containsMouse ? root.accentTextColor : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
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

                        // Name & Status Subtitle Column: bound between devBadge and pairActionBtn with explicit elide
                        Column {
                            anchors.left: devBadge.right
                            anchors.leftMargin: 10
                            anchors.right: pairActionBtn.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: modelData.name || "KDE Connect Device"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                elide: Text.ElideRight
                            }

                            Row {
                                width: parent.width
                                spacing: 5

                                Text {
                                    text: modelData.paired ? (modelData.reachable ? "Connected" : "Offline") : (modelData.reachable ? "Available to Pair" : "Not Reachable")
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: modelData.paired ? (modelData.reachable ? root.accentColor : (root.isDarkTheme ? "#9aa0a6" : "#606770")) : root.accentColor
                                }

                                // Battery Status (if reported)
                                Row {
                                    visible: modelData.battery !== undefined && modelData.battery >= 0
                                    spacing: 3
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: "•"
                                        font.pixelSize: 11
                                        color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                                    }

                                    Kirigami.Icon {
                                        width: 12
                                        height: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        source: {
                                            var b = modelData.battery || 0
                                            var step = Math.max(0, Math.min(100, Math.round(b / 10) * 10))
                                            var stepStr = ("000" + step).slice(-3)
                                            return modelData.charging ? ("battery-" + stepStr + "-charging") : ("battery-" + stepStr)
                                        }
                                    }

                                    Text {
                                        text: modelData.battery + "%"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    }
                                }
                            }
                        }
                    }

                    // Action Tiles Row (Ring, Send File, SMS, Browse SFTP, Ping)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // 1. Ring Phone Action
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 10
                            color: ringMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10))
                                                           : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    source: "notifications-symbolic"
                                    isMask: true
                                    color: ringMouse.containsMouse ? root.accentColor : (root.isDarkTheme ? "#f6f8fa" : "#1a1a1a")
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Ring"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
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

                        // 2. Send File Action
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 10
                            color: shareMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10))
                                                            : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    source: "document-send-symbolic"
                                    isMask: true
                                    color: shareMouse.containsMouse ? root.accentColor : (root.isDarkTheme ? "#f6f8fa" : "#1a1a1a")
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Send File"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
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

                        // 3. SMS Messages Action
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 10
                            color: smsMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10))
                                                          : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    source: "dialog-messages-symbolic"
                                    isMask: true
                                    color: smsMouse.containsMouse ? root.accentColor : (root.isDarkTheme ? "#f6f8fa" : "#1a1a1a")
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "SMS"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
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

                        // 4. Browse Files SFTP Action
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 10
                            color: browseMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10))
                                                             : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    source: "folder-remote-symbolic"
                                    isMask: true
                                    color: browseMouse.containsMouse ? root.accentColor : (root.isDarkTheme ? "#f6f8fa" : "#1a1a1a")
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Files"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
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

                        // 5. Ping Device Action
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 10
                            color: pingMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10))
                                                           : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    source: "network-connect-symbolic"
                                    isMask: true
                                    color: pingMouse.containsMouse ? root.accentColor : (root.isDarkTheme ? "#f6f8fa" : "#1a1a1a")
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Ping"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
                                }
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

        // Empty state when no devices are detected
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.devicesModel || root.devicesModel.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                width: parent.width - 40

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 56
                    height: 56
                    radius: 28
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        source: "kdeconnect-symbolic"
                        isMask: true
                        color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No Devices Found"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "Make sure your phone or tablet has the KDE Connect app open and is connected to the same Wi-Fi network."
                    font.pixelSize: 12
                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    width: 160
                    height: 34
                    radius: 17
                    color: pairNewMouse.containsMouse ? Qt.darker(root.accentColor, 1.15) : root.accentColor

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Kirigami.Icon {
                            implicitWidth: 14
                            implicitHeight: 14
                            source: "kdeconnect-symbolic"
                            isMask: true
                            color: root.accentTextColor
                        }

                        Text {
                            text: "Open KDE Connect"
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
        }

        // Bottom Footer Button: Open KDE Connect App
        Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 20
            color: bottomBtnMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10))
                                                : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
            border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Kirigami.Icon {
                    implicitWidth: 16
                    implicitHeight: 16
                    source: "kdeconnect-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                Text {
                    text: "Configure KDE Connect"
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

