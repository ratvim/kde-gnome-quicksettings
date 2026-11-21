import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import "../components"

/**
 * BrightnessView.qml - GNOME-style Display & Brightness Sub-View (Plasma 6)
 * Follows exact KDE System Settings (KScreen) nomenclature:
 *   - "Screen brightness" slider (0-100%)
 *   - "Adaptive Backlight Modulation" slider (0-4)
 *   - "Color profile:" selector ("None" | "Built-in")
 *   - "sRGB color intensity" slider (0-100%, hidden when Color profile is "None")
 *   - Single button to redirect to System Settings Display Configuration
 */
Rectangle {
    id: root

    property var backend: null
    property bool isDarkTheme: true
    property real resolutionScale: 1.0

    signal backClicked()

    readonly property color textColor: isDarkTheme ? "#f6f8fa" : "#1a1a1a"
    readonly property color subTextColor: isDarkTheme ? Qt.rgba(255, 255, 255, 0.65) : Qt.rgba(0, 0, 0, 0.60)
    readonly property color headerColor: isDarkTheme ? Qt.rgba(255, 255, 255, 0.50) : Qt.rgba(0, 0, 0, 0.50)
    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"
    readonly property color accentTextColor: (Kirigami.Theme.highlightedTextColor !== undefined && Kirigami.Theme.highlightedTextColor.a > 0) ? Kirigami.Theme.highlightedTextColor : "#ffffff"

    color: "transparent"

    // Live auto-refresh while the brightness view is visible
    Timer {
        id: autoRefreshTimer
        interval: 3000
        repeat: true
        running: root.visible && (backend !== null)
        onTriggered: {
            if (backend && typeof backend.fetchDisplayDetails === "function") {
                backend.fetchDisplayDetails()
            }
        }
    }

    Component.onCompleted: {
        if (backend && typeof backend.fetchDisplayDetails === "function") {
            backend.fetchDisplayDetails()
        }
    }

    onVisibleChanged: {
        if (visible && backend && typeof backend.fetchDisplayDetails === "function") {
            backend.fetchDisplayDetails()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(14 * root.resolutionScale)
        spacing: Math.round(10 * root.resolutionScale)

        // 1. Header Bar: Back Button (<), Title, and Refresh Button
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(8 * root.resolutionScale)

            // Back button (<)
            Rectangle {
                implicitWidth: Math.round(32 * root.resolutionScale)
                implicitHeight: implicitWidth
                radius: implicitWidth / 2
                color: backMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    implicitWidth: Math.round(16 * root.resolutionScale)
                    implicitHeight: implicitWidth
                    source: "go-previous-symbolic"
                    isMask: true
                    color: root.textColor
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
                text: "Display & Brightness"
                font.pixelSize: Math.round(15 * root.resolutionScale)
                font.weight: Font.Bold
                color: root.textColor
                Layout.fillWidth: true
            }

            // Refresh Button
            Rectangle {
                implicitWidth: Math.round(28 * root.resolutionScale)
                implicitHeight: implicitWidth
                radius: implicitWidth / 2
                color: refMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "view-refresh-symbolic"
                    implicitWidth: Math.round(14 * root.resolutionScale)
                    implicitHeight: implicitWidth
                    isMask: true
                    color: root.subTextColor
                }

                MouseArea {
                    id: refMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (backend && typeof backend.fetchDisplayDetails === "function") {
                            backend.fetchDisplayDetails()
                        }
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }

        // 2. Scrollable Body
        ScrollView {
            id: scrollBody
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                id: contentCol
                width: scrollBody.availableWidth
                spacing: Math.round(10 * root.resolutionScale)

                // =========================================================================
                // MAIN CARD: DISPLAY BARS
                // =========================================================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: cardCol.implicitHeight + Math.round(16 * root.resolutionScale)
                    radius: Math.round(10 * root.resolutionScale)
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.035)
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
                    border.width: 1

                    ColumnLayout {
                        id: cardCol
                        anchors.fill: parent
                        anchors.margins: Math.round(10 * root.resolutionScale)
                        spacing: Math.round(10 * root.resolutionScale)

                        // -------------------------------------------------------------
                        // BAR 1: Screen brightness
                        // -------------------------------------------------------------
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(6 * root.resolutionScale)

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Screen brightness"
                                    font.pixelSize: Math.round(11 * root.resolutionScale)
                                    font.weight: Font.DemiBold
                                    color: root.textColor
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: (backend ? backend.brightness : 75) + "%"
                                    font.pixelSize: Math.round(11 * root.resolutionScale)
                                    font.weight: Font.DemiBold
                                    color: root.subTextColor
                                }
                            }

                            CurvedSlider {
                                Layout.fillWidth: true
                                implicitHeight: Math.max(24, Math.round(26 * root.resolutionScale))
                                value: backend ? backend.brightness : 75
                                from: 0
                                to: 100
                                isMuted: false
                                iconName: "brightness-high-symbolic"
                                isDarkTheme: root.isDarkTheme
                                accentColor: root.accentColor
                                accentTextColor: root.accentTextColor
                                onValueChangedByUser: function(newValue) { if (backend) backend.setBrightness(newValue) }
                                onIconClicked: if (backend) backend.setBrightness(10)
                            }
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
                        }

                        // -------------------------------------------------------------
                        // BAR 2: Adaptive Backlight Modulation
                        // -------------------------------------------------------------
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(6 * root.resolutionScale)

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Adaptive Backlight Modulation"
                                    font.pixelSize: Math.round(11 * root.resolutionScale)
                                    font.weight: Font.DemiBold
                                    color: root.textColor
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    property int lvl: backend ? backend.displayAbmLevel : 1
                                    text: lvl === 0 ? "0 (Off)" : lvl.toString()
                                    font.pixelSize: Math.round(11 * root.resolutionScale)
                                    font.weight: Font.DemiBold
                                    color: lvl > 0 ? root.accentColor : root.subTextColor
                                }
                            }

                            CurvedSlider {
                                Layout.fillWidth: true
                                implicitHeight: Math.max(24, Math.round(26 * root.resolutionScale))
                                value: backend ? backend.displayAbmLevel : 1
                                from: 0
                                to: 4
                                isMuted: false
                                iconName: "contrast-symbolic"
                                isDarkTheme: root.isDarkTheme
                                accentColor: root.accentColor
                                accentTextColor: root.accentTextColor
                                onValueChangedByUser: function(newValue) {
                                    if (backend && typeof backend.setAbmLevel === "function") {
                                        backend.setAbmLevel(newValue)
                                    }
                                }
                                onIconClicked: {
                                    if (backend && typeof backend.setAbmLevel === "function") {
                                        backend.setAbmLevel(0)
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
                        }

                        // -------------------------------------------------------------
                        // COLOR PROFILE SELECTOR ("None" vs "Built-in")
                        // -------------------------------------------------------------
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(8 * root.resolutionScale)

                            Text {
                                text: "Color profile:"
                                font.pixelSize: Math.round(11 * root.resolutionScale)
                                font.weight: Font.DemiBold
                                color: root.textColor
                            }

                            Item { Layout.fillWidth: true }

                            // Segmented pill: "None" vs "Built-in"
                            Rectangle {
                                implicitHeight: Math.round(26 * root.resolutionScale)
                                implicitWidth: segRow.implicitWidth + Math.round(4 * root.resolutionScale)
                                radius: implicitHeight / 2
                                color: root.isDarkTheme ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(0, 0, 0, 0.08)

                                RowLayout {
                                    id: segRow
                                    anchors.centerIn: parent
                                    spacing: Math.round(2 * root.resolutionScale)

                                    // Option "None"
                                    Rectangle {
                                        id: optNone
                                        implicitHeight: Math.round(22 * root.resolutionScale)
                                        implicitWidth: txtNone.implicitWidth + Math.round(14 * root.resolutionScale)
                                        radius: implicitHeight / 2

                                        readonly property bool isSelected: !backend || backend.displayColorProfile === "None" || backend.displayColorProfile === "sRGB"

                                        color: isSelected ? root.accentColor : (mouseNone.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            id: txtNone
                                            anchors.centerIn: parent
                                            text: "None"
                                            font.pixelSize: Math.round(10 * root.resolutionScale)
                                            font.weight: optNone.isSelected ? Font.Bold : Font.Normal
                                            color: optNone.isSelected ? root.accentTextColor : root.textColor
                                        }

                                        MouseArea {
                                            id: mouseNone
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (backend && typeof backend.setColorProfileSource === "function") {
                                                    backend.setColorProfileSource("None")
                                                }
                                            }
                                        }
                                    }

                                    // Option "Built-in"
                                    Rectangle {
                                        id: optBuiltIn
                                        implicitHeight: Math.round(22 * root.resolutionScale)
                                        implicitWidth: txtBuiltIn.implicitWidth + Math.round(14 * root.resolutionScale)
                                        radius: implicitHeight / 2

                                        readonly property bool isSelected: Boolean(backend && backend.displayColorProfile !== "None" && backend.displayColorProfile !== "sRGB")

                                        color: isSelected ? root.accentColor : (mouseBuiltIn.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            id: txtBuiltIn
                                            anchors.centerIn: parent
                                            text: "Built-in"
                                            font.pixelSize: Math.round(10 * root.resolutionScale)
                                            font.weight: optBuiltIn.isSelected ? Font.Bold : Font.Normal
                                            color: optBuiltIn.isSelected ? root.accentTextColor : root.textColor
                                        }

                                        MouseArea {
                                            id: mouseBuiltIn
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (backend && typeof backend.setColorProfileSource === "function") {
                                                    backend.setColorProfileSource("Built-in")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // -------------------------------------------------------------
                        // BAR 3: sRGB color intensity
                        // (Visible ONLY when Color profile is NOT "None"!)
                        // -------------------------------------------------------------
                        ColumnLayout {
                            id: srgbIntensityCol
                            Layout.fillWidth: true
                            spacing: Math.round(6 * root.resolutionScale)
                            visible: Boolean(backend && backend.displayColorProfile !== "None" && backend.displayColorProfile !== "sRGB")

                            // Divider before sRGB intensity
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "sRGB color intensity"
                                    font.pixelSize: Math.round(11 * root.resolutionScale)
                                    font.weight: Font.DemiBold
                                    color: root.textColor
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: (backend ? backend.displaySrgbIntensity : 100) + "%"
                                    font.pixelSize: Math.round(11 * root.resolutionScale)
                                    font.weight: Font.DemiBold
                                    color: root.subTextColor
                                }
                            }

                            CurvedSlider {
                                Layout.fillWidth: true
                                implicitHeight: Math.max(24, Math.round(26 * root.resolutionScale))
                                value: backend ? backend.displaySrgbIntensity : 100
                                from: 0
                                to: 100
                                isMuted: false
                                iconName: "color-management-symbolic"
                                isDarkTheme: root.isDarkTheme
                                accentColor: root.accentColor
                                accentTextColor: root.accentTextColor
                                onValueChangedByUser: function(newValue) {
                                    if (backend && typeof backend.setSrgbIntensity === "function") {
                                        backend.setSrgbIntensity(newValue)
                                    }
                                }
                                onIconClicked: {
                                    if (backend && typeof backend.setSrgbIntensity === "function") {
                                        backend.setSrgbIntensity(100)
                                    }
                                }
                            }
                        }
                    }
                }

                // =========================================================================
                // FOOTER: REDIRECT TO SYSTEM DISPLAY CONFIGURATION
                // =========================================================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * root.resolutionScale)
                    radius: Math.round(8 * root.resolutionScale)
                    color: displaySettingsMouse.containsMouse
                        ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))
                        : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03))
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.07)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Math.round(6 * root.resolutionScale)

                        Kirigami.Icon {
                            source: "preferences-desktop-display"
                            fallback: "video-display"
                            implicitWidth: Math.round(14 * root.resolutionScale)
                            implicitHeight: implicitWidth
                            isMask: true
                            color: root.textColor
                        }

                        Text {
                            text: "Configure Displays in System Settings..."
                            font.pixelSize: Math.round(11 * root.resolutionScale)
                            font.weight: Font.Medium
                            color: root.textColor
                        }
                    }

                    MouseArea {
                        id: displaySettingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (backend && typeof backend.openDisplaySettings === "function") {
                                backend.openDisplaySettings()
                            }
                        }
                    }
                }
            }
        }
    }
}
