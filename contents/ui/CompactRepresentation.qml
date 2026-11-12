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

    // Dynamically follows global desktop theme (Complementary in Dark mode, Window in Light mode)
    // Ensures text and symbolic icons render in crisp contrast matching the system theme.
    Kirigami.Theme.colorSet: root.isDarkTheme ? Kirigami.Theme.Complementary : Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    // Backend reference (avoiding any shadowing by PlasmaCore.Dialog.mainItem)
    readonly property var backend: (typeof mainItem !== "undefined" && mainItem) ? mainItem : null

    readonly property bool systemIsDark: (backend && backend.systemIsDark !== undefined) ? backend.systemIsDark : false
    property bool isDarkTheme: (backend && backend.isDarkTheme !== undefined) ? backend.isDarkTheme : true

    // Dynamic detection of attached panel background, opacity, and blur
    function detectPanelProperties() {
        var hasCustomColor = false
        var detectedColor = Qt.rgba(0, 0, 0, 0)
        var detectedOpacity = 0.70
        var detectedBlur = true
        var detectedTextColor = Qt.rgba(0, 0, 0, 0)

        // 1. Inspect sibling applets in the panel containment for panel.colorizer
        try {
            if (typeof plasmoid !== "undefined" && plasmoid.containment && plasmoid.containment.applets) {
                var applets = plasmoid.containment.applets
                for (var i = 0; i < applets.length; ++i) {
                    var app = applets[i]
                    if (app && app.plugin === "luisbocanegra.panel.colorizer") {
                        var cfg = app.configuration
                        if (cfg) {
                            var gSettings = (typeof cfg.globalSettings === "string") ? JSON.parse(cfg.globalSettings) : cfg.globalSettings
                            if (gSettings) {
                                // 1a. Native panel background opacity override
                                if (gSettings.nativePanel && gSettings.nativePanel.background && gSettings.nativePanel.background.opacity !== undefined) {
                                    var nop = parseFloat(gSettings.nativePanel.background.opacity)
                                    if (!isNaN(nop) && nop >= 0.05 && nop <= 1.0) {
                                        detectedOpacity = nop
                                    }
                                }
                                // 1b. Custom panel settings override
                                if (gSettings.panel && gSettings.panel.enabled) {
                                    if (gSettings.panel.opacity !== undefined) {
                                        var pop = parseFloat(gSettings.panel.opacity)
                                        if (!isNaN(pop) && pop >= 0.05 && pop <= 1.0) {
                                            detectedOpacity = pop
                                        }
                                    }
                                    if (gSettings.panel.backgroundColor && gSettings.panel.backgroundColor.enabled && gSettings.panel.backgroundColor.custom) {
                                        var customHex = gSettings.panel.backgroundColor.custom
                                        if (customHex && typeof customHex === "string" && customHex.length >= 4) {
                                            detectedColor = Qt.color(customHex)
                                            hasCustomColor = true
                                        }
                                    }
                                    if (gSettings.panel.blurBehind !== undefined) {
                                        detectedBlur = Boolean(gSettings.panel.blurBehind)
                                    }
                                    if (gSettings.panel.foregroundColor && gSettings.panel.foregroundColor.enabled && gSettings.panel.foregroundColor.custom) {
                                        var fgHex = gSettings.panel.foregroundColor.custom
                                        if (fgHex && typeof fgHex === "string" && fgHex.length >= 4) {
                                            detectedTextColor = Qt.color(fgHex)
                                        }
                                    }
                                }
                            }
                        }
                        break
                    }
                }
            }
        } catch (e1) {}

        // 2. Check native PanelView window and parent hierarchy
        try {
            var win = root.Window.window
            if (win) {
                // Check opacityMode on PanelView (0: Adaptive, 1: Opaque, 2: Translucent)
                if (win.opacityMode !== undefined) {
                    if (win.opacityMode === 1) { // Opaque
                        detectedOpacity = 1.0
                    } else if (win.opacityMode === 2) { // Translucent
                        detectedOpacity = 0.65
                    }
                }

                if (win.panelOpacity !== undefined && win.panelOpacity > 0.05) {
                    detectedOpacity = Math.max(0.35, Math.min(1.0, win.panelOpacity))
                } else if (win.contentItem && win.contentItem.children) {
                    for (var j = 0; j < win.contentItem.children.length; ++j) {
                        var ch = win.contentItem.children[j]
                        if (ch && ch.panelOpacity !== undefined && ch.panelOpacity > 0.05) {
                            detectedOpacity = Math.max(0.35, Math.min(1.0, ch.panelOpacity))
                            break
                        }
                    }
                }
            }
        } catch (e2) {}

        // 3. Walk up parent hierarchy for panelOpacity
        try {
            var p = root.parent
            while (p) {
                if (p.panelOpacity !== undefined && p.panelOpacity > 0.05) {
                    detectedOpacity = Math.max(0.35, Math.min(1.0, p.panelOpacity))
                    break
                }
                p = p.parent
            }
        } catch (e3) {}

        if (backend) {
            backend.hasCustomPanelColor = hasCustomColor
            backend.detectedPanelColor = hasCustomColor ? detectedColor : Qt.rgba(0, 0, 0, 0)
            backend.detectedPanelOpacity = detectedOpacity
            backend.detectedPanelBlur = detectedBlur
            backend.detectedPanelTextColor = detectedTextColor
        }
    }

    Timer {
        id: panelDetectTimer
        interval: 300
        running: true
        repeat: false
        onTriggered: root.detectPanelProperties()
    }

    function disableSystemToolTip() {
        var p = parent
        while (p) {
            if (p.objectName === "org.kde.desktop-CompactApplet" || (typeof p.active !== "undefined" && p.toString().indexOf("ToolTipArea") !== -1)) {
                p.active = false
                if (typeof p.mainText !== "undefined") p.mainText = ""
                if (typeof p.subText !== "undefined") p.subText = ""
                break
            }
            p = p.parent
        }
    }

    Timer {
        id: disableToolTipTimer
        interval: 150
        repeat: false
        running: true
        onTriggered: root.disableSystemToolTip()
    }

    Connections {
        target: backend ? backend : null
        ignoreUnknownSignals: true
        function onExpandedChanged() {
            root.disableSystemToolTip()
        }
    }

    onWindowChanged: {
        root.detectPanelProperties()
        root.disableSystemToolTip()
    }

    onParentChanged: {
        root.detectPanelProperties()
        root.disableSystemToolTip()
    }

    Component.onCompleted: {
        root.detectPanelProperties()
        root.disableSystemToolTip()
    }

    // Active icons on the panel use high-contrast panel foreground adapting dynamically to dark/light theme
    readonly property color activeIndicatorColor: {
        if (backend && backend.detectedPanelTextColor && backend.detectedPanelTextColor.a > 0) {
            return backend.detectedPanelTextColor
        }
        if (backend && backend.hasCustomPanelColor) {
            return backend.effectiveIsDark ? "#f6f8fa" : "#1a1a1a"
        }
        return root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
    }
    // Inactive, muted, or blocked indicators are slightly greyed (45% opacity) and always clearly visible
    readonly property color inactiveIndicatorColor: Qt.rgba(activeIndicatorColor.r, activeIndicatorColor.g, activeIndicatorColor.b, 0.45)

    // Tooltip card foreground colors (tooltips float in their own window following system light/dark theme)
    readonly property color tooltipActiveColor: root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
    readonly property color tooltipInactiveColor: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.45) : Qt.rgba(0, 0, 0, 0.45)

    // System states
    property bool wifiEnabled: backend ? backend.wifiEnabled : true
    property bool wifiConnected: backend ? backend.wifiConnected : true
    property int wifiSignal: backend ? backend.wifiSignal : 80
    property string wifiSsid: backend ? backend.wifiSsid : ""
    property bool btEnabled: backend ? backend.btEnabled : true
    property bool btConnected: backend ? backend.btConnected : false
    property string btDeviceName: backend ? backend.btDeviceName : ""
    property int btBattery: backend ? backend.btBattery : 0
    property int volume: backend ? backend.volume : 65
    property bool isMuted: backend ? backend.isMuted : false
    property var audioSinks: backend ? backend.audioSinks : []
    property int batteryLevel: backend ? backend.batteryLevel : 85
    property bool batteryCharging: backend ? backend.batteryCharging : false

    // Sizing
    property int panelIconSize: (backend && backend.panelIconSize !== undefined) ? backend.panelIconSize : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelIconSize !== undefined) ? plasmoid.configuration.panelIconSize : 16)

    // Configuration options (persisted via plasmoid settings)
    property bool showVolume: (backend && backend.showVolume !== undefined) ? backend.showVolume : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showVolume !== undefined) ? plasmoid.configuration.showVolume : true)
    property bool showBattery: (backend && backend.showBattery !== undefined) ? backend.showBattery : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showBattery !== undefined) ? plasmoid.configuration.showBattery : true)
    property bool showBatteryPercent: (backend && backend.showBatteryPercent !== undefined) ? backend.showBatteryPercent : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showBatteryPercent !== undefined) ? plasmoid.configuration.showBatteryPercent : true)

    // Panel Toggle Icons Visibility (persisted via plasmoid settings)
    property bool panelShowWifi: (backend && backend.panelShowWifi !== undefined) ? backend.panelShowWifi : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowWifi !== undefined) ? plasmoid.configuration.panelShowWifi : true)
    property bool panelShowBluetooth: (backend && backend.panelShowBluetooth !== undefined) ? backend.panelShowBluetooth : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowBluetooth !== undefined) ? plasmoid.configuration.panelShowBluetooth : true)
    property bool panelShowNightLight: (backend && backend.panelShowNightLight !== undefined) ? backend.panelShowNightLight : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowNightLight !== undefined) ? plasmoid.configuration.panelShowNightLight : true)
    property bool panelShowAirplane: (backend && backend.panelShowAirplane !== undefined) ? backend.panelShowAirplane : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowAirplane !== undefined) ? plasmoid.configuration.panelShowAirplane : true)
    property bool panelShowDnd: (backend && backend.panelShowDnd !== undefined) ? backend.panelShowDnd : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowDnd !== undefined) ? plasmoid.configuration.panelShowDnd : true)
    property bool panelShowHotspot: (backend && backend.panelShowHotspot !== undefined) ? backend.panelShowHotspot : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowHotspot !== undefined) ? plasmoid.configuration.panelShowHotspot : true)
    property bool panelShowDarkTheme: (backend && backend.panelShowDarkTheme !== undefined) ? backend.panelShowDarkTheme : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowDarkTheme !== undefined) ? plasmoid.configuration.panelShowDarkTheme : true)
    property bool panelShowPowerProfile: (backend && backend.panelShowPowerProfile !== undefined) ? backend.panelShowPowerProfile : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowPowerProfile !== undefined) ? plasmoid.configuration.panelShowPowerProfile : true)
    property bool panelShowLocation: (backend && backend.panelShowLocation !== undefined) ? backend.panelShowLocation : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowLocation !== undefined) ? plasmoid.configuration.panelShowLocation : true)
    property bool panelShowCamera: (backend && backend.panelShowCamera !== undefined) ? backend.panelShowCamera : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowCamera !== undefined) ? plasmoid.configuration.panelShowCamera : true)
    property bool panelShowMic: (backend && backend.panelShowMic !== undefined) ? backend.panelShowMic : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowMic !== undefined) ? plasmoid.configuration.panelShowMic : true)
    property bool panelShowKdeConnect: (backend && backend.panelShowKdeConnect !== undefined) ? backend.panelShowKdeConnect : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowKdeConnect !== undefined) ? plasmoid.configuration.panelShowKdeConnect : true)

    // Device, Privacy & Quick Setting States
    property bool locationEnabled: Boolean(backend && (backend.locationEnabled || (backend.locationApps && backend.locationApps.length > 0)))
    property var locationApps: (backend && backend.locationApps) ? backend.locationApps : []
    property bool micMuted: backend ? backend.micMuted : false
    property var micApps: (backend && backend.micApps) ? backend.micApps : []
    property bool cameraBlocked: backend ? backend.cameraBlocked : false
    property var cameraApps: (backend && backend.cameraApps) ? backend.cameraApps : []
    property bool kdeConnectConnected: backend ? backend.kdeConnectConnected : false
    property string kdeConnectName: backend ? backend.kdeConnectName : ""
    property int kdeConnectBattery: (backend && backend.kdeConnectBattery !== undefined) ? backend.kdeConnectBattery : -1
    property bool nightLightEnabled: backend ? backend.nightLightEnabled : false
    property bool dndEnabled: backend ? backend.dndEnabled : false
    property string dndUntilText: backend ? backend.dndUntilText : ""
    property bool hotspotEnabled: backend ? backend.hotspotEnabled : false
    property string hotspotSsid: backend ? backend.hotspotSsid : ""
    property string hotspotPassword: backend ? backend.hotspotPassword : ""
    property bool airplaneMode: backend ? backend.airplaneMode : false
    property string powerProfile: backend ? backend.powerProfile : "balanced"
    property bool isTrayExpanded: Boolean(backend && backend.expanded)

    // Wi-Fi icon — follows the active system icon pack exactly
    property string wifiIconName: {
        if (backend && backend.wifiIconName) {
            return backend.wifiIconName
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
        if (backend && backend.volumeIconName) {
            return backend.volumeIconName
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
        if (backend && backend.btIconName) {
            return backend.btIconName
        }
        if (root.btConnected) {
            return "network-bluetooth"
        }
        return "preferences-system-bluetooth"
    }

    // Dynamic Battery icon matching KDE Plasma System Tray
    property string batteryIconName: {
        if (backend && backend.batteryIconName) {
            return backend.batteryIconName
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
        if (backend) {
            if (backend.powerProfile === "performance") {
                return "battery-profile-performance-symbolic"
            }
            if (backend.powerProfile === "power-saver") {
                return "battery-profile-powersave-symbolic"
            }
        }
        return ""
    }

    // Check if any indicators or battery/volume are currently visible in the capsule
    readonly property bool hasVisibleIndicators: {
        if (root.showBattery) return true
        if (root.showVolume) return true
        if (root.panelShowWifi && (root.wifiConnected || root.wifiEnabled)) return true
        if (root.panelShowBluetooth && (root.btEnabled || root.btConnected)) return true
        if (root.panelShowAirplane && root.airplaneMode) return true
        if (root.panelShowHotspot && root.hotspotEnabled) return true
        if (root.panelShowPowerProfile && (root.powerProfile === "performance" || root.powerProfile === "power-saver")) return true
        if (root.panelShowNightLight && root.nightLightEnabled) return true
        if (root.panelShowDnd && root.dndEnabled) return true
        if (root.panelShowDarkTheme) return true
        if (root.panelShowLocation && Boolean(root.locationApps && root.locationApps.length > 0)) return true
        if (root.panelShowMic && Boolean(root.micApps && root.micApps.length > 0)) return true
        if (root.panelShowCamera && Boolean(root.cameraApps && root.cameraApps.length > 0)) return true
        if (root.panelShowKdeConnect && root.kdeConnectConnected) return true
        return false
    }

    // Panel orientation tracking for directional arrow and indicator hover popups
    readonly property int panelLocation: {
        if (typeof backend !== "undefined" && backend) {
            if (backend.panelLocation !== undefined) return backend.panelLocation
            if (backend.Plasmoid) {
                if (backend.Plasmoid.containment && backend.Plasmoid.containment.location !== undefined) {
                    return backend.Plasmoid.containment.location
                }
                if (backend.Plasmoid.location !== undefined) {
                    return backend.Plasmoid.location
                }
            }
        }
        if (typeof Plasmoid !== "undefined" && Plasmoid) {
            if (Plasmoid.containment && Plasmoid.containment.location !== undefined) {
                return Plasmoid.containment.location
            }
            if (Plasmoid.location !== undefined) {
                return Plasmoid.location
            }
        }
        if (typeof plasmoid !== "undefined" && plasmoid) {
            if (plasmoid.containment && plasmoid.containment.location !== undefined) {
                return plasmoid.containment.location
            }
            if (plasmoid.location !== undefined) {
                return plasmoid.location
            }
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

        if (root.isTrayExpanded) {
            return baseAngle + 180
        }
        return baseAngle
    }

    readonly property bool isTopPanel: root.panelLocation === PlasmaCore.Types.TopEdge

    function toggleQuickSettings() {
        root.detectPanelProperties()
        if (typeof backend !== "undefined" && backend && typeof backend.expanded !== "undefined") {
            backend.expanded = !backend.expanded
        } else if (typeof plasmoid !== "undefined" && typeof plasmoid.expanded !== "undefined") {
            plasmoid.expanded = !plasmoid.expanded
        } else if (typeof Plasmoid !== "undefined" && typeof Plasmoid.expanded !== "undefined") {
            Plasmoid.expanded = !Plasmoid.expanded
        }
    }

    function formatAppNames(appsList) {
        if (!appsList || !Array.isArray(appsList) || appsList.length === 0) return ""
        var names = []
        for (var i = 0; i < appsList.length; i++) {
            var item = appsList[i]
            if (typeof item === "string") {
                names.push(item)
            } else if (item && typeof item === "object") {
                names.push(item.name || item.comm || item.details || "Application")
            }
        }
        return names.join(", ")
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
        objectName: "capsulePill"
        anchors.centerIn: parent
        implicitWidth: root.hasVisibleIndicators ? (contentRow.implicitWidth + 24) : Math.max(30, contentRow.implicitWidth + 18)
        implicitHeight: Math.max(32, root.panelIconSize + 14)
        width: implicitWidth
        height: implicitHeight
        radius: height / 2

        color: mouseArea.containsMouse ? Qt.rgba(root.activeIndicatorColor.r, root.activeIndicatorColor.g, root.activeIndicatorColor.b, 0.16)
                                       : Qt.rgba(root.activeIndicatorColor.r, root.activeIndicatorColor.g, root.activeIndicatorColor.b, 0.08)
        border.color: Qt.rgba(root.activeIndicatorColor.r, root.activeIndicatorColor.g, root.activeIndicatorColor.b, 0.12)
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: root.toggleQuickSettings()
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8

            // ========================================================
            // UNIVERSAL FALLBACK ARROW (SHOWN WHEN ALL INDICATORS REMOVED)
            // Points DOWN on top panel, UP on bottom panel
            // ========================================================
            Item {
                id: fallbackArrowItem
                visible: !root.hasVisibleIndicators
                implicitWidth: Math.max(12, root.panelIconSize - 2)
                implicitHeight: Math.max(12, root.panelIconSize - 2)
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    id: fallbackArrow
                    anchors.fill: parent
                    source: Qt.resolvedUrl("../assets/arrow-down-symbolic.svg")
                    fallback: "go-down-symbolic"
                    isMask: true
                    color: root.activeIndicatorColor
                    rotation: root.arrowRotation

                    Behavior on rotation {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: arrowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: !root.hasVisibleIndicators && arrowHover.containsMouse && !root.isTrayExpanded
                    title: "Quick Settings"
                    status: "Click to open Control Center"
                    iconName: "preferences-system"
                    iconColor: root.tooltipActiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: fallbackArrowItem
                }
            }

            // ========================================================
            // ACTIVE TOGGLE ICONS (LEFT TO RIGHT)
            // ========================================================

            // 1. KDE Connect (when connected)
            Item {
                id: kdeItem
                visible: root.panelShowKdeConnect && root.kdeConnectConnected
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: "kdeconnect-tray-symbolic"
                    fallback: Qt.resolvedUrl("../icons/phone-symbolic.svg")
                    isMask: true
                    color: root.activeIndicatorColor
                }

                MouseArea {
                    id: kdeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: kdeHover.containsMouse && !root.isTrayExpanded
                    title: (root.kdeConnectName && root.kdeConnectName !== "") ? root.kdeConnectName : "KDE Connect"
                    status: (root.kdeConnectBattery > 0) ? (root.kdeConnectBattery + "% Battery • Synced") : (root.kdeConnectConnected ? "Device synchronized" : "No device connected")
                    iconName: "kdeconnect-tray-symbolic"
                    iconColor: root.kdeConnectConnected ? root.tooltipActiveColor : root.tooltipInactiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: kdeItem
                }
            }

            // 2. Camera (appears ONLY when some app is actively using the camera)
            Item {
                id: camItem
                visible: root.panelShowCamera && Boolean(root.cameraApps && root.cameraApps.length > 0)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: root.cameraBlocked ? "camera-off-symbolic" : "camera-web-symbolic"
                    fallback: root.cameraBlocked ? Qt.resolvedUrl("../icons/camera-off-symbolic.svg") : Qt.resolvedUrl("../icons/camera-web-symbolic.svg")
                    isMask: true
                    color: root.cameraBlocked ? root.inactiveIndicatorColor : root.activeIndicatorColor
                }

                MouseArea {
                    id: camHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: camHover.containsMouse && !root.isTrayExpanded
                    title: {
                        var names = root.formatAppNames(root.cameraApps)
                        if (names !== "") return names
                        return root.cameraBlocked ? "Camera Guard Active" : "Camera In Use"
                    }
                    status: root.cameraBlocked ? "Video capture blocked" : "Active camera stream"
                    iconName: root.cameraBlocked ? "camera-off-symbolic" : "camera-web-symbolic"
                    iconColor: root.cameraBlocked ? root.tooltipInactiveColor : root.tooltipActiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: camItem
                }
            }

            // 3. Microphone (appears ONLY when some app is actively using the microphone)
            Item {
                id: micItem
                visible: root.panelShowMic && Boolean(root.micApps && root.micApps.length > 0)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: root.micMuted ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic"
                    fallback: root.micMuted ? Qt.resolvedUrl("../icons/microphone-sensitivity-muted-symbolic.svg") : Qt.resolvedUrl("../icons/audio-input-microphone-symbolic.svg")
                    isMask: true
                    color: root.micMuted ? root.inactiveIndicatorColor : root.activeIndicatorColor
                }

                MouseArea {
                    id: micHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: micHover.containsMouse && !root.isTrayExpanded
                    title: {
                        var names = root.formatAppNames(root.micApps)
                        if (names !== "") return names
                        return root.micMuted ? "Microphone Muted" : "Microphone Active"
                    }
                    status: root.micMuted ? "Muted by privacy toggle" : "Audio capture active"
                    iconName: root.micMuted ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic"
                    iconColor: root.micMuted ? root.tooltipInactiveColor : root.tooltipActiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: micItem
                }
            }

            // 4. Location (appears ONLY when some app is actively accessing location)
            Item {
                id: locItem
                visible: root.panelShowLocation && Boolean(root.locationApps && root.locationApps.length > 0)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: "find-location-symbolic"
                    fallback: Qt.resolvedUrl("../icons/location-services-active-symbolic.svg")
                    isMask: true
                    color: root.locationEnabled ? root.activeIndicatorColor : root.inactiveIndicatorColor
                }

                MouseArea {
                    id: locHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: locHover.containsMouse && !root.isTrayExpanded
                    title: {
                        var names = root.formatAppNames(root.locationApps)
                        if (names !== "") return names
                        return root.locationEnabled ? "Location Services" : "Location Off"
                    }
                    status: root.locationEnabled 
                        ? ((root.locationApps && root.locationApps.length > 0) ? "Active Geolocation • In Use" : "Location Enabled") 
                        : "Location tracking disabled"
                    iconName: "find-location-symbolic"
                    iconColor: root.locationEnabled ? root.tooltipActiveColor : root.tooltipInactiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: locItem
                }
            }

            // 5. Dark Style / Dark Theme (adapts symbol: moon in dark mode, sun in light mode)
            Item {
                id: darkItem
                visible: root.panelShowDarkTheme
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: root.isDarkTheme ? "weather-clear-night-symbolic" : "weather-clear-symbolic"
                    fallback: root.isDarkTheme ? Qt.resolvedUrl("../icons/weather-clear-night-symbolic.svg") : "contrast-symbolic"
                    isMask: true
                    color: root.activeIndicatorColor
                }

                MouseArea {
                    id: darkHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: darkHover.containsMouse && !root.isTrayExpanded
                    title: root.isDarkTheme ? "Dark Mode Active" : "Light Mode Active"
                    status: "Desktop color scheme"
                    iconName: root.isDarkTheme ? "weather-clear-night-symbolic" : "weather-clear-symbolic"
                    iconColor: root.tooltipActiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: darkItem
                }
            }

            // 6. Do Not Disturb (DND) (when active)
            Item {
                id: dndItem
                visible: root.panelShowDnd && root.dndEnabled
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: "notifications-disabled-symbolic"
                    fallback: Qt.resolvedUrl("../icons/notifications-disabled-symbolic.svg")
                    isMask: true
                    color: root.activeIndicatorColor
                }

                MouseArea {
                    id: dndHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: dndHover.containsMouse && !root.isTrayExpanded
                    title: root.dndEnabled ? "Do Not Disturb" : "Notifications Active"
                    status: root.dndEnabled ? (root.dndUntilText ? ("Muted until " + root.dndUntilText) : "All alerts and sounds muted") : "Normal notification alerts"
                    iconName: "notifications-disabled-symbolic"
                    iconColor: root.tooltipActiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: dndItem
                }
            }

            // 7. Night Light (when active)
            Item {
                id: nightItem
                visible: root.panelShowNightLight && root.nightLightEnabled
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: "redshift-status-on-symbolic"
                    fallback: Qt.resolvedUrl("../icons/night-light-symbolic.svg")
                    isMask: true
                    color: root.activeIndicatorColor
                }

                MouseArea {
                    id: nightHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: nightHover.containsMouse && !root.isTrayExpanded
                    title: root.nightLightEnabled ? "Night Light Active" : "Night Light Off"
                    status: root.nightLightEnabled ? "Warm color temperature for eye comfort" : "Standard color temperature"
                    iconName: "redshift-status-on-symbolic"
                    iconColor: root.tooltipActiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: nightItem
                }
            }

            // 8. Power Mode: Performance or Power-Saver / Optimise (Balanced shows NO icon)
            Item {
                id: powerItem
                visible: root.panelShowPowerProfile && (root.powerProfile === "performance" || root.powerProfile === "power-saver")
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: root.powerProfileIconName
                    fallback: (root.powerProfile === "power-saver") ? Qt.resolvedUrl("../icons/power-profile-powersave-symbolic.svg") : Qt.resolvedUrl("../icons/power-profile-performance-symbolic.svg")
                    isMask: true
                    color: root.activeIndicatorColor
                }

                MouseArea {
                    id: powerHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: powerHover.containsMouse && !root.isTrayExpanded
                    title: (root.powerProfile === "performance") ? "Performance Mode" : ((root.powerProfile === "power-saver") ? "Power Saver Mode" : "Balanced Mode")
                    status: (root.powerProfile === "performance") ? "Maximum system performance" : ((root.powerProfile === "power-saver") ? "Optimizing battery lifespan" : "Standard performance & efficiency")
                    iconName: root.powerProfileIconName
                    iconColor: root.tooltipActiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: powerItem
                }
            }

            // 9. Hotspot (when active)
            Item {
                id: hotspotItem
                visible: root.panelShowHotspot && root.hotspotEnabled
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: "network-wireless-hotspot-symbolic"
                    fallback: Qt.resolvedUrl("../icons/network-wireless-hotspot-symbolic.svg")
                    isMask: true
                    color: root.activeIndicatorColor
                }

                MouseArea {
                    id: hotspotHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: hotspotHover.containsMouse && !root.isTrayExpanded
                    title: (root.hotspotSsid && root.hotspotSsid !== "") ? root.hotspotSsid : "Wi-Fi Hotspot"
                    status: root.hotspotPassword ? ("Password: " + root.hotspotPassword) : "Sharing internet connection"
                    iconName: "network-wireless-hotspot-symbolic"
                    iconColor: root.tooltipActiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: hotspotItem
                }
            }

            // 10. Airplane Mode (when active)
            Item {
                id: airItem
                visible: root.panelShowAirplane && root.airplaneMode
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: "network-flightmode-on-symbolic"
                    fallback: Qt.resolvedUrl("../icons/airplane-mode-symbolic.svg")
                    isMask: true
                    color: root.activeIndicatorColor
                }

                MouseArea {
                    id: airHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: airHover.containsMouse && !root.isTrayExpanded
                    title: root.airplaneMode ? "Airplane Mode Active" : "Airplane Mode Off"
                    status: root.airplaneMode ? "All wireless transmissions disabled" : "Wireless communications enabled"
                    iconName: "network-flightmode-on-symbolic"
                    iconColor: root.tooltipActiveColor
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: airItem
                }
            }

            // 11. Bluetooth (when enabled or connected)
            Item {
                id: btItem
                visible: root.panelShowBluetooth && (root.btEnabled || root.btConnected)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: root.btIconName
                    fallback: Qt.resolvedUrl("../icons/preferences-system-bluetooth-symbolic.svg")
                    isMask: true
                    color: root.btConnected ? root.activeIndicatorColor : root.inactiveIndicatorColor
                }

                MouseArea {
                    id: btHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: btHover.containsMouse && !root.isTrayExpanded
                    title: (root.btConnected && root.btDeviceName && root.btDeviceName !== "")
                        ? root.btDeviceName
                        : (root.btEnabled ? (root.btConnected ? "Connected Device" : "Not Connected") : "Bluetooth Off")
                    status: root.btConnected 
                        ? ((root.btBattery > 0) ? (root.btBattery + "% Battery • Connected") : "Device connected")
                        : (root.btEnabled ? "Click to connect devices" : "Bluetooth adapter disabled")
                    iconName: root.btIconName
                    iconColor: root.btConnected ? root.tooltipActiveColor : root.tooltipInactiveColor
                    showProgressBar: Boolean(root.btConnected && root.btBattery > 0)
                    progressValue: root.btBattery
                    progressColor: (root.btBattery <= 20) ? "#e74c3c" : "#33d17a"
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: btItem
                }
            }

            // 12. Wi-Fi (when enabled or connected)
            Item {
                id: wifiItem
                visible: root.panelShowWifi && (root.wifiConnected || root.wifiEnabled)
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: root.wifiIconName
                    fallback: Qt.resolvedUrl("../icons/network-wireless-symbolic.svg")
                    isMask: true
                    color: root.wifiConnected ? root.activeIndicatorColor : root.inactiveIndicatorColor
                }

                MouseArea {
                    id: wifiHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: wifiHover.containsMouse && !root.isTrayExpanded
                    title: (root.wifiConnected && root.wifiSsid && root.wifiSsid !== "" && root.wifiSsid !== "Checking...") 
                        ? root.wifiSsid 
                        : (root.wifiEnabled ? (root.wifiConnected ? "Connected Network" : "Disconnected") : "Wi-Fi Off")
                    status: root.wifiConnected 
                        ? (root.wifiSignal > 0 ? (root.wifiSignal + "% Signal Strength • Connected") : "Connected") 
                        : (root.wifiEnabled ? "Click to connect to a network" : "Wireless adapter disabled")
                    iconName: root.wifiIconName
                    iconColor: root.wifiConnected ? root.tooltipActiveColor : root.tooltipInactiveColor
                    showProgressBar: root.wifiConnected && root.wifiSignal > 0
                    progressValue: root.wifiSignal
                    progressColor: root.wifiSignal >= 60 ? "#33d17a" : (root.wifiSignal >= 30 ? "#f5a623" : "#e74c3c")
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: wifiItem
                }
            }

            // ========================================================
            // VOLUME INDICATOR (ICON ONLY, NO PERCENTAGE)
            // ========================================================
            Item {
                id: volItem
                visible: root.showVolume
                implicitWidth: root.panelIconSize
                implicitHeight: root.panelIconSize
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.fill: parent
                    source: root.volumeIconName
                    fallback: root.isMuted ? Qt.resolvedUrl("../icons/audio-volume-muted-symbolic.svg") : Qt.resolvedUrl("../icons/audio-volume-high-symbolic.svg")
                    isMask: true
                    color: root.isMuted ? root.inactiveIndicatorColor : root.activeIndicatorColor
                }

                MouseArea {
                    id: volHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: volHover.containsMouse && !root.isTrayExpanded
                    title: root.isMuted ? "Audio Muted" : (root.volume + "% Volume")
                    status: root.isMuted 
                        ? "Sound output is muted" 
                        : ((root.audioSinks && root.audioSinks.length > 0) 
                            ? (root.audioSinks.find(function(s){ return s.is_default }) 
                                ? root.audioSinks.find(function(s){ return s.is_default }).description 
                                : "Audio Output") 
                            : "Master Audio Output")
                    iconName: root.volumeIconName
                    iconColor: root.isMuted ? root.tooltipInactiveColor : root.tooltipActiveColor
                    showProgressBar: true
                    progressValue: root.isMuted ? 0 : root.volume
                    progressColor: root.isMuted ? (root.isDarkTheme ? "#777777" : "#999999") : ((Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4")
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: volItem
                }
            }

            // ========================================================
            // BATTERY INDICATOR + OPTIONAL PERCENTAGE (RIGHTMOST)
            // ========================================================
            Item {
                id: batItem
                visible: root.showBattery
                implicitWidth: batRow.implicitWidth
                implicitHeight: Math.max(root.panelIconSize, batRow.implicitHeight)
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    id: batRow
                    anchors.centerIn: parent
                    spacing: 4

                    Kirigami.Icon {
                        implicitWidth: root.panelIconSize
                        implicitHeight: root.panelIconSize
                        source: root.batteryIconName
                        fallback: root.batteryCharging ? Qt.resolvedUrl("../icons/battery-charging-symbolic.svg") : Qt.resolvedUrl("../icons/battery-symbolic.svg")
                        isMask: true
                        color: root.batteryLevel <= 20 && !root.batteryCharging ? "#e74c3c" : root.activeIndicatorColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        visible: root.showBatteryPercent
                        text: root.batteryLevel + "%"
                        font.pixelSize: Math.max(10, root.panelIconSize - 4)
                        font.weight: Font.Medium
                        color: root.batteryLevel <= 20 && !root.batteryCharging ? "#e74c3c" : root.activeIndicatorColor
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: batHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleQuickSettings()
                }

                StatusToolTip {
                    visible: batHover.containsMouse && !root.isTrayExpanded
                    title: root.batteryLevel + "% Battery" + (root.batteryCharging ? " (Charging)" : "")
                    status: root.batteryCharging 
                        ? "Power Adapter Connected • Charging" 
                        : (root.batteryLevel <= 20 ? "Battery Low • Connect Charger" : "Running on Battery Power")
                    iconName: root.batteryIconName
                    iconColor: root.batteryLevel <= 20 && !root.batteryCharging ? "#e74c3c" : root.tooltipActiveColor
                    showProgressBar: true
                    progressValue: root.batteryLevel
                    progressColor: root.batteryCharging ? "#33d17a" : (root.batteryLevel <= 20 ? "#e74c3c" : (root.isDarkTheme ? "#f6f8fa" : "#3584e4"))
                    isDarkTheme: root.isDarkTheme
                    panelLocation: root.panelLocation
                    capsuleItem: pillRect
                    targetItem: batItem
                }
            }
        }
    }
}
