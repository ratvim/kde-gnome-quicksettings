import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "./components"

/**
 * CompactRepresentation.qml - Sleek status bar capsule pill for KDE panel (Plasma 6)
 * Layout Order (from right side):
 *   1. Battery icon & % (rightmost, % visibility configurable)
 *   2. Volume icon (icon only, no %)
 *   3. Active toggle icons to the left of Volume (shown only when active/enabled and configured on):
 *      - Wi-Fi, Bluetooth, Airplane, Hotspot, Power Profile (Performance/Optimise only; Balanced is hidden),
 *        Night Light, DND, Dark Style, Location, Mic, Camera, KDE Connect.
 */
Item {
    id: root

    readonly property bool systemIsDark: {
        var bg = Kirigami.Theme.backgroundColor
        return (bg.r * 0.299 + bg.g * 0.587 + bg.b * 0.114) < 0.5
    }
    property bool isDarkTheme: (mainItem && mainItem.isDarkTheme !== undefined) ? mainItem.isDarkTheme : systemIsDark

    // System states
    property bool wifiEnabled: mainItem ? mainItem.wifiEnabled : true
    property bool wifiConnected: mainItem ? mainItem.wifiConnected : true
    property int wifiSignal: mainItem ? mainItem.wifiSignal : 80
    property bool btEnabled: mainItem ? mainItem.btEnabled : true
    property bool btConnected: mainItem ? mainItem.btConnected : false
    property int volume: mainItem ? mainItem.volume : 65
    property bool isMuted: mainItem ? mainItem.isMuted : false
    property int batteryLevel: mainItem ? mainItem.batteryLevel : 85
    property bool batteryCharging: mainItem ? mainItem.batteryCharging : false

    // Sizing
    property int panelIconSize: (mainItem && mainItem.panelIconSize !== undefined) ? mainItem.panelIconSize : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelIconSize !== undefined) ? plasmoid.configuration.panelIconSize : 15)

    // Configuration options (persisted via plasmoid settings)
    property bool showVolume: (mainItem && mainItem.showVolume !== undefined) ? mainItem.showVolume : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showVolume !== undefined) ? plasmoid.configuration.showVolume : true)
    property bool showBattery: (mainItem && mainItem.showBattery !== undefined) ? mainItem.showBattery : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showBattery !== undefined) ? plasmoid.configuration.showBattery : true)
    property bool showBatteryPercent: (mainItem && mainItem.showBatteryPercent !== undefined) ? mainItem.showBatteryPercent : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showBatteryPercent !== undefined) ? plasmoid.configuration.showBatteryPercent : true)

    // Panel Toggle Icons Visibility (persisted via plasmoid settings)
    property bool panelShowWifi: (mainItem && mainItem.panelShowWifi !== undefined) ? mainItem.panelShowWifi : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowWifi !== undefined) ? plasmoid.configuration.panelShowWifi : true)
    property bool panelShowBluetooth: (mainItem && mainItem.panelShowBluetooth !== undefined) ? mainItem.panelShowBluetooth : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowBluetooth !== undefined) ? plasmoid.configuration.panelShowBluetooth : true)
    property bool panelShowNightLight: (mainItem && mainItem.panelShowNightLight !== undefined) ? mainItem.panelShowNightLight : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowNightLight !== undefined) ? plasmoid.configuration.panelShowNightLight : true)
    property bool panelShowAirplane: (mainItem && mainItem.panelShowAirplane !== undefined) ? mainItem.panelShowAirplane : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowAirplane !== undefined) ? plasmoid.configuration.panelShowAirplane : true)
    property bool panelShowDnd: (mainItem && mainItem.panelShowDnd !== undefined) ? mainItem.panelShowDnd : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowDnd !== undefined) ? plasmoid.configuration.panelShowDnd : true)
    property bool panelShowHotspot: (mainItem && mainItem.panelShowHotspot !== undefined) ? mainItem.panelShowHotspot : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowHotspot !== undefined) ? plasmoid.configuration.panelShowHotspot : true)
    property bool panelShowDarkTheme: (mainItem && mainItem.panelShowDarkTheme !== undefined) ? mainItem.panelShowDarkTheme : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowDarkTheme !== undefined) ? plasmoid.configuration.panelShowDarkTheme : true)
    property bool panelShowPowerProfile: (mainItem && mainItem.panelShowPowerProfile !== undefined) ? mainItem.panelShowPowerProfile : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowPowerProfile !== undefined) ? plasmoid.configuration.panelShowPowerProfile : true)
    property bool panelShowLocation: (mainItem && mainItem.panelShowLocation !== undefined) ? mainItem.panelShowLocation : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowLocation !== undefined) ? plasmoid.configuration.panelShowLocation : true)
    property bool panelShowCamera: (mainItem && mainItem.panelShowCamera !== undefined) ? mainItem.panelShowCamera : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowCamera !== undefined) ? plasmoid.configuration.panelShowCamera : true)
    property bool panelShowMic: (mainItem && mainItem.panelShowMic !== undefined) ? mainItem.panelShowMic : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowMic !== undefined) ? plasmoid.configuration.panelShowMic : true)
    property bool panelShowKdeConnect: (mainItem && mainItem.panelShowKdeConnect !== undefined) ? mainItem.panelShowKdeConnect : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowKdeConnect !== undefined) ? plasmoid.configuration.panelShowKdeConnect : true)

    // Wi-Fi icon — follows the active system icon pack exactly
    property string wifiIconName: {
        if (mainItem && mainItem.wifiIconName) {
            return mainItem.wifiIconName
        }
        if (!root.wifiEnabled || !root.wifiConnected) {
            return "network-wireless-offline-symbolic"
        }
        var s = root.wifiSignal
        if (s >= 75) return "network-wireless-signal-excellent-symbolic"
        if (s >= 50) return "network-wireless-signal-good-symbolic"
        if (s >= 25) return "network-wireless-signal-ok-symbolic"
        if (s >  0)  return "network-wireless-signal-weak-symbolic"
        return "network-wireless-symbolic"
    }

    // Dynamic Volume icon matching KDE Plasma System Tray
    property string volumeIconName: {
        if (mainItem && mainItem.volumeIconName) {
            return mainItem.volumeIconName
        }
        if (root.isMuted || root.volume === 0) {
            return "audio-volume-muted"
        }
        if (root.volume > 66) {
            return "audio-volume-high"
        }
        if (root.volume > 33) {
            return "audio-volume-medium"
        }
        return "audio-volume-low"
    }

    // Dynamic Bluetooth icon matching KDE Plasma System Tray
    property string btIconName: {
        if (mainItem && mainItem.btIconName) {
            return mainItem.btIconName
        }
        if (root.btConnected) {
            return "network-bluetooth"
        }
        return "preferences-system-bluetooth"
    }

    // Dynamic Battery icon matching KDE Plasma System Tray
    property string batteryIconName: {
        if (mainItem && mainItem.batteryIconName) {
            return mainItem.batteryIconName
        }
        var level = Math.max(0, Math.min(100, Math.round(root.batteryLevel / 10) * 10))
        var levelStr = ("000" + level).slice(-3)
        if (root.batteryCharging) {
            return "battery-" + levelStr + "-charging"
        }
        return "battery-" + levelStr
    }

    // Dynamic Power Profile icon (Performance / Optimise only)
    property string powerProfileIconName: {
        if (mainItem) {
            if (mainItem.powerProfile === "performance") {
                return "battery-profile-performance-symbolic"
            }
            if (mainItem.powerProfile === "power-saver") {
                return "battery-profile-powersave-symbolic"
            }
        }
        return ""
    }

    // Check if any indicators or battery/volume are currently visible in the capsule
    readonly property bool hasVisibleIndicators: {
        if (root.showBattery) return true
        if (root.showVolume) return true
        if (root.panelShowWifi && Boolean(mainItem && !mainItem.hotspotEnabled && (mainItem.wifiConnected || mainItem.wifiEnabled))) return true
        if (root.panelShowBluetooth && Boolean(mainItem && (mainItem.btEnabled || mainItem.btConnected))) return true
        if (root.panelShowAirplane && Boolean(mainItem && mainItem.airplaneMode)) return true
        if (root.panelShowHotspot && Boolean(mainItem && mainItem.hotspotEnabled)) return true
        if (root.panelShowPowerProfile && Boolean(mainItem && (mainItem.powerProfile === "performance" || mainItem.powerProfile === "power-saver"))) return true
        if (root.panelShowNightLight && Boolean(mainItem && mainItem.nightLightEnabled)) return true
        if (root.panelShowDnd && Boolean(mainItem && mainItem.dndEnabled)) return true
        if (root.panelShowDarkTheme && Boolean(mainItem && mainItem.isDarkTheme)) return true
        if (root.panelShowLocation && Boolean(mainItem && mainItem.locationApps && mainItem.locationApps.length > 0)) return true
        if (root.panelShowMic && Boolean(mainItem && mainItem.micApps && mainItem.micApps.length > 0)) return true
        if (root.panelShowCamera && Boolean(mainItem && mainItem.cameraApps && mainItem.cameraApps.length > 0)) return true
        if (root.panelShowKdeConnect && Boolean(mainItem && mainItem.kdeConnectConnected)) return true
        return false
    }

    // Panel orientation tracking for directional arrow
    readonly property int panelLocation: {
        if (typeof plasmoid !== "undefined" && plasmoid.location !== undefined) {
            return plasmoid.location
        }
        if (typeof Plasmoid !== "undefined" && Plasmoid.location !== undefined) {
            return Plasmoid.location
        }
        return PlasmaCore.Types.BottomEdge
    }

    readonly property real arrowRotation: {
        var baseAngle = 180 // BottomEdge default: pointing UP
        if (panelLocation === PlasmaCore.Types.TopEdge) {
            baseAngle = 0 // TopEdge: pointing DOWN
        } else if (panelLocation === PlasmaCore.Types.BottomEdge) {
            baseAngle = 180 // BottomEdge: pointing UP
        } else if (panelLocation === PlasmaCore.Types.LeftEdge) {
            baseAngle = 270 // LeftEdge: pointing RIGHT
        } else if (panelLocation === PlasmaCore.Types.RightEdge) {
            baseAngle = 90 // RightEdge: pointing LEFT
        }

        if (mainItem && mainItem.expanded) {
            return baseAngle + 180
        }
        return baseAngle
    }

    // Plasma Panel Layout sizing & safety margins
    Layout.fillWidth: false
    Layout.fillHeight: true
    Layout.minimumWidth: pillRect.implicitWidth + 12
    Layout.preferredWidth: pillRect.implicitWidth + 12
    Layout.maximumWidth: pillRect.implicitWidth + 16
    Layout.minimumHeight: pillRect.implicitHeight
    Layout.preferredHeight: pillRect.implicitHeight
    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: 2
    Layout.rightMargin: 8

    implicitWidth: pillRect.implicitWidth + 12
    implicitHeight: pillRect.implicitHeight

    // Capsule pill container
    Rectangle {
        id: pillRect
        anchors.centerIn: parent
        implicitWidth: root.hasVisibleIndicators ? (contentRow.implicitWidth + 24) : Math.max(30, contentRow.implicitWidth + 18)
        implicitHeight: Math.max(30, root.panelIconSize + 14)
        width: implicitWidth
        height: implicitHeight
        radius: height / 2

        color: mouseArea.containsMouse ? (isDarkTheme ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12))
                                       : (isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))
        border.color: isDarkTheme ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(0, 0, 0, 0.08)
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8

            // ========================================================
            // UNIVERSAL FALLBACK ARROW (SHOWN WHEN ALL INDICATORS REMOVED)
            // Points DOWN on top panel, UP on bottom panel
            // ========================================================
            Kirigami.Icon {
                id: fallbackArrow
                visible: !root.hasVisibleIndicators
                implicitWidth: Math.max(12, root.panelIconSize - 2)
                implicitHeight: Math.max(12, root.panelIconSize - 2)
                source: Qt.resolvedUrl("../assets/arrow-down-symbolic.svg")
                fallback: "go-down-symbolic"
                isMask: true
                color: root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
                rotation: root.arrowRotation
                Layout.alignment: Qt.AlignVCenter

                Behavior on rotation {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
            }

            // ========================================================
            // ACTIVE TOGGLE ICONS (LEFT TO RIGHT)
            // Visible only when the toggle is enabled / active AND
            // user configuration allows it to be shown in the panel.
            // ========================================================

            // 1. KDE Connect (when connected)
            Kirigami.Icon {
                visible: root.panelShowKdeConnect && Boolean(mainItem && mainItem.kdeConnectConnected)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: "kdeconnect-tray-symbolic"
                Layout.alignment: Qt.AlignVCenter
            }

            // 2. Camera (appears ONLY when some app is actively using the camera)
            Kirigami.Icon {
                visible: root.panelShowCamera && Boolean(mainItem && mainItem.cameraApps && mainItem.cameraApps.length > 0)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: "camera-web-symbolic"
                Layout.alignment: Qt.AlignVCenter
            }

            // 3. Microphone (appears ONLY when some app is actively using the microphone)
            Kirigami.Icon {
                visible: root.panelShowMic && Boolean(mainItem && mainItem.micApps && mainItem.micApps.length > 0)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: "audio-input-microphone-symbolic"
                Layout.alignment: Qt.AlignVCenter
            }

            // 4. Location (appears ONLY when some app is actively accessing location)
            Kirigami.Icon {
                visible: root.panelShowLocation && Boolean(mainItem && mainItem.locationApps && mainItem.locationApps.length > 0)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: "find-location-symbolic"
                Layout.alignment: Qt.AlignVCenter
            }

            // 5. Dark Style / Dark Theme (when dark mode is active)
            Kirigami.Icon {
                visible: root.panelShowDarkTheme && Boolean(mainItem && mainItem.isDarkTheme)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: "contrast-symbolic"
                Layout.alignment: Qt.AlignVCenter
            }

            // 6. Do Not Disturb (DND) (when active)
            Kirigami.Icon {
                visible: root.panelShowDnd && Boolean(mainItem && mainItem.dndEnabled)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: "notifications-disabled-symbolic"
                Layout.alignment: Qt.AlignVCenter
            }

            // 7. Night Light (when active)
            Kirigami.Icon {
                visible: root.panelShowNightLight && Boolean(mainItem && mainItem.nightLightEnabled)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: "redshift-status-on-symbolic"
                Layout.alignment: Qt.AlignVCenter
            }

            // 8. Power Mode: Performance or Power-Saver / Optimise (Balanced shows NO icon)
            Kirigami.Icon {
                visible: root.panelShowPowerProfile && Boolean(mainItem && (mainItem.powerProfile === "performance" || mainItem.powerProfile === "power-saver"))
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: root.powerProfileIconName
                Layout.alignment: Qt.AlignVCenter
            }

            // 9. Hotspot (when active)
            Kirigami.Icon {
                visible: root.panelShowHotspot && Boolean(mainItem && mainItem.hotspotEnabled)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: "network-wireless-hotspot-symbolic"
                Layout.alignment: Qt.AlignVCenter
            }

            // 10. Airplane Mode (when active)
            Kirigami.Icon {
                visible: root.panelShowAirplane && Boolean(mainItem && mainItem.airplaneMode)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: "network-flightmode-on-symbolic"
                Layout.alignment: Qt.AlignVCenter
            }

            // 11. Bluetooth (when enabled or connected)
            Kirigami.Icon {
                visible: root.panelShowBluetooth && Boolean(mainItem && (mainItem.btEnabled || mainItem.btConnected))
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: root.btIconName
                Layout.alignment: Qt.AlignVCenter
            }

            // 12. Wi-Fi (when enabled or connected)
            Kirigami.Icon {
                visible: root.panelShowWifi && Boolean(mainItem && !mainItem.hotspotEnabled && (mainItem.wifiConnected || mainItem.wifiEnabled))
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: root.wifiIconName
                Layout.alignment: Qt.AlignVCenter
            }

            // ========================================================
            // VOLUME INDICATOR (ICON ONLY, NO PERCENTAGE)
            // ========================================================
            Kirigami.Icon {
                visible: root.showVolume
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                source: root.volumeIconName
                Layout.alignment: Qt.AlignVCenter
            }

            // ========================================================
            // BATTERY INDICATOR + OPTIONAL PERCENTAGE (RIGHTMOST)
            // ========================================================
            RowLayout {
                visible: root.showBattery
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    implicitWidth: root.panelIconSize
                    implicitHeight: root.panelIconSize
                    source: root.batteryIconName
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    visible: root.showBatteryPercent
                    text: root.batteryLevel + "%"
                    font.pixelSize: Math.max(10, root.panelIconSize - 4)
                    font.weight: Font.Medium
                    color: root.batteryLevel <= 20 && !root.batteryCharging ? "#e74c3c" : (root.isDarkTheme ? "#f6f8fa" : "#1a1a1a")
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: {
                if (typeof mainItem !== "undefined" && typeof mainItem.expanded !== "undefined") {
                    mainItem.expanded = !mainItem.expanded
                } else if (typeof plasmoid !== "undefined" && typeof plasmoid.expanded !== "undefined") {
                    plasmoid.expanded = !plasmoid.expanded
                } else if (typeof Plasmoid !== "undefined" && typeof Plasmoid.expanded !== "undefined") {
                    Plasmoid.expanded = !Plasmoid.expanded
                }
            }
        }
    }
}
