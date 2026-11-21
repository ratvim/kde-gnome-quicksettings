import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * LocalSendView.qml - Dedicated Send Local (LocalSend) device & file transfer sub-view (Plasma 6)
 * Features:
 *   - Local Wi-Fi cross-platform file transfer
 *   - Live LocalSend daemon status detection (Port 53317 & LAN IP)
 *   - Direct "Send Files / Media…" trigger invoking native KDE kdialog file picker
 *   - Instant launcher for the LocalSend desktop application
 *   - Discovered nearby LocalSend peers across the local network
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
    signal openLocalSendClicked()
    signal sendLocalSendFileClicked(string filePath)

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header with Back, Title, Refresh, and App Launch Button
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
                text: i18n("Send Local")
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

            // Launch LocalSend App Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: appBtnMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "org.localsend.localsend_app"
                    fallback: Qt.resolvedUrl("../../icons/document-send-symbolic.svg")
                }

                MouseArea {
                    id: appBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openLocalSendClicked()
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
        // LocalSend Network & Daemon Status Card
        // =========================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: lsCardCol.implicitHeight + 20
            radius: 14
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
                              : i18n("Port 53317 (LAN)")
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
                            onClicked: root.sendLocalSendFileClicked("")
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
                            onClicked: root.openLocalSendClicked()
                        }
                    }
                }
            }
        }

        // Section Title for Devices List
        Text {
            visible: (root.devicesModel && root.devicesModel.length > 0)
            text: i18n("Nearby LocalSend Devices")
            font.pixelSize: 12
            font.weight: Font.Bold
            color: root.accentColor
        }

        // List of Nearby Discovered LocalSend Devices
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: root.devicesModel

            delegate: Rectangle {
                id: deviceCard
                width: listView.width
                implicitHeight: cardCol.implicitHeight + 20
                radius: 14
                color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
                border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
                border.width: 1

                ColumnLayout {
                    id: cardCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // Device Header Info
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Kirigami.Icon {
                            implicitWidth: 24
                            implicitHeight: 24
                            source: {
                                var t = (modelData.type || modelData.deviceType || "").toLowerCase()
                                if (t === "tablet") return "tablet-symbolic"
                                if (t === "laptop" || t === "desktop" || t === "computer") return "computer-symbolic"
                                return "phone-symbolic"
                            }
                            fallback: Qt.resolvedUrl("../../icons/phone-symbolic.svg")
                            isMask: true
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.name || modelData.alias || modelData.ip || i18n("Nearby Device")
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: (modelData.ip ? modelData.ip : "") + (modelData.deviceModel ? (" • " + modelData.deviceModel) : "")
                                font.pixelSize: 11
                                color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Send File directly to this peer
                        Rectangle {
                            implicitWidth: 64
                            implicitHeight: 30
                            radius: 15
                            color: sendPeerMouse.containsMouse ? Qt.darker(root.accentColor, 1.15) : root.accentColor

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Kirigami.Icon {
                                    implicitWidth: 12
                                    implicitHeight: 12
                                    source: "document-send-symbolic"
                                    fallback: Qt.resolvedUrl("../../icons/document-send-symbolic.svg")
                                    isMask: true
                                    color: root.accentTextColor
                                }

                                Text {
                                    text: i18n("Send")
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: root.accentTextColor
                                }
                            }

                            MouseArea {
                                id: sendPeerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.sendLocalSendFileClicked("")
                            }
                        }
                    }
                }
            }
        }

        // Empty state when no nearby peers are discovered
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: (!root.devicesModel || root.devicesModel.length === 0)
            alignment: Qt.AlignCenter
            spacing: 12

            Kirigami.Icon {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 48
                implicitHeight: 48
                source: "org.localsend.localsend_app"
                fallback: Qt.resolvedUrl("../../icons/document-send-symbolic.svg")
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("No Nearby LocalSend Devices")
                font.pixelSize: 14
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: i18n("LocalSend transfers files directly over your Wi-Fi network. Open LocalSend on your phone, tablet, or another computer to send and receive files instantly.")
                font.pixelSize: 12
                color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                spacing: 10

                Rectangle {
                    implicitWidth: 170
                    implicitHeight: 34
                    radius: 17
                    color: pickFileMouse.containsMouse ? Qt.darker(root.accentColor, 1.15) : root.accentColor

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Kirigami.Icon {
                            implicitWidth: 14
                            implicitHeight: 14
                            source: "document-send-symbolic"
                            fallback: Qt.resolvedUrl("../../icons/document-send-symbolic.svg")
                            isMask: true
                            color: root.accentTextColor
                        }

                        Text {
                            text: i18n("Choose Files to Send…")
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.accentTextColor
                        }
                    }

                    MouseArea {
                        id: pickFileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sendLocalSendFileClicked("")
                    }
                }

                Rectangle {
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

        // Bottom Footer Button: Open LocalSend App
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
                    source: "org.localsend.localsend_app"
                    fallback: Qt.resolvedUrl("../../icons/document-send-symbolic.svg")
                }

                Text {
                    text: i18n("Open LocalSend Application")
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
                onClicked: root.openLocalSendClicked()
            }
        }
    }
}
