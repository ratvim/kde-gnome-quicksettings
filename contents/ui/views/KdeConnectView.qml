import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * KdeConnectView.qml - KDE Connect & Send Local (LocalSend) device management sub-view (Plasma 6)
 * Supports two modes:
 *   1. KDE Connect: Reachable & paired devices, device battery, ring, share, SMS, SFTP browse, ping.
 *   2. Send Local (LocalSend): Local Wi-Fi cross-platform file transfer, quick send file picker dialog,
 *      LocalSend daemon status, port 53317 network info, and direct app launcher.
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property bool isLocalSendMode: false
    property bool isSendFileMode: isLocalSendMode
    property var devicesModel: []
    property var backend: null

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"
    readonly property color accentTextColor: (Kirigami.Theme.highlightedTextColor !== undefined && Kirigami.Theme.highlightedTextColor.a > 0) ? Kirigami.Theme.highlightedTextColor : "#ffffff"

    signal backClicked()
    signal refreshClicked()
    signal openLocalSendClicked()
    signal sendLocalSendFileClicked()
    signal ringClicked(string devId)
    signal pingClicked(string devId)
    signal shareClicked(string devId)
    signal smsClicked()
    signal browseClicked(string devId)
    signal pairClicked(string devId)
    signal unpairClicked(string devId)
    signal openSettingsClicked()
    signal openSendFileClicked()

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header with Back, Title, Refresh, and Settings / App Button
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
                text: (root.isLocalSendMode || root.isSendFileMode) ? i18n("Send Local") : i18n("KDE Connect")
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

            // Settings / Launch App Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: settingsMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: (root.isLocalSendMode || root.isSendFileMode) ? "org.localsend.localsend_app" : "settings-configure-symbolic"
                    fallback: (root.isLocalSendMode || root.isSendFileMode) ? Qt.resolvedUrl("../../icons/document-send-symbolic.svg") : ""
                    isMask: !(root.isLocalSendMode || root.isSendFileMode)
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.isLocalSendMode || root.isSendFileMode) {
                            root.openLocalSendClicked()
                        } else {
                            root.openSettingsClicked()
                        }
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }

        // =========================================================================
        // TOP STATUS & QUICK ACTIONS CARD (VISIBLE IN SEND LOCAL / LOCALSEND MODE)
        // =========================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: lsCardCol.implicitHeight + 20
            radius: 14
            visible: (root.isLocalSendMode || root.isSendFileMode)
            color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
            border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
            border.width: 1

            ColumnLayout {
                id: lsCardCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Status Indicator Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        color: (backend && backend.localsendRunning) ? "#2ecc71" : "#9aa0a6"
                    }

                    Text {
                        text: (backend && backend.localsendRunning)
                              ? i18n("LocalSend is Active")
                              : i18n("LocalSend is Stopped")
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        Layout.fillWidth: true
                    }

                    Text {
                        text: (backend && backend.localsendLocalIp && backend.localsendLocalIp !== "")
                              ? (backend.localsendLocalIp + ":53317")
                              : i18n("Wi-Fi LAN")
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.6) : Qt.rgba(0, 0, 0, 0.55)
                    }
                }

                // Action Buttons Row (Send File Dialog & Launch App)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // 1. Direct File Picker Send Action
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 18
                        color: sendFileActionMouse.containsMouse ? Qt.darker(root.accentColor, 1.15) : root.accentColor

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Kirigami.Icon {
                                implicitWidth: 15
                                implicitHeight: 15
                                source: "document-send-symbolic"
                                fallback: Qt.resolvedUrl("../../icons/document-send-symbolic.svg")
                                isMask: true
                                color: root.accentTextColor
                            }

                            Text {
                                text: i18n("Send Files / Media…")
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: root.accentTextColor
                            }
                        }

                        MouseArea {
                            id: sendFileActionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sendLocalSendFileClicked()
                            }
                        }
                    }

                    // 2. Open LocalSend App
                    Rectangle {
                        implicitWidth: Math.max(90, openAppTxt.implicitWidth + 24)
                        implicitHeight: 36
                        radius: 18
                        color: openAppMouse.containsMouse
                               ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10))
                                : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Kirigami.Icon {
                                implicitWidth: 16
                                implicitHeight: 16
                                source: "org.localsend.localsend_app"
                                fallback: Qt.resolvedUrl("../../icons/document-send-symbolic.svg")
                            }

                            Text {
                                id: openAppTxt
                                text: i18n("Open App")
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            }
                        }

                        MouseArea {
                            id: openAppMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.openLocalSendClicked()
                            }
                        }
                    }
                }
            }
        }

        // Section Title for Devices List
        Text {
            visible: (root.isLocalSendMode || root.isSendFileMode) && (root.devicesModel && root.devicesModel.length > 0)
            text: i18n("Nearby LocalSend Devices")
            font.pixelSize: 12
            font.weight: Font.Bold
            color: root.accentColor
        }

        // Devices List (KDE Connect Devices or Discovered LocalSend Devices)
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
                color: (root.isLocalSendMode || root.isSendFileMode)
                       ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
                       : (modelData.paired ? (root.isDarkTheme ? Qt.rgba(53/255, 132/255, 228/255, 0.18) : Qt.rgba(53/255, 132/255, 228/255, 0.10))
                                           : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)))
                border.color: (root.isLocalSendMode || root.isSendFileMode)
                              ? (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06))
                              : (modelData.paired ? (root.isDarkTheme ? Qt.rgba(53/255, 132/255, 228/255, 0.5) : Qt.rgba(53/255, 132/255, 228/255, 0.3))
                                                  : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)))
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
                                    if (t === "phone" || t === "smartphone" || t === "mobile") return "phone-symbolic"
                                    return (root.isLocalSendMode || root.isSendFileMode) ? "document-send-symbolic" : "phone-symbolic"
                                }
                                isMask: true
                                color: root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
                            }
                        }

                        // Right action button: "Send" for LocalSend, "Pair/Unpair" for KDE Connect
                        Rectangle {
                            id: pairActionBtn
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: (root.isLocalSendMode || root.isSendFileMode) ? 70 : 72
                            height: 28
                            radius: 14
                            color: pairBtnMouse.containsMouse
                                   ? ((root.isLocalSendMode || root.isSendFileMode) ? Qt.darker(root.accentColor, 1.15) : (modelData.paired ? "#e74c3c" : root.accentColor))
                                   : ((root.isLocalSendMode || root.isSendFileMode) ? root.accentColor : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)))

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                Kirigami.Icon {
                                    visible: (root.isLocalSendMode || root.isSendFileMode)
                                    implicitWidth: 12
                                    implicitHeight: 12
                                    source: "document-send-symbolic"
                                    isMask: true
                                    color: (root.isLocalSendMode || root.isSendFileMode) ? root.accentTextColor : (pairBtnMouse.containsMouse ? root.accentTextColor : (root.isDarkTheme ? "#ffffff" : "#1a1a1a"))
                                }
                                Text {
                                    text: (root.isLocalSendMode || root.isSendFileMode) ? i18n("Send") : (modelData.paired ? "Unpair" : "Pair")
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: (root.isLocalSendMode || root.isSendFileMode) ? root.accentTextColor : (pairBtnMouse.containsMouse ? root.accentTextColor : (root.isDarkTheme ? "#ffffff" : "#1a1a1a"))
                                }
                            }

                            MouseArea {
                                id: pairBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.isLocalSendMode || root.isSendFileMode) {
                                        root.sendLocalSendFileClicked()
                                    } else if (modelData.paired) {
                                        root.unpairClicked(modelData.id)
                                    } else {
                                        root.pairClicked(modelData.id)
                                    }
                                }
                            }
                        }

                        // Device Name & Status / IP
                        ColumnLayout {
                            anchors.left: devBadge.right
                            anchors.leftMargin: 10
                            anchors.right: pairActionBtn.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: modelData.name || modelData.alias || i18n("Device")
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: {
                                    if (root.isLocalSendMode || root.isSendFileMode) {
                                        return modelData.ip ? (modelData.ip + (modelData.deviceModel ? (" • " + modelData.deviceModel) : "")) : i18n("LocalSend Peer")
                                    }
                                    if (modelData.reachable) {
                                        return (modelData.battery !== undefined && modelData.battery >= 0) ? (modelData.battery + "% Battery • Reachable") : i18n("Reachable")
                                    }
                                    return i18n("Disconnected")
                                }
                                font.pixelSize: 11
                                color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.6) : Qt.rgba(0, 0, 0, 0.55)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // In KDE Connect mode: Action Tiles Row (Ring, Share, SMS, Browse SFTP, Ping)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: !(root.isLocalSendMode || root.isSendFileMode)

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

                        // 2. Send File / Share Action
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
                                    text: "Share"
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

                        // 3. SMS Action
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

                        // 5. Send Ping Action
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
                                    source: "chat-message-new-symbolic"
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
                        source: (root.isLocalSendMode || root.isSendFileMode) ? "org.localsend.localsend_app" : "kdeconnect-symbolic"
                        fallback: (root.isLocalSendMode || root.isSendFileMode) ? Qt.resolvedUrl("../../icons/document-send-symbolic.svg") : ""
                        isMask: !(root.isLocalSendMode || root.isSendFileMode)
                        color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (root.isLocalSendMode || root.isSendFileMode) ? i18n("Local Wi-Fi Sharing Ready") : i18n("No Devices Found")
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: (root.isLocalSendMode || root.isSendFileMode)
                          ? i18n("LocalSend transfers files directly over your Wi-Fi network. Open LocalSend on your phone, tablet, or another computer to send and receive files instantly.")
                          : i18n("Make sure your phone or tablet has the KDE Connect app open and is connected to the same Wi-Fi network.")
                    font.pixelSize: 12
                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    spacing: 10

                    Rectangle {
                        implicitWidth: (root.isLocalSendMode || root.isSendFileMode) ? 170 : 160
                        implicitHeight: 34
                        radius: 17
                        color: pairNewMouse.containsMouse ? Qt.darker(root.accentColor, 1.15) : root.accentColor

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Kirigami.Icon {
                                implicitWidth: 14
                                implicitHeight: 14
                                source: (root.isLocalSendMode || root.isSendFileMode) ? "document-send-symbolic" : "kdeconnect-symbolic"
                                fallback: (root.isLocalSendMode || root.isSendFileMode) ? Qt.resolvedUrl("../../icons/document-send-symbolic.svg") : ""
                                isMask: true
                                color: root.accentTextColor
                            }

                            Text {
                                text: (root.isLocalSendMode || root.isSendFileMode) ? i18n("Choose Files to Send…") : i18n("Open KDE Connect")
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
                            onClicked: {
                                if (root.isLocalSendMode || root.isSendFileMode) {
                                    root.sendLocalSendFileClicked()
                                } else {
                                    root.openSettingsClicked()
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: (root.isLocalSendMode || root.isSendFileMode)
                        implicitWidth: 150
                        implicitHeight: 34
                        radius: 17
                        color: openAppSecMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06))

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Kirigami.Icon {
                                implicitWidth: 14
                                implicitHeight: 14
                                source: "org.localsend.localsend_app"
                                fallback: Qt.resolvedUrl("../../icons/document-send-symbolic.svg")
                            }

                            Text {
                                text: i18n("Open LocalSend")
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            }
                        }

                        MouseArea {
                            id: openAppSecMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openLocalSendClicked()
                        }
                    }
                }
            }
        }

        // Bottom Footer Button: Open LocalSend App / Configure KDE Connect
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
                    source: (root.isLocalSendMode || root.isSendFileMode) ? "org.localsend.localsend_app" : "kdeconnect-symbolic"
                    fallback: (root.isLocalSendMode || root.isSendFileMode) ? Qt.resolvedUrl("../../icons/document-send-symbolic.svg") : ""
                    isMask: !(root.isLocalSendMode || root.isSendFileMode)
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                Text {
                    text: (root.isLocalSendMode || root.isSendFileMode) ? i18n("Open LocalSend Application") : i18n("Configure KDE Connect")
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
                onClicked: {
                    if (root.isLocalSendMode || root.isSendFileMode) {
                        root.openLocalSendClicked()
                    } else {
                        root.openSettingsClicked()
                    }
                }
            }
        }
    }
}
