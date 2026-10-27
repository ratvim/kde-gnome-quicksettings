import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * LocationView.qml - GNOME-style Location Privacy & Active Application Sub-View (Plasma 6)
 * Displays applications currently querying or accessing GeoClue / location services with stop controls.
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property bool locationEnabled: false
    property var locationApps: []

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"

    signal backClicked()
    signal toggleLocation()
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
                text: "Location Services"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
            }

            // Master Location Switch (On = Enabled, Off = Disabled)
            Switch {
                checked: root.locationEnabled
                onToggled: root.toggleLocation()
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
                if (!root.locationEnabled) {
                    return "Location services are turned off. Applications cannot access your geographic positioning."
                }
                if (root.locationApps && root.locationApps.length > 0) {
                    return "Applications currently querying or using location services:"
                }
                return "No applications are currently using location services."
            }
            font.pixelSize: 11
            color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            wrapMode: Text.WordWrap
        }

        // Applications List (when active apps exist and location is enabled)
        ListView {
            id: appsList
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: visible ? -1 : 0
            clip: true
            visible: root.locationEnabled && (root.locationApps && root.locationApps.length > 0)
            model: (root.locationEnabled && root.locationApps) ? root.locationApps : []
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
                        source: modelData.icon || "find-location-symbolic"
                        fallback: "find-location-symbolic"
                    }
                }

                // 2. Right Action Button (Stop or In Use) - rigidly anchored to parent.right
                Rectangle {
                    id: stopBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 64
                    height: 28
                    radius: 14
                    readonly property bool canStop: (modelData.pid && modelData.pid > 0)
                    color: {
                        if (!canStop) {
                            return root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.04)
                        }
                        return stopMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(0.9, 0.2, 0.2, 0.25) : Qt.rgba(0.9, 0.2, 0.2, 0.15))
                                                       : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))
                    }
                    border.color: (canStop && stopMouse.containsMouse) ? "#e01b24" : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: stopBtn.canStop ? "Stop" : "System"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: {
                            if (!stopBtn.canStop) {
                                return root.isDarkTheme ? "#9aa0a6" : "#606770"
                            }
                            return stopMouse.containsMouse ? "#ff5c57" : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
                        }
                    }

                    MouseArea {
                        id: stopMouse
                        anchors.fill: parent
                        hoverEnabled: stopBtn.canStop
                        cursorShape: stopBtn.canStop ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (stopBtn.canStop) {
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
                        text: modelData.name || "Location Application"
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
                            text: modelData.details || "Active"
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

        // Empty state when enabled but no apps active
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: visible ? -1 : 0
            visible: root.locationEnabled && (!root.locationApps || root.locationApps.length === 0)
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
                    source: "find-location-symbolic"
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
                    text: "No apps are currently querying or tracking location data."
                    font.pixelSize: 11
                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                }
            }
        }

        // State display when Location is Disabled
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: visible ? -1 : 0
            visible: !root.locationEnabled
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
                    source: "find-location-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.35
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Location Access is Disabled"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.8
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Flip the switch above to enable location services."
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
                text: "Refresh Location Apps"
                icon.name: "view-refresh-symbolic"
                onClicked: root.refreshClicked()
            }
        }
    }

    Component.onCompleted: root.refreshClicked()
}

