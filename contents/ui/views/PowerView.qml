import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * PowerView.qml - GNOME-style Power Mode Sub-View (Plasma 6)
 * Supports Performance, Balanced, and Optimise (Power Saver) profiles.
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property string currentProfile: "balanced"

    signal backClicked()
    signal selectProfile(string profile)

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header with Back Button
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
                text: "Power Mode"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }

        Text {
            Layout.fillWidth: true
            text: "Affects system performance, fan noise, and battery life."
            font.pixelSize: 11
            color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            wrapMode: Text.WordWrap
        }

        // Profile List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8

            model: [
                {
                    key: "performance",
                    name: "Performance",
                    desc: "High performance and greater power consumption",
                    icon: "battery-profile-performance-symbolic"
                },
                {
                    key: "balanced",
                    name: "Balanced",
                    desc: "Standard performance and balanced power usage",
                    icon: "battery-profile-balanced-symbolic"
                },
                {
                    key: "power-saver",
                    name: "Optimise",
                    desc: "Reduced performance for improved battery life",
                    icon: "battery-profile-powersave-symbolic"
                }
            ]

            delegate: Rectangle {
                id: itemCard
                width: listView.width
                height: 64
                radius: 14

                readonly property bool isSelected: root.currentProfile === modelData.key

                color: isSelected ? (root.isDarkTheme ? Qt.rgba(53/255, 132/255, 228/255, 0.22) : Qt.rgba(53/255, 132/255, 228/255, 0.12))
                                   : (itemMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.06)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03)))
                border.color: isSelected ? root.accentColor : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06))
                border.width: 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                // 1. Icon badge
                Rectangle {
                    id: pwrIconBadge
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    height: 38
                    radius: 19
                    color: itemCard.isSelected ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                                               : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: modelData.icon
                        isMask: true
                        color: itemCard.isSelected ? root.accentColor : (root.isDarkTheme ? "#f6f8fa" : "#1a1a1a")
                    }
                }

                // 2. Radio indicator - anchored rigidly to right edge (rightMargin: 14 to match DndView perfectly)
                Rectangle {
                    id: pwrIndicator
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: "transparent"
                    border.color: itemCard.isSelected ? root.accentColor : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(0, 0, 0, 0.3))
                    border.width: 2

                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        radius: 5
                        color: root.accentColor
                        visible: itemCard.isSelected
                    }
                }

                // 3. Middle Text Column: bound between pwrIconBadge and pwrIndicator with explicit elide
                Column {
                    anchors.left: pwrIconBadge.right
                    anchors.leftMargin: 12
                    anchors.right: pwrIndicator.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: modelData.name
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: modelData.desc
                        font.pixelSize: 11
                        color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectProfile(modelData.key)
                    }
                }
            }
        }
    }
}

