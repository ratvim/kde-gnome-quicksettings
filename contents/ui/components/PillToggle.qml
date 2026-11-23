import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

/**
 * PillToggle.qml - GNOME Quick Settings Toggle Button
 * Supports standard GNOME capsule pill (2 columns, icon + text + chevron)
 * as well as customizable compact icon shapes (Circle, Rounded Square, Water Drop, Squircle - 4 columns).
 */
Rectangle {
    id: root

    // Properties
    property string title: "Toggle"
    property string subtitle: "Off"
    property string iconName: "dialog-information"
    property string iconFallback: ""
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
    property color inactiveIconColor: isDarkTheme ? Qt.rgba(255, 255, 255, 0.65) : Qt.rgba(0, 0, 0, 0.45)
    property real pillRadius: 20
    property int iconSize: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileIconSize !== undefined) ? plasmoid.configuration.tileIconSize : 20

    property string toggleShape: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.toggleShape !== undefined && plasmoid.configuration.toggleShape !== "") ? plasmoid.configuration.toggleShape : "pill"
    readonly property bool isCompactShape: toggleShape !== "pill"

    signal toggled(bool newState)
    signal menuClicked()

    implicitWidth: 180
    implicitHeight: isCompactShape ? width : Math.max(56, root.iconSize + 36)
    height: implicitHeight

    radius: {
        if (root.toggleShape === "circle") return width / 2
        if (root.toggleShape === "rounded_square") return Math.round(width * 0.26)
        if (root.toggleShape === "water_drop") return 0
        return root.pillRadius
    }
    topLeftRadius: (root.toggleShape === "water_drop") ? (width / 2) : radius
    bottomLeftRadius: (root.toggleShape === "water_drop") ? (width / 2) : radius
    bottomRightRadius: (root.toggleShape === "water_drop") ? (width / 2) : radius
    topRightRadius: (root.toggleShape === "water_drop") ? Math.max(6, Math.round(width * 0.12)) : radius

    readonly property color effectiveBgColor: checked ? activeColor : (mouseArea.containsMouse ? (isDarkTheme ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.09)) : inactiveColor)
    readonly property color effectiveBorderColor: checked ? Qt.rgba(1, 1, 1, 0.15) : (isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.08))

    color: (root.toggleShape === "squircle") ? "transparent" : root.effectiveBgColor
    border.color: (root.toggleShape === "squircle") ? "transparent" : root.effectiveBorderColor
    border.width: (root.toggleShape === "squircle") ? 0 : 1

    scale: mouseArea.pressed ? 0.97 : (mouseArea.containsMouse ? 1.01 : 1.0)

    Behavior on color {
        ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
    }

    // Continuous Curvature Squircle Shape
    Shape {
        id: squircleShape
        anchors.fill: parent
        visible: root.isCompactShape && root.toggleShape === "squircle"
        layer.enabled: true
        layer.samples: 4
        ShapePath {
            strokeColor: root.effectiveBorderColor
            strokeWidth: 1
            fillColor: root.effectiveBgColor
            joinStyle: ShapePath.RoundJoin
            startX: root.width * 0.5
            startY: 1
            PathCubic {
                control1X: root.width * 0.72; control1Y: 1
                control2X: root.width - 1; control2Y: root.height * 0.28
                x: root.width - 1; y: root.height * 0.5
            }
            PathCubic {
                control1X: root.width - 1; control1Y: root.height * 0.72
                control2X: root.width * 0.72; control2Y: root.height - 1
                x: root.width * 0.5; y: root.height - 1
            }
            PathCubic {
                control1X: root.width * 0.28; control1Y: root.height - 1
                control2X: 1; control2Y: root.height * 0.72
                x: 1; y: root.height * 0.5
            }
            PathCubic {
                control1X: 1; control1Y: root.height * 0.28
                control2X: root.width * 0.28; control2Y: 1
                x: root.width * 0.5; y: 1
            }
        }
    }

    // Compact View (Icon-only, no text)
    Item {
        id: compactView
        anchors.fill: parent
        visible: root.isCompactShape

        Kirigami.Icon {
            id: compactIcon
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: (root.toggleShape === "water_drop") ? -1 : 0
            anchors.verticalCenterOffset: (root.toggleShape === "water_drop") ? 1 : 0
            implicitWidth: Math.max(22, Math.round(root.iconSize * 1.25))
            implicitHeight: implicitWidth
            source: root.iconName
            fallback: root.iconFallback
            color: root.checked ? root.activeTextColor : (mouseArea.containsMouse ? root.inactiveTextColor : root.inactiveIconColor)
            isMask: true
        }

        // Subtle menu indicator dot at bottom center if hasMenu is true
        Rectangle {
            visible: root.hasMenu
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.max(4, Math.round(root.height * 0.08))
            anchors.horizontalCenter: parent.horizontalCenter
            width: 4
            height: 4
            radius: 2
            color: root.checked ? Qt.rgba(root.activeTextColor.r, root.activeTextColor.g, root.activeTextColor.b, 0.7) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(0, 0, 0, 0.3))
        }
    }

    ToolTip {
        visible: root.isCompactShape && mouseArea.containsMouse
        delay: 350
        text: root.title + ((root.subtitle && root.subtitle !== "") ? (" • " + root.subtitle) : "")
    }

    // Standard Pill View (Icon badge, Title & Subtitle, optional Chevron)
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: root.hasMenu ? 4 : 14
        spacing: 10
        visible: !root.isCompactShape

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
                fallback: root.iconFallback
                color: root.checked ? root.activeTextColor : root.inactiveIconColor
                isMask: true
            }
        }

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

        Item {
            id: chevronContainer
            visible: root.hasMenu
            Layout.preferredWidth: 32
            Layout.preferredHeight: parent.height - 12
            Layout.alignment: Qt.AlignVCenter

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

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.rightMargin: (!root.isCompactShape && root.hasMenu) ? (chevronContainer.width + 4) : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.toggled(!root.checked)
                return
            }
            if (root.isCompactShape) {
                if (root.hasMenu) {
                    root.menuClicked()
                } else {
                    root.toggled(!root.checked)
                }
            } else {
                root.toggled(!root.checked)
            }
        }
    }
}
