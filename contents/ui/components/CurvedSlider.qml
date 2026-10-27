import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * CurvedSlider.qml - GNOME-style curved pill slider for Volume & Brightness
 * Features:
 *   - Follows theme icon color palette: Dark Charcoal (#1a1a1a) in Light Mode, Soft White (#f6f8fa) in Dark Mode
 *   - Smooth 60 FPS cursor dragging with preventStealing to avoid ScrollView interception
 *   - Throttled backend execution to eliminate shell process flooding
 *   - Instant visual response on drag with animated transitions on click
 */
Rectangle {
    id: root

    property int value: 50
    property int from: 0
    property int to: 100
    property string iconName: "audio-volume-high-symbolic"
    property bool isMuted: false
    property bool isDarkTheme: true
    property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"
    property color accentTextColor: (Kirigami.Theme.highlightedTextColor !== undefined && Kirigami.Theme.highlightedTextColor.a > 0) ? Kirigami.Theme.highlightedTextColor : "#ffffff"
    property color trackColor: isDarkTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08)
    property color fillColor: isMuted ? (isDarkTheme ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.25)) : accentColor
    property color iconColor: isDarkTheme ? "#f6f8fa" : "#1a1a1a"

    // Decouple visual fill from backend binding to allow 60 FPS smooth dragging
    property real visualValue: value
    onValueChanged: {
        if (!dragArea.pressed) {
            visualValue = value
        }
    }

    signal valueChangedByUser(int newValue)
    signal iconClicked()

    implicitWidth: 362
    implicitHeight: 24
    height: 24
    radius: height / 2
    color: trackColor
    clip: true

    border.color: isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.08)
    border.width: 1

    // Filled portion (uses system accent color, e.g. Teal)
    Rectangle {
        id: fillRect
        height: parent.height
        width: (root.isMuted || root.visualValue <= root.from) ? 0 : Math.max(parent.height, (root.visualValue - root.from) / (root.to - root.from) * parent.width)
        radius: parent.radius
        color: root.fillColor
        opacity: root.isMuted ? 0.6 : 1.0

        // Disable width animation while dragging so slider sticks directly to mouse cursor
        Behavior on width {
            enabled: !dragArea.pressed
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: 180 }
        }
    }

    // Leading Icon Button (Inside the slider)
    Rectangle {
        id: iconBtn
        width: parent.height - 4
        height: parent.height - 4
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        color: iconMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.15) : "transparent"
        z: 2

        Kirigami.Icon {
            anchors.centerIn: parent
            width: 14
            height: 14
            source: root.iconName
            isMask: true
            color: (root.visualValue > 15 && !root.isMuted) ? root.accentTextColor : root.iconColor
        }

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            onClicked: root.iconClicked()
        }
    }

    // Interactive Drag Area across the slider track
    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // Crucial: Prevents parent ScrollView from stealing mouse drag events
        preventStealing: true

        property int lastEmittedValue: -1

        Timer {
            id: throttleTimer
            interval: 40
            repeat: false
            onTriggered: {
                var v = Math.round(root.visualValue)
                if (v !== dragArea.lastEmittedValue) {
                    dragArea.lastEmittedValue = v
                    root.valueChangedByUser(v)
                }
            }
        }

        function updateFromMouse(mouseX) {
            // Slider active range extends across the capsule
            var startX = parent.height / 2
            var endX = width - (parent.height / 2)
            var ratio = Math.max(0, Math.min(1, (mouseX - startX) / (endX - startX)))
            var newVal = Math.round(root.from + ratio * (root.to - root.from))
            
            // Instant visual feedback under the mouse
            root.visualValue = newVal

            // Throttled CLI emission to prevent process queue flooding
            if (!throttleTimer.running) {
                dragArea.lastEmittedValue = newVal
                root.valueChangedByUser(newVal)
                throttleTimer.start()
            }
        }

        onPressed: function(mouse) {
            updateFromMouse(mouse.x)
        }

        onPositionChanged: function(mouse) {
            if (pressed) {
                updateFromMouse(mouse.x)
            }
        }

        onReleased: function(mouse) {
            throttleTimer.stop()
            var startX = parent.height / 2
            var endX = width - (parent.height / 2)
            var ratio = Math.max(0, Math.min(1, (mouse.x - startX) / (endX - startX)))
            var finalVal = Math.round(root.from + ratio * (root.to - root.from))
            root.visualValue = finalVal
            dragArea.lastEmittedValue = finalVal
            root.valueChangedByUser(finalVal)
        }

        onWheel: function(wheel) {
            var step = (root.to - root.from) * 0.05
            var delta = wheel.angleDelta.y > 0 ? step : -step
            var newVal = Math.max(root.from, Math.min(root.to, Math.round(root.visualValue + delta)))
            root.visualValue = newVal
            dragArea.lastEmittedValue = newVal
            root.valueChangedByUser(newVal)
        }
    }

    // Percentage Label
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.isMuted ? "Muted" : (Math.round(root.visualValue) + "%")
        font.pixelSize: 10
        font.weight: Font.DemiBold
        color: (root.visualValue > 85 && !root.isMuted) ? root.accentTextColor : (root.isDarkTheme ? "#9aa0a6" : "#606770")
        z: 2
    }
}
