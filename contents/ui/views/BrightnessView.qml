import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import "../components"

/**
 * BrightnessView.qml - GNOME-style Display & Brightness Sub-View (Plasma 6)
 * Features:
 *   - Master Display Brightness curved slider with instant feedback
 *   - Adaptive Backlight Modulation (ABM) intensity levels (0=Off, 1=Low, 2=Medium, 3=High, 4=Max)
 *   - sRGB Color Profile selection (sRGB / EDID) and sRGB Color Intensity slider (0-100%)
 *   - Direct shortcut button to KDE System Display Settings (kcm_kscreen)
 * Dedicated full sub-view matching VolumeView, NetworkView, and BluetoothView.
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(14 * root.resolutionScale)
        spacing: Math.round(10 * root.resolutionScale)

        // 1. Header Bar: Back Button, Title, and Refresh Button (NO duplicate settings button)
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
                spacing: Math.round(12 * root.resolutionScale)

                // =========================================================================
                // SECTION 1: MASTER DISPLAY BRIGHTNESS
                // =========================================================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: masterCol.implicitHeight + Math.round(16 * root.resolutionScale)
                    radius: Math.round(10 * root.resolutionScale)
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.035)
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
                    border.width: 1

                    ColumnLayout {
                        id: masterCol
                        anchors.fill: parent
                        anchors.margins: Math.round(10 * root.resolutionScale)
                        spacing: Math.round(8 * root.resolutionScale)

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "MASTER BRIGHTNESS"
                                font.pixelSize: Math.round(10 * root.resolutionScale)
                                font.weight: Font.Bold
                                font.capitalization: Font.AllUppercase
                                color: root.headerColor
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
                            isMuted: false
                            iconName: "brightness-high-symbolic"
                            isDarkTheme: root.isDarkTheme
                            accentColor: root.accentColor
                            accentTextColor: root.accentTextColor
                            onValueChangedByUser: function(newValue) { if (backend) backend.setBrightness(newValue) }
                            onIconClicked: if (backend) backend.setBrightness(10)
                        }
                    }
                }

                // =========================================================================
                // SECTION 2: ADAPTIVE BACKLIGHT INTENSITY (ABM)
                // =========================================================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: abmCol.implicitHeight + Math.round(16 * root.resolutionScale)
                    radius: Math.round(10 * root.resolutionScale)
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.035)
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
                    border.width: 1

                    ColumnLayout {
                        id: abmCol
                        anchors.fill: parent
                        anchors.margins: Math.round(10 * root.resolutionScale)
                        spacing: Math.round(8 * root.resolutionScale)

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "ADAPTIVE BACKLIGHT INTENSITY (ABM)"
                                font.pixelSize: Math.round(10 * root.resolutionScale)
                                font.weight: Font.Bold
                                font.capitalization: Font.AllUppercase
                                color: root.headerColor
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                property int curLevel: backend ? backend.displayAbmLevel : 1
                                text: curLevel === 0 ? "Disabled (0)" :
                                      (curLevel === 1 ? "Low (1)" :
                                      (curLevel === 2 ? "Medium (2)" :
                                      (curLevel === 3 ? "High (3)" : "Maximum (4)")))
                                font.pixelSize: Math.round(11 * root.resolutionScale)
                                font.weight: Font.DemiBold
                                color: curLevel > 0 ? root.accentColor : root.subTextColor
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Dynamically adjusts screen backlight based on pixel content to enhance contrast and save battery power."
                            font.pixelSize: Math.round(10 * root.resolutionScale)
                            color: root.subTextColor
                            wrapMode: Text.WordWrap
                        }

                        // 5-Level Segmented Controls (0: Off, 1: Low, 2: Med, 3: High, 4: Max)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(4 * root.resolutionScale)

                            Repeater {
                                model: [
                                    { level: 0, label: "Off" },
                                    { level: 1, label: "Low" },
                                    { level: 2, label: "Medium" },
                                    { level: 3, label: "High" },
                                    { level: 4, label: "Max" }
                                ]

                                Rectangle {
                                    id: abmBtn
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(28 * root.resolutionScale)
                                    radius: Math.round(6 * root.resolutionScale)

                                    readonly property bool isSelected: (backend ? backend.displayAbmLevel : 1) === modelData.level

                                    color: isSelected
                                        ? root.accentColor
                                        : (abmMouse.containsMouse
                                            ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                                            : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)))

                                    border.color: isSelected ? "transparent" : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.06))
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.pixelSize: Math.round(10 * root.resolutionScale)
                                        font.weight: abmBtn.isSelected ? Font.Bold : Font.Normal
                                        color: abmBtn.isSelected ? root.accentTextColor : root.textColor
                                    }

                                    MouseArea {
                                        id: abmMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (backend && typeof backend.setAbmLevel === "function") {
                                                backend.setAbmLevel(modelData.level)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =========================================================================
                // SECTION 3: sRGB COLOR INTENSITY & PROFILE
                // =========================================================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: colorCol.implicitHeight + Math.round(16 * root.resolutionScale)
                    radius: Math.round(10 * root.resolutionScale)
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.035)
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
                    border.width: 1

                    ColumnLayout {
                        id: colorCol
                        anchors.fill: parent
                        anchors.margins: Math.round(10 * root.resolutionScale)
                        spacing: Math.round(10 * root.resolutionScale)

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "SRGB COLOR INTENSITY"
                                font.pixelSize: Math.round(10 * root.resolutionScale)
                                font.weight: Font.Bold
                                font.capitalization: Font.AllUppercase
                                color: root.headerColor
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: (backend ? backend.displaySrgbIntensity : 100) + "%"
                                font.pixelSize: Math.round(11 * root.resolutionScale)
                                font.weight: Font.DemiBold
                                color: root.subTextColor
                            }
                        }

                        // sRGB Intensity Curved Slider
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

                        // Divider inside card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.06)
                        }

                        // Color Profile Source Selector (sRGB vs EDID Native)
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "COLOR PROFILE"
                                font.pixelSize: Math.round(10 * root.resolutionScale)
                                font.weight: Font.Bold
                                font.capitalization: Font.AllUppercase
                                color: root.headerColor
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: backend && backend.displayOutputName ? backend.displayOutputName : "Display"
                                font.pixelSize: Math.round(10 * root.resolutionScale)
                                color: root.subTextColor
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(6 * root.resolutionScale)

                            // sRGB Profile Button
                            Rectangle {
                                id: srgbBtn
                                Layout.fillWidth: true
                                implicitHeight: Math.round(30 * root.resolutionScale)
                                radius: Math.round(6 * root.resolutionScale)

                                readonly property bool isSelected: !backend || !backend.displayColorProfile || backend.displayColorProfile === "sRGB"

                                color: isSelected
                                    ? root.accentColor
                                    : (srgbMouse.containsMouse
                                        ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                                        : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)))

                                border.color: isSelected ? "transparent" : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.06))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: Math.round(6 * root.resolutionScale)

                                    Kirigami.Icon {
                                        source: "color-management-symbolic"
                                        implicitWidth: Math.round(13 * root.resolutionScale)
                                        implicitHeight: implicitWidth
                                        isMask: true
                                        color: srgbBtn.isSelected ? root.accentTextColor : root.textColor
                                    }

                                    Text {
                                        text: "sRGB (Standard Profile)"
                                        font.pixelSize: Math.round(11 * root.resolutionScale)
                                        font.weight: srgbBtn.isSelected ? Font.Bold : Font.Normal
                                        color: srgbBtn.isSelected ? root.accentTextColor : root.textColor
                                    }
                                }

                                MouseArea {
                                    id: srgbMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (backend && typeof backend.setColorProfileSource === "function") {
                                            backend.setColorProfileSource("sRGB")
                                        }
                                    }
                                }
                            }

                            // EDID Native Hardware Button
                            Rectangle {
                                id: edidBtn
                                Layout.fillWidth: true
                                implicitHeight: Math.round(30 * root.resolutionScale)
                                radius: Math.round(6 * root.resolutionScale)

                                readonly property bool isSelected: Boolean(backend && backend.displayColorProfile === "EDID")

                                color: isSelected
                                    ? root.accentColor
                                    : (edidMouse.containsMouse
                                        ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                                        : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)))

                                border.color: isSelected ? "transparent" : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.06))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: Math.round(6 * root.resolutionScale)

                                    Kirigami.Icon {
                                        source: "video-display"
                                        implicitWidth: Math.round(13 * root.resolutionScale)
                                        implicitHeight: implicitWidth
                                        isMask: true
                                        color: edidBtn.isSelected ? root.accentTextColor : root.textColor
                                    }

                                    Text {
                                        text: "EDID (Native Hardware)"
                                        font.pixelSize: Math.round(11 * root.resolutionScale)
                                        font.weight: edidBtn.isSelected ? Font.Bold : Font.Normal
                                        color: edidBtn.isSelected ? root.accentTextColor : root.textColor
                                    }
                                }

                                MouseArea {
                                    id: edidMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (backend && typeof backend.setColorProfileSource === "function") {
                                            backend.setColorProfileSource("EDID")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =========================================================================
                // SECTION 4: FOOTER - CONFIGURE DISPLAY SETTINGS
                // =========================================================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * root.resolutionScale)
                    radius: Math.round(8 * root.resolutionScale)
                    color: displaySettingsMouse.containsMouse
                        ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))
                        : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03))
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.07)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Math.round(8 * root.resolutionScale)

                        Kirigami.Icon {
                            source: "preferences-desktop-display"
                            fallback: "video-display"
                            implicitWidth: Math.round(15 * root.resolutionScale)
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
