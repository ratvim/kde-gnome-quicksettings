import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * NetworkView.qml - GNOME-style Wi-Fi network selection sub-view (Plasma 6)
 * Uses real system icons via Kirigami.Icon with bundled SVG fallback.
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property bool wifiEnabled: true
    property bool hotspotEnabled: false
    property string activeSsid: ""
    property var networksModel: []

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"
    readonly property color accentTextColor: (Kirigami.Theme.highlightedTextColor !== undefined && Kirigami.Theme.highlightedTextColor.a > 0) ? Kirigami.Theme.highlightedTextColor : "#ffffff"

    signal backClicked()
    signal toggleWifi(bool enabled)
    signal connectToSsid(string ssid)
    signal refreshClicked()

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header with Back button
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
                text: "Wi-Fi Networks"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
            }

            // Wi-Fi Master Switch
            Switch {
                checked: root.wifiEnabled
                onToggled: root.toggleWifi(checked)
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }

        // Network List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.wifiEnabled ? root.networksModel : []
            spacing: 6

            delegate: Rectangle {
                id: netCard
                width: listView.width
                height: 52
                radius: 14
                color: modelData.active ? (root.isDarkTheme ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22) : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12))
                                       : (itemMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")
                border.color: modelData.active ? root.accentColor : "transparent"
                border.width: modelData.active ? 1 : 0

                // 1. Left Network Signal Icon
                Kirigami.Icon {
                    id: netIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    source: {
                        var s = parseInt(modelData.signal) || 0
                        if (s >= 75) return "network-wireless-signal-excellent-symbolic"
                        if (s >= 50) return "network-wireless-signal-good-symbolic"
                        if (s >= 25) return "network-wireless-signal-ok-symbolic"
                        if (s > 0) return "network-wireless-signal-weak-symbolic"
                        return "network-wireless-signal-none-symbolic"
                    }
                    isMask: true
                    color: modelData.active ? root.accentColor : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
                }

                // 2. Right Action Container - locked rigidly to parent.right to guarantee 100% vertical alignment across all rows
                Item {
                    id: netActionContainer
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 72
                    height: 28

                    // Inactive Network: Connect Pill Button
                    Rectangle {
                        anchors.fill: parent
                        visible: !modelData.active
                        radius: 14
                        color: connMouse.containsMouse ? root.accentColor : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: connMouse.containsMouse ? root.accentTextColor : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
                        }

                        MouseArea {
                            id: connMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.connectToSsid(modelData.ssid)
                        }
                    }

                    // Active Network: Checkmark Indicator centered in action container
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        visible: modelData.active
                        width: 18
                        height: 18
                        source: "emblem-ok-symbolic"
                        isMask: true
                        color: root.accentColor
                    }
                }

                // 3. Middle Text Column: bound between netIcon and netActionContainer with explicit elide
                Column {
                    anchors.left: netIcon.right
                    anchors.leftMargin: 12
                    anchors.right: netActionContainer.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: modelData.ssid || "Unknown Network"
                        font.pixelSize: 13
                        font.weight: modelData.active ? Font.DemiBold : Font.Normal
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: modelData.active ? "Connected" : ((modelData.security || "Open") + " • Signal: " + modelData.signal + "%")
                        font.pixelSize: 10
                        color: modelData.active ? root.accentColor : (root.isDarkTheme ? "#9aa0a6" : "#606770")
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    anchors.rightMargin: 86
                    hoverEnabled: true
                    cursorShape: modelData.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (!modelData.active) {
                            root.connectToSsid(modelData.ssid)
                        }
                    }
                }
            }
        }

        // Inactive State Card (when Wi-Fi is disabled)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.wifiEnabled
            color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.02)
            radius: 14
            border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                width: parent.width - 40

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    width: 36
                    height: 36
                    source: "network-wireless-offline-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.35
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.hotspotEnabled ? "Wi-Fi Hotspot is Active" : "Wi-Fi is Turned Off"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.8
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.hotspotEnabled
                          ? "Turn on Wi-Fi above to disable Hotspot and connect to Wi-Fi networks."
                          : "Turn on Wi-Fi using the switch above to view available networks."
                    font.pixelSize: 11
                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // Empty state message when list is empty
        Text {
            visible: root.wifiEnabled && (!root.networksModel || root.networksModel.length === 0)
            text: "Scanning for nearby networks..."
            font.pixelSize: 12
            color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            Layout.alignment: Qt.AlignHCenter
        }

        // Footer Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.wifiEnabled

            Button {
                Layout.fillWidth: true
                text: "Refresh Networks"
                onClicked: root.refreshClicked()
            }
        }
    }

    Component.onCompleted: root.refreshClicked()
    onVisibleChanged: {
        if (visible) {
            root.refreshClicked()
        }
    }
}
