import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * BluetoothView.qml - GNOME-style Bluetooth device management sub-view (Plasma 6)
 * Uses real system icons via Kirigami.Icon with bundled SVG fallback.
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property bool btEnabled: true
    property var devicesModel: []
    property bool isScanning: false

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"
    readonly property color accentTextColor: (Kirigami.Theme.highlightedTextColor !== undefined && Kirigami.Theme.highlightedTextColor.a > 0) ? Kirigami.Theme.highlightedTextColor : "#ffffff"

    signal backClicked()
    signal toggleBt(bool enabled)
    signal toggleConnectDevice(string mac, bool currentlyConnected)
    signal pairClicked(string mac)
    signal openSettingsClicked()
    signal scanClicked()

    function handleDeviceClick(mac, connected, paired) {
        if (connected) {
            root.toggleConnectDevice(mac, true)
        } else if (paired) {
            root.toggleConnectDevice(mac, false)
        } else {
            root.pairClicked(mac)
        }
    }

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
                text: "Bluetooth Devices"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
            }

            // Bluetooth Master Switch
            Switch {
                checked: root.btEnabled
                onToggled: root.toggleBt(checked)
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
            model: root.btEnabled ? root.devicesModel : []
            spacing: 6

            delegate: Rectangle {
                id: devCard
                width: listView.width
                height: 52
                radius: 14
                color: modelData.connected ? (root.isDarkTheme ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22) : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12))
                                           : (itemMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")
                border.color: modelData.connected ? root.accentColor : "transparent"
                border.width: modelData.connected ? 1 : 0

                // 1. Left Device Icon
                Kirigami.Icon {
                    id: devIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    source: {
                        if (modelData.type === "audio-headphones") return "audio-headphones-symbolic"
                        if (modelData.type === "phone") return "phone-symbolic"
                        if (modelData.type === "input-mouse") return "input-mouse-symbolic"
                        if (modelData.type === "input-keyboard") return "input-keyboard-symbolic"
                        if (modelData.type === "audio-speakers") return "audio-volume-high-symbolic"
                        return "network-bluetooth-symbolic"
                    }
                    isMask: true
                    color: modelData.connected ? root.accentColor : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
                }

                // 2. Right Action Button (Connect / Disconnect / Pair) - locked rigidly to parent.right
                Rectangle {
                    id: devActionBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 80
                    height: 28
                    radius: 14
                    color: btnMouse.containsMouse ? (modelData.connected ? "#e74c3c" : root.accentColor)
                                                  : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))

                    Text {
                        anchors.centerIn: parent
                        text: modelData.connected ? "Disconnect" : (modelData.paired ? "Connect" : "Pair")
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: btnMouse.containsMouse ? root.accentTextColor : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.handleDeviceClick(modelData.mac, modelData.connected, modelData.paired)
                    }
                }

                // 3. Middle Text Column: bound between devIcon and devActionBtn with explicit elide
                Column {
                    anchors.left: devIcon.right
                    anchors.leftMargin: 12
                    anchors.right: devActionBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: modelData.name || "Bluetooth Device"
                        font.pixelSize: 13
                        font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        elide: Text.ElideRight
                    }

                    Row {
                        width: parent.width
                        spacing: 5

                        Text {
                            text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "Available")
                            font.pixelSize: 11
                            font.weight: modelData.connected ? Font.Medium : Font.Normal
                            color: modelData.connected ? root.accentColor : (root.isDarkTheme ? "#9aa0a6" : "#606770")
                        }

                        // Dedicated Battery Pill
                        Row {
                            visible: modelData.connected && (modelData.battery !== undefined && modelData.battery > 0)
                            spacing: 3
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "•"
                                font.pixelSize: 11
                                color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                            }

                            Kirigami.Icon {
                                width: 13
                                height: 13
                                anchors.verticalCenter: parent.verticalCenter
                                source: {
                                    var b = modelData.battery || 0
                                    var step = Math.max(0, Math.min(100, Math.round(b / 10) * 10))
                                    return "battery-" + ("000" + step).slice(-3)
                                }
                            }

                            Text {
                                text: modelData.battery + "%"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: modelData.battery <= 20 ? "#e74c3c" : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
                            }
                        }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    anchors.rightMargin: 94
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.handleDeviceClick(modelData.mac, modelData.connected, modelData.paired)
                }
            }
        }

        // Empty state message when list is empty
        Text {
            visible: root.btEnabled && (!root.devicesModel || root.devicesModel.length === 0)
            text: "No paired Bluetooth devices found\nClick 'Pair New Device' to add a device"
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 12
            color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            Layout.alignment: Qt.AlignHCenter
        }

        // Footer Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                Layout.fillWidth: true
                text: "Pair New Device"
                icon.name: "list-add-symbolic"
                enabled: root.btEnabled
                onClicked: root.openSettingsClicked()
            }
        }
    }

    Component.onCompleted: root.scanClicked()
}
