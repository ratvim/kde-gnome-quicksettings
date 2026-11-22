import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * LocalSendView.qml - Clean, professional Send Local (LocalSend) device & file transfer sub-view
 * Designed strictly to KDE Plasma 6 & GNOME HIG: zero duplicate buttons, clear status, direct peer sending.
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
    signal sendToPeerClicked(string peerIp, int peerPort, string peerName)

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header: Back Navigation, Title, and Refresh Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
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
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
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
        }

        // Subtle Section Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }

        // Service & Network Status Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 54
            radius: 12
            color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
            border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                // Status Indicator Dot
                Rectangle {
                    Layout.preferredWidth: 10
                    Layout.preferredHeight: 10
                    radius: 5
                    color: (root.backend && root.backend.localsendRunning) ? "#2ecc71" : "#9aa0a6"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: (backend && backend.localsendRunning)
                              ? i18n("LocalSend is Active")
                              : i18n("LocalSend is Inactive")
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    }

                    Text {
                        text: (backend && backend.localsendRunning)
                              ? ((backend.localsendLocalIp ? (backend.localsendLocalIp + " : 53317 • ") : "") + i18n("Wi-Fi LAN"))
                              : i18n("Service is not running")
                        font.pixelSize: 11
                        color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.6) : Qt.rgba(0, 0, 0, 0.55)
                    }
                }

                // Quick Start button if stopped
                Rectangle {
                    visible: Boolean(backend && !backend.localsendRunning)
                    implicitWidth: 70
                    implicitHeight: 28
                    radius: 14
                    color: startMouse.containsMouse ? Qt.darker(root.accentColor, 1.15) : root.accentColor

                    Text {
                        anchors.centerIn: parent
                        text: i18n("Start")
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: root.accentTextColor
                    }

                    MouseArea {
                        id: startMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openLocalSendClicked()
                    }
                }
            }
        }

        // Section Title: Nearby Devices
        Text {
            visible: Boolean(root.devicesModel && root.devicesModel.length > 0)
            text: i18n("Nearby Devices")
            font.pixelSize: 12
            font.weight: Font.Bold
            color: root.accentColor
        }

        // Discovered Nearby Peers List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            visible: Boolean(root.devicesModel && root.devicesModel.length > 0)
            model: root.devicesModel

            delegate: Rectangle {
                id: deviceCard
                width: listView.width
                implicitHeight: 56
                radius: 12
                color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
                border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Kirigami.Icon {
                        implicitWidth: 22
                        implicitHeight: 22
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
                        spacing: 1

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

                    // Direct Send Button for this specific peer
                    Rectangle {
                        implicitWidth: 72
                        implicitHeight: 28
                        radius: 14
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
                            onClicked: {
                                root.sendToPeerClicked(modelData.ip || "", modelData.port || 53317, modelData.name || modelData.alias || "")
                            }
                        }
                    }
                }
            }
        }

        // Clean Empty State when no peers are discovered (Zero redundant buttons)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: (!root.devicesModel || root.devicesModel.length === 0)

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 10

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 44
                    implicitHeight: 44
                    source: "org.localsend.localsend_app"
                    fallback: Qt.resolvedUrl("../../icons/document-send-symbolic.svg")
                    opacity: 0.65
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("No Nearby Devices Discovered")
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: i18n("LocalSend transfers files securely over your local network. Make sure other devices on this Wi-Fi network have LocalSend open.")
                    font.pixelSize: 11
                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                }
            }
        }

        // Single Bottom Footer Button: Open / Launch LocalSend
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
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
                    text: (backend && backend.localsendRunning) ? i18n("Open LocalSend Window") : i18n("Launch LocalSend Application")
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
