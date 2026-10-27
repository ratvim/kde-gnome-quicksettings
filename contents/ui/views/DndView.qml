import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * DndView.qml - GNOME-style Do Not Disturb Mode Sub-View (Plasma 6)
 * Supports duration options matching the native KDE Plasma Notification widget:
 *   - Until turned off (until manually disabled)
 *   - For 1 hour
 *   - For 4 hours
 *   - Until this evening / Until tomorrow morning
 *   - Until tomorrow morning
 *   - Until Monday (during weekends)
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property bool dndEnabled: false
    property string dndMode: "until_off"
    property string dndUntilText: ""

    signal backClicked()
    signal toggleDnd(bool enabled)
    signal selectOption(string mode)

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"

    color: "transparent"

    function getFormattedEndTime(hoursToAdd) {
        var d = new Date()
        d.setHours(d.getHours() + hoursToAdd)
        var h = d.getHours()
        var m = d.getMinutes()
        return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m)
    }

    readonly property var dndOptions: {
        var now = new Date()
        var curH = now.getHours()
        var curDay = now.getDay() // 0=Sun, 1=Mon, ..., 5=Fri, 6=Sat

        var list = [
            {
                key: "until_off",
                title: "Until turned off",
                desc: "Stay muted until manually disabled",
                icon: "notifications-disabled-symbolic"
            },
            {
                key: "1h",
                title: "For 1 hour",
                desc: "Ends at " + getFormattedEndTime(1),
                icon: "chronometer-symbolic"
            },
            {
                key: "4h",
                title: "For 4 hours",
                desc: "Ends at " + getFormattedEndTime(4),
                icon: "chronometer-symbolic"
            }
        ]

        if (curH < 18) {
            list.push({
                key: "evening",
                title: "Until this evening",
                desc: "Ends at 18:00 today",
                icon: "weather-clear-night-symbolic"
            })
        }

        list.push({
            key: "tomorrow",
            title: "Until tomorrow morning",
            desc: "Ends tomorrow at 07:00",
            icon: "weather-clear-night-symbolic"
        })

        if (curDay === 5 || curDay === 6 || curDay === 0) { // Fri, Sat, Sun
            list.push({
                key: "monday",
                title: "Until Monday morning",
                desc: "Ends Monday at 07:00",
                icon: "view-calendar-symbolic"
            })
        }

        return list
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // 1. Header with Back Button & Master Privacy Switch on Top Right
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
                text: "Do Not Disturb"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
            }

            // Master Switch placed at top right consistent with Camera, Mic, Location, Hotspot
            Switch {
                checked: root.dndEnabled
                onToggled: root.toggleDnd(checked)
            }
        }

        // 2. Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }

        // 3. Subtitle explanation
        Text {
            Layout.fillWidth: true
            text: {
                if (root.dndEnabled) {
                    return root.dndUntilText ? root.dndUntilText : "Notifications and popups are muted."
                }
                return "Allow all notifications and alert sounds."
            }
            font.pixelSize: 11
            color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            wrapMode: Text.WordWrap
        }

        // 4. Section Title when Enabled
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 2
            text: "MUTE NOTIFICATIONS FOR"
            font.pixelSize: 11
            font.weight: Font.Bold
            color: root.accentColor
            visible: root.dndEnabled
        }

        // 5. Options List (when DND is enabled)
        ListView {
            id: optionsList
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: visible ? -1 : 0
            clip: true
            spacing: 6
            visible: root.dndEnabled
            model: root.dndEnabled ? root.dndOptions : []

            delegate: Rectangle {
                id: optionCard
                width: optionsList.width
                height: 52
                radius: 12

                readonly property bool isSelected: root.dndEnabled && (root.dndMode === modelData.key)

                color: isSelected ? (root.isDarkTheme ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22) : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12))
                                   : (optMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.06)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03)))
                border.color: isSelected ? root.accentColor : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06))
                border.width: 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                // Left Option Icon
                Kirigami.Icon {
                    id: optIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    source: modelData.icon
                    isMask: true
                    color: optionCard.isSelected ? root.accentColor : (root.isDarkTheme ? "#9aa0a6" : "#606770")
                }

                // Radio / Check Indicator - anchored to the right edge
                Rectangle {
                    id: optIndicator
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: optionCard.isSelected ? root.accentColor : "transparent"
                    border.color: optionCard.isSelected ? root.accentColor : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(0, 0, 0, 0.3))
                    border.width: optionCard.isSelected ? 0 : 2

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        source: "emblem-ok-symbolic"
                        isMask: true
                        color: "#ffffff"
                        visible: optionCard.isSelected
                    }
                }

                // Text Column in the middle
                Column {
                    anchors.left: optIcon.right
                    anchors.leftMargin: 12
                    anchors.right: optIndicator.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: modelData.title
                        width: parent.width
                        elide: Text.ElideRight
                        font.pixelSize: 12
                        font.weight: optionCard.isSelected ? Font.Bold : Font.Medium
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    }

                    Text {
                        text: modelData.desc
                        width: parent.width
                        elide: Text.ElideRight
                        font.pixelSize: 10
                        color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                    }
                }

                MouseArea {
                    id: optMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectOption(modelData.key)
                    }
                }
            }
        }

        // 6. Inactive State Card (when DND is OFF)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: visible ? -1 : 0
            visible: !root.dndEnabled
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
                    source: "notifications-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.35
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Notifications Allowed"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    opacity: 0.8
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Flip the switch above to silence notifications and sounds."
                    font.pixelSize: 11
                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleDnd(true)
            }
        }
    }
}
