import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.notificationmanager as NotificationManager

/**
 * main.qml - GNOME Quick Settings Control Center for KDE Plasma 6
 * Real system backend integration via Plasma5Support.DataSource and native CLI hooks.
 */
PlasmoidItem {
    id: mainItem

    preferredRepresentation: compactRepresentation

    Layout.fillWidth: false
    Layout.fillHeight: true
    Layout.preferredWidth: compactRepresentationItem ? compactRepresentationItem.implicitWidth : 36
    Layout.minimumWidth: compactRepresentationItem ? compactRepresentationItem.Layout.minimumWidth : 36
    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: 2
    Layout.rightMargin: 8

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {
        Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
        Plasmoid.userBackgroundHints: PlasmaCore.Types.NoBackground
    }

    // Dynamic System Theme Detection via Kirigami.Theme luminance:
    readonly property bool systemIsDark: {
        var bg = Kirigami.Theme.backgroundColor
        return (bg.r * 0.299 + bg.g * 0.587 + bg.b * 0.114) < 0.5
    }
    property bool manualThemeOverride: false
    property bool manualDark: false
    property bool isDarkTheme: manualThemeOverride ? manualDark : systemIsDark

    Connections {
        target: Kirigami.Theme
        function onColorsChanged() {
            mainItem.manualThemeOverride = false
            if (mainItem.fullRepresentationItem && typeof mainItem.fullRepresentationItem.removePlasmaBackground === "function") {
                mainItem.fullRepresentationItem.removePlasmaBackground()
                mainItem.fullRepresentationItem.syncWindowGeometry()
                mainItem.fullRepresentationItem.restartBackgroundFixTimers()
            }
        }
    }

    // Configuration Properties (persisted via KConfigXT)
    property bool showVolume: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showVolume !== undefined) ? plasmoid.configuration.showVolume : true
    property bool showBattery: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showBattery !== undefined) ? plasmoid.configuration.showBattery : true
    property bool showBatteryPercent: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showBatteryPercent !== undefined) ? plasmoid.configuration.showBatteryPercent : true
    property int panelIconSize: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelIconSize !== undefined) ? plasmoid.configuration.panelIconSize : 15
    property int tileIconSize: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileIconSize !== undefined) ? plasmoid.configuration.tileIconSize : 20

    // Panel Status Capsule Toggle Icons Visibility (persisted via KConfigXT)
    property bool panelShowWifi: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowWifi !== undefined) ? plasmoid.configuration.panelShowWifi : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showWifi !== undefined) ? plasmoid.configuration.showWifi : true)
    property bool panelShowBluetooth: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowBluetooth !== undefined) ? plasmoid.configuration.panelShowBluetooth : ((typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.showBluetooth !== undefined) ? plasmoid.configuration.showBluetooth : true)
    property bool panelShowNightLight: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowNightLight !== undefined) ? plasmoid.configuration.panelShowNightLight : true
    property bool panelShowAirplane: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowAirplane !== undefined) ? plasmoid.configuration.panelShowAirplane : true
    property bool panelShowDnd: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowDnd !== undefined) ? plasmoid.configuration.panelShowDnd : true
    property bool panelShowHotspot: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowHotspot !== undefined) ? plasmoid.configuration.panelShowHotspot : true
    property bool panelShowDarkTheme: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowDarkTheme !== undefined) ? plasmoid.configuration.panelShowDarkTheme : true
    property bool panelShowPowerProfile: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowPowerProfile !== undefined) ? plasmoid.configuration.panelShowPowerProfile : true
    property bool panelShowLocation: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowLocation !== undefined) ? plasmoid.configuration.panelShowLocation : true
    property bool panelShowCamera: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowCamera !== undefined) ? plasmoid.configuration.panelShowCamera : true
    property bool panelShowMic: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowMic !== undefined) ? plasmoid.configuration.panelShowMic : true
    property bool panelShowKdeConnect: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.panelShowKdeConnect !== undefined) ? plasmoid.configuration.panelShowKdeConnect : true

    // Quick Settings Tiles Visibility
    property bool tileShowWifi: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowWifi !== undefined) ? plasmoid.configuration.tileShowWifi : true
    property bool tileShowBluetooth: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowBluetooth !== undefined) ? plasmoid.configuration.tileShowBluetooth : true
    property bool tileShowNightLight: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowNightLight !== undefined) ? plasmoid.configuration.tileShowNightLight : true
    property bool tileShowAirplane: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowAirplane !== undefined) ? plasmoid.configuration.tileShowAirplane : true
    property bool tileShowDnd: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowDnd !== undefined) ? plasmoid.configuration.tileShowDnd : true
    property bool tileShowHotspot: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowHotspot !== undefined) ? plasmoid.configuration.tileShowHotspot : true
    property bool tileShowDarkTheme: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowDarkTheme !== undefined) ? plasmoid.configuration.tileShowDarkTheme : true
    property bool tileShowPowerSaver: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowPowerSaver !== undefined) ? plasmoid.configuration.tileShowPowerSaver : true
    property bool tileShowLocation: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowLocation !== undefined) ? plasmoid.configuration.tileShowLocation : true
    property bool tileShowCamera: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowCamera !== undefined) ? plasmoid.configuration.tileShowCamera : true
    property bool tileShowMic: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowMic !== undefined) ? plasmoid.configuration.tileShowMic : true
    property bool tileShowKdeConnect: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tileShowKdeConnect !== undefined) ? plasmoid.configuration.tileShowKdeConnect : true
    property string tilesOrder: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.tilesOrder !== undefined && plasmoid.configuration.tilesOrder.length > 0) ? plasmoid.configuration.tilesOrder : "wifi,bluetooth,location,mic,camera,kdeconnect,dark,night,airplane,dnd,hotspot,power"
    property int toggleRowsPerPage: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.toggleRowsPerPage !== undefined) ? Math.max(3, Math.min(8, plasmoid.configuration.toggleRowsPerPage)) : 4

    // Keep visibility properties synced when configuration changes
    Connections {
        target: (typeof plasmoid !== "undefined" && plasmoid.configuration) ? plasmoid.configuration : null
        function onTileShowWifiChanged() { mainItem.tileShowWifi = plasmoid.configuration.tileShowWifi }
        function onTileShowBluetoothChanged() { mainItem.tileShowBluetooth = plasmoid.configuration.tileShowBluetooth }
        function onTileShowNightLightChanged() { mainItem.tileShowNightLight = plasmoid.configuration.tileShowNightLight }
        function onTileShowAirplaneChanged() { mainItem.tileShowAirplane = plasmoid.configuration.tileShowAirplane }
        function onTileShowDndChanged() { mainItem.tileShowDnd = plasmoid.configuration.tileShowDnd }
        function onTileShowHotspotChanged() { mainItem.tileShowHotspot = plasmoid.configuration.tileShowHotspot }
        function onTileShowDarkThemeChanged() { mainItem.tileShowDarkTheme = plasmoid.configuration.tileShowDarkTheme }
        function onTileShowPowerSaverChanged() { mainItem.tileShowPowerSaver = plasmoid.configuration.tileShowPowerSaver }
        function onTileShowLocationChanged() { mainItem.tileShowLocation = plasmoid.configuration.tileShowLocation }
        function onTileShowCameraChanged() { mainItem.tileShowCamera = plasmoid.configuration.tileShowCamera }
        function onTileShowMicChanged() { mainItem.tileShowMic = plasmoid.configuration.tileShowMic }
        function onTileShowKdeConnectChanged() { mainItem.tileShowKdeConnect = plasmoid.configuration.tileShowKdeConnect }
        function onTilesOrderChanged() { mainItem.tilesOrder = plasmoid.configuration.tilesOrder }
        function onToggleRowsPerPageChanged() { mainItem.toggleRowsPerPage = Math.max(3, Math.min(8, plasmoid.configuration.toggleRowsPerPage)) }

        function onPanelShowWifiChanged() { mainItem.panelShowWifi = plasmoid.configuration.panelShowWifi }
        function onPanelShowBluetoothChanged() { mainItem.panelShowBluetooth = plasmoid.configuration.panelShowBluetooth }
        function onPanelShowNightLightChanged() { mainItem.panelShowNightLight = plasmoid.configuration.panelShowNightLight }
        function onPanelShowAirplaneChanged() { mainItem.panelShowAirplane = plasmoid.configuration.panelShowAirplane }
        function onPanelShowDndChanged() { mainItem.panelShowDnd = plasmoid.configuration.panelShowDnd }
        function onPanelShowHotspotChanged() { mainItem.panelShowHotspot = plasmoid.configuration.panelShowHotspot }
        function onPanelShowDarkThemeChanged() { mainItem.panelShowDarkTheme = plasmoid.configuration.panelShowDarkTheme }
        function onPanelShowPowerProfileChanged() { mainItem.panelShowPowerProfile = plasmoid.configuration.panelShowPowerProfile }
        function onPanelShowLocationChanged() { mainItem.panelShowLocation = plasmoid.configuration.panelShowLocation }
        function onPanelShowCameraChanged() { mainItem.panelShowCamera = plasmoid.configuration.panelShowCamera }
        function onPanelShowMicChanged() { mainItem.panelShowMic = plasmoid.configuration.panelShowMic }
        function onPanelShowKdeConnectChanged() { mainItem.panelShowKdeConnect = plasmoid.configuration.panelShowKdeConnect }
    }

    // Wi-Fi icon — follows the active system icon pack exactly
    readonly property string wifiIconName: {
        if (!mainItem.wifiEnabled || !mainItem.wifiConnected) {
            return "network-wireless-offline-symbolic"
        }
        var s = mainItem.wifiSignal
        if (s >= 75) return "network-wireless-signal-excellent-symbolic"
        if (s >= 50) return "network-wireless-signal-good-symbolic"
        if (s >= 25) return "network-wireless-signal-ok-symbolic"
        if (s >  0)  return "network-wireless-signal-weak-symbolic"
        return "network-wireless-symbolic"
    }

    // Dynamic Volume icon matching KDE Plasma System Tray
    readonly property string volumeIconName: {
        if (mainItem.isMuted || mainItem.volume === 0) {
            return "audio-volume-muted"
        }
        if (mainItem.volume > 66) {
            return "audio-volume-high"
        }
        if (mainItem.volume > 33) {
            return "audio-volume-medium"
        }
        return "audio-volume-low"
    }

    // Dynamic Bluetooth icon matching KDE Plasma System Tray
    readonly property string btIconName: {
        if (mainItem.btConnected) {
            return "network-bluetooth"
        }
        return "preferences-system-bluetooth"
    }

    // Dynamic Battery icon matching KDE Plasma System Tray
    readonly property string batteryIconName: {
        var level = Math.max(0, Math.min(100, Math.round(mainItem.batteryLevel / 10) * 10))
        var levelStr = ("000" + level).slice(-3)
        if (mainItem.batteryCharging) {
            return "battery-" + levelStr + "-charging"
        }
        return "battery-" + levelStr
    }

    // Dynamic Power Profile icon matching KDE Plasma
    readonly property string powerProfileIconName: {
        if (mainItem.powerProfile === "performance") {
            return "battery-profile-performance-symbolic"
        }
        if (mainItem.powerProfile === "power-saver") {
            return "battery-profile-powersave-symbolic"
        }
        return "battery-profile-balanced-symbolic"
    }

    // Device & Privacy States
    property bool locationEnabled: false
    property var locationApps: []
    property bool cameraBlocked: false
    property var cameraApps: []
    property bool micMuted: false
    property var micApps: []
    property bool kdeConnectConnected: false
    property string kdeConnectName: "No Device"
    property string kdeConnectId: ""
    property var kdeConnectDevices: []

    // Wi-Fi
    property bool wifiEnabled: false
    property bool wifiConnected: false
    property string wifiSsid: "Checking..."
    property int wifiSignal: 0
    property var wifiNetworks: []

    // Bluetooth
    property bool btEnabled: false
    property bool btConnected: false
    property string btDeviceName: ""
    property string btDeviceMac: ""
    property int btBattery: 0
    property var btDevices: []
    property bool btScanning: false
    property string btPairingMac: ""

    // Display & Sound
    property int volume: 50
    property bool isMuted: false
    property int brightness: 100

    // Toggles
    property bool nightLightEnabled: false
    property bool airplaneMode: false
    property bool dndEnabled: false
    property string dndMode: "until_off"
    property string dndUntilText: ""
    property bool hotspotEnabled: false
    property string hotspotSsid: ""
    property string hotspotPassword: ""
    property string powerProfile: "balanced"
    property bool powerSaverEnabled: powerProfile !== "balanced"

    // KDE Plasma native Notification Manager integration for real Do Not Disturb
    NotificationManager.Settings {
        id: notifSettings
        onSettingsChanged: {
            mainItem.syncDndState()
        }
    }

    // Battery
    property int batteryLevel: 100
    property bool batteryCharging: false

    // User Profile
    property string userRealName: "User"
    property string userName: "user"
    property string userAvatarPath: ""
    property string userRole: "Administrator"

    // Media
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaAlbumArt: ""
    property bool mediaPlaying: false
    property real mediaProgress: 0.0

    // Screenshot Tool
    property bool hasSpectacle: false
    property bool hasFlameshot: false
    property string screenshotTool: (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.screenshotTool !== undefined && plasmoid.configuration.screenshotTool !== "") ? plasmoid.configuration.screenshotTool : "auto"

    // Executable DataEngine to run system scripts natively in Plasma 6
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(source, data) {
            var stdout = data["stdout"] ? data["stdout"].trim() : ""
            disconnectSource(source)

            if (!stdout) return

            try {
                if (source.indexOf("network.sh") !== -1) {
                    if (source.indexOf("list_wifi") !== -1) {
                        var nList = JSON.parse(stdout)
                        if (Array.isArray(nList)) {
                            mainItem.wifiNetworks = nList
                        }
                    } else {
                        var net = JSON.parse(stdout)
                        if (net.wifi_enabled !== undefined) {
                            mainItem.wifiEnabled = !!net.wifi_enabled
                            mainItem.wifiConnected = !!net.connected
                            mainItem.wifiSsid = net.ssid || (net.connected ? "Connected" : "Disconnected")
                            mainItem.wifiSignal = parseInt(net.signal) || 0
                        }
                        if (net.hotspot) {
                            mainItem.hotspotEnabled = !!net.hotspot.hotspot_enabled
                            if (net.hotspot.ssid) mainItem.hotspotSsid = net.hotspot.ssid
                            if (net.hotspot.password) mainItem.hotspotPassword = net.hotspot.password
                        } else if (net.hotspot_enabled !== undefined) {
                            mainItem.hotspotEnabled = !!net.hotspot_enabled
                            if (net.ssid) mainItem.hotspotSsid = net.ssid
                            if (net.password) mainItem.hotspotPassword = net.password
                        }
                        // Refresh wifi list immediately on state changes if expanded
                        if (mainItem.expanded && source.indexOf("status") === -1) {
                            mainItem.refreshWifi()
                        }
                    }
                } else if (source.indexOf("audio.sh") !== -1) {
                    var aud = JSON.parse(stdout)
                    mainItem.volume = parseInt(aud.volume) || 0
                    mainItem.isMuted = !!aud.muted
                } else if (source.indexOf("brightness.sh") !== -1) {
                    var bri = JSON.parse(stdout)
                    mainItem.brightness = parseInt(bri.brightness) || 0
                } else if (source.indexOf("bluetooth.sh' status") !== -1 || source.indexOf("bluetooth.sh status") !== -1) {
                    var bt = JSON.parse(stdout)
                    mainItem.btEnabled = !!bt.enabled
                    mainItem.btConnected = !!bt.connected
                    mainItem.btDeviceName = bt.device_name || ""
                    mainItem.btDeviceMac = bt.device_mac || ""
                    mainItem.btBattery = parseInt(bt.battery) || 0
                } else if (source.indexOf("bluetooth.sh' devices") !== -1 || source.indexOf("bluetooth.sh devices") !== -1 || source.indexOf("bluetooth.sh' scan") !== -1 || source.indexOf("bluetooth.sh scan") !== -1) {
                    try {
                        var bList = JSON.parse(stdout)
                        if (Array.isArray(bList)) {
                            mainItem.btDevices = bList
                            if (mainItem.btPairingMac) {
                                var dev = bList.find(function(d) { return d.mac === mainItem.btPairingMac })
                                if (dev && (dev.paired || dev.connected)) {
                                    mainItem.btPairingMac = ""
                                }
                            }
                        }
                    } catch (e) {
                        console.warn("Could not parse Bluetooth devices JSON:", e)
                    }
                    mainItem.btScanning = false
                } else if (source.indexOf("power.sh") !== -1) {
                    var bat = JSON.parse(stdout)
                    if (bat.percentage !== undefined) {
                        mainItem.batteryLevel = parseInt(bat.percentage) || 100
                        mainItem.batteryCharging = !!bat.charging
                    }
                    if (bat.dark_mode !== undefined && !mainItem.manualThemeOverride) {
                        mainItem.manualDark = !!bat.dark_mode
                    }
                    if (bat.power_profile !== undefined) {
                        mainItem.powerProfile = bat.power_profile
                    }
                    if (bat.night_light !== undefined) {
                        mainItem.nightLightEnabled = !!bat.night_light
                    }
                } else if (source.indexOf("kdeconnect_list") !== -1 || source.indexOf("kdeconnect_devices") !== -1 || source.indexOf("kdeconnect_refresh") !== -1) {
                    var kList = JSON.parse(stdout)
                    if (Array.isArray(kList)) {
                        mainItem.kdeConnectDevices = kList
                        if (kList.length > 0) {
                            var firstActive = kList.find(function(d) { return d.paired && d.reachable }) || kList[0]
                            mainItem.kdeConnectConnected = !!(firstActive.paired && firstActive.reachable)
                            mainItem.kdeConnectName = firstActive.name || "Device"
                            mainItem.kdeConnectId = firstActive.id || ""
                        }
                    }
                } else if (source.indexOf("devices.sh") !== -1) {
                    var dev = JSON.parse(stdout)
                    if (dev.mic_muted !== undefined) mainItem.micMuted = !!dev.mic_muted
                    if (dev.mic_apps !== undefined) mainItem.micApps = dev.mic_apps
                    if (dev.location_enabled !== undefined) mainItem.locationEnabled = !!dev.location_enabled
                    if (dev.location_apps !== undefined) mainItem.locationApps = dev.location_apps
                    if (dev.camera_blocked !== undefined) mainItem.cameraBlocked = !!dev.camera_blocked
                    if (dev.camera_apps !== undefined) mainItem.cameraApps = dev.camera_apps
                    if (dev.kdeconnect) {
                        mainItem.kdeConnectConnected = !!dev.kdeconnect.connected
                        mainItem.kdeConnectName = dev.kdeconnect.device_name || "No Device"
                        mainItem.kdeConnectId = dev.kdeconnect.device_id || ""
                    }
                    if (dev.user) {
                        if (dev.user.user_real_name) mainItem.userRealName = dev.user.user_real_name
                        if (dev.user.user_name) mainItem.userName = dev.user.user_name
                        if (dev.user.user_avatar !== undefined) mainItem.userAvatarPath = dev.user.user_avatar
                        if (dev.user.user_role) mainItem.userRole = dev.user.user_role
                    }
                    if (dev.airplane_mode !== undefined) {
                        mainItem.airplaneMode = !!dev.airplane_mode
                    }
                    if (dev.has_spectacle !== undefined) mainItem.hasSpectacle = !!dev.has_spectacle
                    if (dev.has_flameshot !== undefined) mainItem.hasFlameshot = !!dev.has_flameshot
                }
            } catch (e) {
                // Ignore parse errors from background notifications
            }

        }

        function exec(cmd) {
            connectSource(cmd)
        }
    }

    function getScriptPath(scriptName) {
        var path = ""
        if (typeof plasmoid !== "undefined" && typeof plasmoid.file === "function") {
            path = plasmoid.file("scripts", scriptName)
        } else if (typeof Plasmoid !== "undefined" && typeof Plasmoid.file === "function") {
            path = Plasmoid.file("scripts", scriptName)
        }
        if (!path || path === "") {
            path = Qt.resolvedUrl("../scripts/" + scriptName).toString().replace(/^file:\/\//, "")
        }
        return path
    }

    function refreshAll() {
        executable.exec("bash '" + getScriptPath("network.sh") + "' status")
        executable.exec("bash '" + getScriptPath("audio.sh") + "' status")
        executable.exec("bash '" + getScriptPath("brightness.sh") + "' status")
        executable.exec("bash '" + getScriptPath("bluetooth.sh") + "' status")
        executable.exec("bash '" + getScriptPath("power.sh") + "' battery")
        executable.exec("bash '" + getScriptPath("devices.sh") + "' status")
        executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_list")
        syncDndState()
    }

    onExpandedChanged: {
        if (fullRepresentationItem && typeof fullRepresentationItem.resetToFreshMainView === "function") {
            fullRepresentationItem.resetToFreshMainView()
        } else if (fullRepresentationItem) {
            if (fullRepresentationItem.powerOverlay) fullRepresentationItem.powerOverlay.visible = false
            if (fullRepresentationItem.activeView !== undefined) fullRepresentationItem.activeView = "main"
        }
        if (mainItem.expanded) {
            refreshAll()
            executable.exec("bash '" + getScriptPath("network.sh") + "' list_wifi")
            executable.exec("bash '" + getScriptPath("bluetooth.sh") + "' devices")
            executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_list")
        }
        pollTimer.restart()
    }

    Component.onCompleted: {
        refreshAll()
        pollTimer.start()
    }

    Timer {
        id: pollTimer
        // Responsive 2s sync when tray is open, gentle 5s background sync when closed
        interval: mainItem.expanded ? 2000 : 5000
        repeat: true
        running: true
        onTriggered: {
            refreshAll()
            if (mainItem.expanded && fullRepresentationItem && fullRepresentationItem.activeView) {
                var av = fullRepresentationItem.activeView
                if (av === "network") {
                    executable.exec("bash '" + getScriptPath("network.sh") + "' list_wifi")
                } else if (av === "bluetooth") {
                    executable.exec("bash '" + getScriptPath("bluetooth.sh") + "' devices")
                } else if (av === "kdeconnect") {
                    executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_list")
                }
            }
        }
    }


    // Actions & Methods connected directly to system scripts
    function toggleWifi(enabled) {
        mainItem.wifiEnabled = enabled
        if (enabled && mainItem.hotspotEnabled) {
            mainItem.hotspotEnabled = false
        }
        executable.exec("bash '" + getScriptPath("network.sh") + "' toggle " + (enabled ? "on" : "off"))
    }

    function connectWifi(ssid) {
        if (mainItem.hotspotEnabled) {
            mainItem.hotspotEnabled = false
        }
        executable.exec("bash '" + getScriptPath("network.sh") + "' connect '" + ssid + "'")
    }

    function refreshWifi() {
        executable.exec("bash '" + getScriptPath("network.sh") + "' list_wifi rescan")
    }

    function toggleBluetooth(enabled) {
        mainItem.btEnabled = enabled
        executable.exec("bash '" + getScriptPath("bluetooth.sh") + "' toggle " + (enabled ? "on" : "off"))
    }

    function refreshBluetoothDevices() {
        executable.exec("bash '" + getScriptPath("bluetooth.sh") + "' devices")
    }

    function scanBluetooth() {
        mainItem.btScanning = true
        executable.exec("bash '" + getScriptPath("bluetooth.sh") + "' scan")
    }

    function toggleBtDevice(mac, currentlyConnected) {
        if (currentlyConnected) {
            executable.exec("bash '" + getScriptPath("bluetooth.sh") + "' disconnect '" + mac + "'")
        } else {
            executable.exec("bash '" + getScriptPath("bluetooth.sh") + "' connect '" + mac + "'")
        }
        btRefreshTimer.start()
    }

    Timer {
        id: btRefreshTimer
        interval: 1500
        repeat: false
        onTriggered: refreshBluetoothDevices()
    }

    function pairBtDevice(mac) {
        openBluetoothSettings()
    }

    function openBluetoothSettings() {
        executable.exec("bash '" + getScriptPath("bluetooth.sh") + "' open_settings")
        closePopup()
    }

    function setVolume(val) {
        mainItem.volume = val
        if (val > 0) mainItem.isMuted = false
        executable.exec("bash '" + getScriptPath("audio.sh") + "' set_volume " + val)
    }

    function toggleMute() {
        mainItem.isMuted = !mainItem.isMuted
        executable.exec("bash '" + getScriptPath("audio.sh") + "' toggle_mute")
    }

    function setBrightness(val) {
        mainItem.brightness = val
        executable.exec("bash '" + getScriptPath("brightness.sh") + "' set " + val)
    }

    function toggleDarkMode(isDark) {
        mainItem.manualThemeOverride = true
        mainItem.manualDark = isDark
        executable.exec("bash '" + getScriptPath("power.sh") + "' darkmode " + (isDark ? "dark" : "light"))
    }

    function toggleNightLight(active) {
        mainItem.nightLightEnabled = active
        executable.exec("bash '" + getScriptPath("power.sh") + "' nightlight")
    }

    function toggleAirplaneMode(active) {
        mainItem.airplaneMode = active
        executable.exec("bash '" + getScriptPath("devices.sh") + "' toggle_airplane")
        refreshAll()
    }

    function syncDndState() {
        try {
            var until = notifSettings.notificationsInhibitedUntil
            if (!until || isNaN(until.getTime()) || until.getTime() <= Date.now()) {
                mainItem.dndEnabled = false
                mainItem.dndUntilText = ""
                mainItem.dndMode = "off"
                return
            }
            mainItem.dndEnabled = true
            var diffMs = until.getTime() - Date.now()
            var diffHours = diffMs / (1000 * 60 * 60)

            if (diffHours > 24 * 30) {
                mainItem.dndMode = "until_off"
                mainItem.dndUntilText = "Until turned off"
            } else {
                var h = until.getHours()
                var m = until.getMinutes()
                var timeStr = (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m)
                mainItem.dndUntilText = "Until " + timeStr
                if (Math.abs(diffHours - 1) < 0.15) {
                    mainItem.dndMode = "1h"
                } else if (Math.abs(diffHours - 4) < 0.15) {
                    mainItem.dndMode = "4h"
                }
            }
        } catch (e) {
            console.warn("Could not sync DND state:", e)
        }
    }

    function setDndMode(mode) {
        try {
            var targetDate = new Date()

            if (mode === "off") {
                notifSettings.notificationsInhibitedUntil = new Date(0)
                notifSettings.save()
                syncDndState()
                return
            }

            if (mode === "1h") {
                targetDate.setHours(targetDate.getHours() + 1)
                mainItem.dndMode = "1h"
            } else if (mode === "4h") {
                targetDate.setHours(targetDate.getHours() + 4)
                mainItem.dndMode = "4h"
            } else if (mode === "evening") {
                if (targetDate.getHours() >= 18) {
                    targetDate.setDate(targetDate.getDate() + 1)
                    targetDate.setHours(7, 0, 0, 0)
                } else {
                    targetDate.setHours(18, 0, 0, 0)
                }
                mainItem.dndMode = "evening"
            } else if (mode === "tomorrow") {
                targetDate.setDate(targetDate.getDate() + 1)
                targetDate.setHours(7, 0, 0, 0)
                mainItem.dndMode = "tomorrow"
            } else if (mode === "monday") {
                var daysUntilMonday = ((1 + 7 - targetDate.getDay()) % 7) || 7
                targetDate.setDate(targetDate.getDate() + daysUntilMonday)
                targetDate.setHours(7, 0, 0, 0)
                mainItem.dndMode = "monday"
            } else {
                // Until manually turned off (1 year in future)
                targetDate.setFullYear(targetDate.getFullYear() + 1)
                mainItem.dndMode = "until_off"
            }

            notifSettings.notificationsInhibitedUntil = targetDate
            notifSettings.save()
            syncDndState()
        } catch (e) {
            console.warn("Could not set DND mode:", e)
        }
    }

    function toggleDnd(active) {
        if (active === undefined) {
            active = !mainItem.dndEnabled
        }
        if (active) {
            setDndMode("until_off")
        } else {
            setDndMode("off")
        }
    }

    function toggleHotspot(active) {
        var arg = (active !== undefined) ? (active ? "on" : "off") : "toggle"
        if (active || (active === undefined && !mainItem.hotspotEnabled)) {
            mainItem.wifiEnabled = false
            mainItem.wifiConnected = false
            mainItem.hotspotEnabled = true
        } else {
            mainItem.hotspotEnabled = false
        }
        executable.exec("bash '" + getScriptPath("network.sh") + "' toggle_hotspot " + arg)
    }

    function refreshHotspot() {
        executable.exec("bash '" + getScriptPath("network.sh") + "' hotspot_status")
    }

    function openHotspotSettings() {
        executable.exec("bash '" + getScriptPath("network.sh") + "' open_hotspot_settings")
    }

    function setPowerProfile(profile) {
        mainItem.powerProfile = profile
        executable.exec("bash '" + getScriptPath("power.sh") + "' set_profile '" + profile + "'")
    }

    function togglePowerSaver(active) {
        if (active) {
            setPowerProfile("power-saver")
            if (mainItem.brightness > 50) {
                setBrightness(40)
            }
        } else {
            setPowerProfile("balanced")
        }
    }

    function setWidgetConfig(key, value) {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
            plasmoid.configuration[key] = value
        } else if (typeof Plasmoid !== "undefined" && Plasmoid.configuration) {
            Plasmoid.configuration[key] = value
        }
        mainItem[key] = value
    }

    function openUserManagement() {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' open_user_management")
        if (mainItem.hideOnWindowDeactivate) {
            mainItem.expanded = false
        }
    }

    function openWidgetSettings() {
        var act = null
        try {
            if (typeof Plasmoid !== "undefined" && typeof Plasmoid.internalAction === "function") {
                act = Plasmoid.internalAction("configure")
            } else if (typeof plasmoid !== "undefined" && typeof plasmoid.internalAction === "function") {
                act = plasmoid.internalAction("configure")
            }
        } catch (e) {
            console.warn("Could not retrieve internal configure action:", e)
        }

        if (act && typeof act.trigger === "function") {
            act.trigger()
            closePopupTimer.start()
            return true
        }
        return false
    }

    Timer {
        id: closePopupTimer
        interval: 100
        repeat: false
        onTriggered: {
            mainItem.expanded = false
        }
    }

    function closePopup() {
        closePopupTimer.start()
    }

    function openSettings() {
        return openSystemSettings()
    }

    function openSystemSettings() {
        executable.exec("bash '" + getScriptPath("power.sh") + "' settings")
        closePopupTimer.start()
    }

    function lockScreen() {
        executable.exec("bash '" + getScriptPath("power.sh") + "' lock")
    }

    function logoutSession() {
        executable.exec("bash '" + getScriptPath("power.sh") + "' logout")
    }

    function suspendSystem() {
        executable.exec("bash '" + getScriptPath("power.sh") + "' suspend")
    }

    function rebootSystem() {
        executable.exec("bash '" + getScriptPath("power.sh") + "' reboot")
    }

    function shutdownSystem() {
        executable.exec("bash '" + getScriptPath("power.sh") + "' shutdown")
    }

    function triggerScreenshot() {
        closePopup()
        var tool = mainItem.screenshotTool
        if (tool === "auto") {
            if (mainItem.hasFlameshot && !mainItem.hasSpectacle) tool = "flameshot"
            else tool = "spectacle"
        }
        executable.exec("bash '" + getScriptPath("devices.sh") + "' screenshot '" + tool + "'")
    }

    function toggleMediaPlay() {
        mainItem.mediaPlaying = !mainItem.mediaPlaying
    }

    function mediaPrevious() {
        mainItem.mediaProgress = 0.0
    }

    function mediaNext() {
        mainItem.mediaProgress = 0.0
    }

    function seekMedia(ratio) {
        mainItem.mediaProgress = ratio
    }

    function toggleMic() {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' toggle_mic")
    }

    function refreshMic() {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' mic_apps")
    }

    function stopMicApp(pid) {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' stop_mic_app " + pid)
    }

    function toggleLocation() {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' toggle_location")
    }

    function refreshLocation() {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' location_apps")
    }

    function stopLocationApp(pid) {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' stop_location_app " + pid)
    }

    function toggleCamera() {
        mainItem.cameraBlocked = !mainItem.cameraBlocked
        executable.exec("bash '" + getScriptPath("devices.sh") + "' toggle_camera")
    }

    function refreshCamera() {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' camera_apps")
    }

    function stopCameraApp(pid) {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' stop_camera_app " + pid)
    }

    function openKdeConnect() {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_open")
    }

    function refreshKdeConnect() {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_refresh")
    }

    function ringKdeConnect(devId) {
        var id = devId || mainItem.kdeConnectId
        if (id) {
            executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_ring '" + id + "'")
        } else {
            openKdeConnect()
        }
    }

    function pingKdeConnect(devId) {
        var id = devId || mainItem.kdeConnectId
        if (id) {
            executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_ping '" + id + "'")
        }
    }

    function shareKdeConnect(devId) {
        var id = devId || mainItem.kdeConnectId
        if (id) {
            executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_share '" + id + "'")
        }
    }

    function smsKdeConnect() {
        executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_sms")
    }

    function browseKdeConnect(devId) {
        var id = devId || mainItem.kdeConnectId
        if (id) {
            executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_browse '" + id + "'")
        }
    }

    function pairKdeConnect(devId) {
        if (devId) {
            executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_pair '" + devId + "'")
            kdeRefreshTimer.start()
        }
    }

    function unpairKdeConnect(devId) {
        if (devId) {
            executable.exec("bash '" + getScriptPath("devices.sh") + "' kdeconnect_unpair '" + devId + "'")
            kdeRefreshTimer.start()
        }
    }

    Timer {
        id: kdeRefreshTimer
        interval: 1500
        repeat: false
        onTriggered: refreshKdeConnect()
    }

    function toggleBatteryPercent() {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
            plasmoid.configuration.showBatteryPercent = !mainItem.showBatteryPercent
        } else {
            mainItem.showBatteryPercent = !mainItem.showBatteryPercent
        }
    }

    function toggleVolumePercent() {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
            plasmoid.configuration.showVolumePercent = !mainItem.showVolumePercent
        } else {
            mainItem.showVolumePercent = !mainItem.showVolumePercent
        }
    }
}
