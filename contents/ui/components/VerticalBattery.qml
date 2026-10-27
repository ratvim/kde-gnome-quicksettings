import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * VerticalBattery.qml - Standing upright vertical battery indicator
 * Features:
 *   - Standing upright orientation (terminal cap at top)
 *   - Proportional vertical level fill from bottom to top
 *   - Distinct color thresholds: Green (charging), Red (<= 20% discharging), White/Dark (normal)
 *   - Vector lightning bolt indicator when charging
 */
Item {
    id: root

    property int level: 85
    property bool charging: false
    property bool isDarkTheme: true
    property color normalColor: isDarkTheme ? "#f6f8fa" : "#1a1a1a"
    property color lowColor: "#e74c3c"
    property color chargingColor: "#2ec27e"

    // Sizing
    property int batteryHeight: 18
    property int batteryWidth: Math.round(batteryHeight * 0.58) // ~10px for 18px height

    implicitWidth: batteryWidth
    implicitHeight: batteryHeight
    width: batteryWidth
    height: batteryHeight

    readonly property color currentFillColor: {
        if (root.charging) return root.chargingColor
        if (root.level <= 20) return root.lowColor
        return root.normalColor
    }

    readonly property color borderColor: {
        if (root.charging) return Qt.rgba(root.chargingColor.r, root.chargingColor.g, root.chargingColor.b, 0.7)
        if (root.level <= 20) return Qt.rgba(root.lowColor.r, root.lowColor.g, root.lowColor.b, 0.8)
        return root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.4)
    }

    Column {
        anchors.centerIn: parent
        spacing: 1

        // Top Terminal Nub (Standing battery cap)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(3, Math.round(root.batteryWidth * 0.42))
            height: 2
            radius: 1
            color: root.borderColor
        }

        // Main Battery Body Container
        Rectangle {
            id: bodyRect
            width: root.batteryWidth
            height: root.batteryHeight - 3
            radius: 2.5
            color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
            border.color: root.borderColor
            border.width: 1
            clip: true

            // Bottom-up Battery Fill Level
            Rectangle {
                id: fillRect
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1.5
                radius: 1.5

                readonly property real pct: Math.max(0.05, Math.min(1.0, root.level / 100.0))
                height: Math.max(2, Math.round((bodyRect.height - 3) * pct))
                color: root.currentFillColor

                Behavior on height {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }

            // Centered Vector Lightning Bolt for Charging
            Kirigami.Icon {
                anchors.centerIn: parent
                visible: root.charging
                width: Math.max(8, root.batteryWidth - 2)
                height: Math.max(8, root.batteryWidth - 2)
                source: "battery-charging-symbolic"
                fallback: "media-flash-symbolic"
                isMask: true
                color: root.isDarkTheme ? "#1a1a1a" : "#ffffff"
                z: 2
            }
        }
    }
}
