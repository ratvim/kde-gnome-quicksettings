import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

/**
 * StatusToolTip.qml - Sleek status preview popup for KDE panel capsule indicators
 * Floats cleanly above or below the panel without clipping, providing live status.
 * Dynamically positions:
 *  - Below capsule if panel is on TOP
 *  - Above capsule if panel is on BOTTOM ("down side")
 *  - To the RIGHT of capsule if panel is on LEFT
 *  - To the LEFT of capsule if panel is on RIGHT
 */
PlasmaComponents.ToolTip {
    id: root

    property string title: ""
    property string status: ""
    property string subStatus: ""
    property string iconName: ""
    property color iconColor: isDarkTheme ? "#f6f8fa" : "#1a1a1a"
    property bool showProgressBar: false
    property int progressValue: 0
    property color progressColor: "#3584e4"
    property bool isDarkTheme: true
    property bool isTopPanel: effectivePanelLocation === locTopEdge
    property int panelLocation: locTopEdge
    property Item capsuleItem: null

    readonly property int locTopEdge: (typeof PlasmaCore !== "undefined" && PlasmaCore.Types && PlasmaCore.Types.TopEdge !== undefined) ? PlasmaCore.Types.TopEdge : 3
    readonly property int locBottomEdge: (typeof PlasmaCore !== "undefined" && PlasmaCore.Types && PlasmaCore.Types.BottomEdge !== undefined) ? PlasmaCore.Types.BottomEdge : 4
    readonly property int locLeftEdge: (typeof PlasmaCore !== "undefined" && PlasmaCore.Types && PlasmaCore.Types.LeftEdge !== undefined) ? PlasmaCore.Types.LeftEdge : 5
    readonly property int locRightEdge: (typeof PlasmaCore !== "undefined" && PlasmaCore.Types && PlasmaCore.Types.RightEdge !== undefined) ? PlasmaCore.Types.RightEdge : 6

    readonly property int effectivePanelLocation: {
        if (panelLocation === locTopEdge ||
            panelLocation === locBottomEdge ||
            panelLocation === locLeftEdge ||
            panelLocation === locRightEdge) {
            return panelLocation
        }
        if (capsuleItem && capsuleItem.panelLocation !== undefined) {
            return capsuleItem.panelLocation
        }
        var cur = parent
        while (cur) {
            if (cur.panelLocation !== undefined) return cur.panelLocation
            cur = cur.parent
        }
        if (parent) {
            try {
                var pt = parent.mapToItem(null, 0, 0)
                var winH = (parent.Window && parent.Window.window) ? parent.Window.window.height : 0
                if (winH > 0 && pt.y < winH / 2) {
                    return locTopEdge
                }
            } catch (e) {}
        }
        return isTopPanel ? locTopEdge : locBottomEdge
    }

    function getCapsuleRectInParent() {
        if (capsuleItem && parent) {
            try {
                var pt = parent.mapFromItem(capsuleItem, 0, 0)
                return {
                    x: pt.x,
                    y: pt.y,
                    width: capsuleItem.width,
                    height: capsuleItem.height,
                    valid: true
                }
            } catch (e) {}
        }
        var pw = parent ? parent.width : 22
        var ph = parent ? parent.height : 22
        return {
            x: 0,
            y: 0,
            width: pw,
            height: ph,
            valid: false
        }
    }

    delay: 150
    timeout: -1

    x: {
        if (!parent) return 0
        var cap = getCapsuleRectInParent()
        var loc = effectivePanelLocation
        var spacing = 8

        if (loc === locLeftEdge) {
            // Panel on LEFT side of screen -> Tooltip placed to the RIGHT of capsule
            return Math.round(cap.x + cap.width + spacing)
        } else if (loc === locRightEdge) {
            // Panel on RIGHT side of screen -> Tooltip placed to the LEFT of capsule
            return Math.round(cap.x - implicitWidth - spacing)
        } else {
            // Panel on TOP or BOTTOM -> Horizontally centered relative to hovered icon
            var targetX = Math.round((parent.width - implicitWidth) / 2)
            if (parent.Window && parent.Window.window) {
                try {
                    var iconInWin = parent.mapToItem(null, 0, 0)
                    var winW = parent.Window.window.width
                    if (winW > 0) {
                        var absLeft = iconInWin.x + targetX
                        var absRight = absLeft + implicitWidth
                        if (absRight > winW - 12) {
                            targetX -= (absRight - (winW - 12))
                        }
                        if (absLeft < 12) {
                            targetX += (12 - absLeft)
                        }
                    }
                } catch (e) {}
            }
            return targetX
        }
    }

    y: {
        if (!parent) return 0
        var cap = getCapsuleRectInParent()
        var loc = effectivePanelLocation
        var spacing = 8

        if (loc === locTopEdge) {
            // Panel on TOP -> Tooltip placed BELOW the capsule
            return Math.round(cap.y + cap.height + spacing)
        } else if (loc === locLeftEdge || loc === locRightEdge) {
            // Panel on LEFT or RIGHT -> Tooltip vertically centered relative to hovered icon
            var targetY = Math.round((parent.height - implicitHeight) / 2)
            if (parent.Window && parent.Window.window) {
                try {
                    var iconInWin = parent.mapToItem(null, 0, 0)
                    var winH = parent.Window.window.height
                    if (winH > 0) {
                        var absTop = iconInWin.y + targetY
                        var absBottom = absTop + implicitHeight
                        if (absBottom > winH - 12) {
                            targetY -= (absBottom - (winH - 12))
                        }
                        if (absTop < 12) {
                            targetY += (12 - absTop)
                        }
                    }
                } catch (e) {}
            }
            return targetY
        } else {
            // Panel on BOTTOM ("down side of panel") -> Tooltip placed ABOVE the capsule
            return Math.round(cap.y - implicitHeight - spacing)
        }
    }

    margins: 0
    topPadding: 8
    bottomPadding: 8
    leftPadding: 12
    rightPadding: 12

    background: Rectangle {
        radius: 10
        color: root.isDarkTheme ? Qt.rgba(28/255, 28/255, 34/255, 0.96) : Qt.rgba(255/255, 255/255, 255/255, 0.96)
        border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(0, 0, 0, 0.14)
        border.width: 1
    }

    contentItem: Item {
        id: contentBox
        implicitWidth: Math.max(150, Math.min(280, mainCol.implicitWidth))
        implicitHeight: mainCol.implicitHeight

        ColumnLayout {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                Kirigami.Icon {
                    visible: Boolean(root.iconName && root.iconName !== "")
                    source: root.iconName
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    isMask: true
                    color: root.iconColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.title
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: root.isDarkTheme ? "#ffffff" : "#111111"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.maximumWidth: 250
                    }

                    Text {
                        visible: Boolean(root.status && root.status !== "")
                        text: root.status
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.82) : Qt.rgba(0, 0, 0, 0.80)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.maximumWidth: 250
                    }

                    Text {
                        visible: Boolean(root.subStatus && root.subStatus !== "")
                        text: root.subStatus
                        font.pixelSize: 10
                        color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.55) : Qt.rgba(0, 0, 0, 0.55)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.maximumWidth: 250
                    }
                }
            }

            // Mini status progress bar (Volume / Battery fill / Signal)
            Rectangle {
                visible: root.showProgressBar
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(0, 0, 0, 0.12)
                clip: true

                Rectangle {
                    width: Math.max(0, Math.min(parent.width, Math.round(parent.width * (Math.max(0, Math.min(100, root.progressValue)) / 100))))
                    height: parent.height
                    radius: 2
                    color: root.progressColor
                }
            }
        }
    }
}
