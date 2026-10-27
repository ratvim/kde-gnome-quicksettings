import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * PillToggle.qml - GNOME-style curved-edge capsule toggle button
 * Features:
 *   - Capsule/pill button shape with rounded corners (radius: 18..22px)
 *   - Glassmorphic inactive state / Dynamic KDE system accent or GNOME blue active state
 *   - Native system icon via Kirigami.Icon with bundled SVG fallback
 *   - Independent chevron button for sub-menus (e.g. Wi-Fi / Bluetooth)
 *   - Press scale micro-interaction and smooth color transitions
 */
Rectangle {
    id: root

    // Properties
    property string title: "Toggle"
    property string subtitle: "Off"
    property string iconName: "dialog-information"
    property bool checked: false
    property bool hasMenu: false
    property bool isDarkTheme: true
    property color activeColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"
    property color activeTextColor: (Kirigami.Theme.highlightedTextColor !== undefined && Kirigami.Theme.highlightedTextColor.a > 0) ? Kirigami.Theme.highlightedTextColor : "#ffffff"
    property color inactiveColor: isDarkTheme ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.06)
    property color inactiveTextColor: isDarkTheme ? "#f6f8fa" : "#1a1a1a"
    property color inactiveSubtextColor: isDarkTheme ? "#9aa0a6" : "#606770"
    property color inactiveIconBg: isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
    property color activeIconBg: Qt.rgba(1, 1, 1, 0.22)
    property real pillRadius: 20
    property int iconSize: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileIconSize !== undefined) ? plasmoid.configuration.tileIconSize : 20

    signal toggled(bool newState)
    signal menuClicked()

    implicitWidth: 180
    implicitHeight: Math.max(56, root.iconSize + 36)
    radius: pillRadius

    // Smooth color & scale animations
    color: checked ? activeColor : (mouseArea.containsMouse ? (isDarkTheme ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.09)) : inactiveColor)
    border.color: checked ? Qt.rgba(1, 1, 1, 0.15) : (isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.08))
    border.width: 1

    scale: mouseArea.pressed ? 0.97 : (mouseArea.containsMouse ? 1.01 : 1.0)

    Behavior on color {
        ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: root.hasMenu ? 4 : 14
        spacing: 10

        // Circular Icon Badge
        Rectangle {
            id: iconBadge
            Layout.preferredWidth: Math.max(36, root.iconSize + 16)
            Layout.preferredHeight: Math.max(36, root.iconSize + 16)
            Layout.alignment: Qt.AlignVCenter
            radius: Layout.preferredWidth / 2
            color: root.checked ? root.activeIconBg : root.inactiveIconBg

            Behavior on color {
                ColorAnimation { duration: 180 }
            }

            Kirigami.Icon {
                id: kirigamiIcon
                anchors.centerIn: parent
                implicitWidth: root.iconSize
                implicitHeight: root.iconSize
                source: root.iconName
                color: root.checked ? root.activeTextColor : root.inactiveTextColor
                isMask: true
            }
        }

        // Title and Subtitle Text Column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.checked ? root.activeTextColor : root.inactiveTextColor
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.subtitle
                font.pixelSize: 11
                color: root.checked ? root.activeTextColor : root.inactiveSubtextColor
                opacity: root.checked ? 0.85 : 1.0
                elide: Text.ElideRight
            }
        }

        // Optional Chevron Split-Button for opening Sub-Menus (Wi-Fi, Bluetooth)
        Item {
            id: chevronContainer
            visible: root.hasMenu
            Layout.preferredWidth: 32
            Layout.preferredHeight: parent.height - 12
            Layout.alignment: Qt.AlignVCenter

            // Vertical divider line
            Rectangle {
                width: 1
                height: 20
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: root.checked ? Qt.rgba(1, 1, 1, 0.25) : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.1))
            }

            Rectangle {
                id: chevronBg
                anchors.fill: parent
                anchors.leftMargin: 2
                radius: 16
                color: chevronMouse.containsMouse ? (root.checked ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.1)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: "go-next-symbolic"
                    isMask: true
                    color: root.checked ? root.activeTextColor : root.inactiveSubtextColor
                }

                MouseArea {
                    id: chevronMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuClicked()
                    }
                }
            }
        }
    }

    // Main Toggle MouseArea (covers the pill except the chevron button)
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.rightMargin: root.hasMenu ? chevronContainer.width + 4 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.toggled(!root.checked)
        }
    }
}
