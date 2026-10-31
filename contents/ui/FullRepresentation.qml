import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "./components"
import "./views"
import "./plugin"

/**
 * FullRepresentation.qml - GNOME Quick Settings Control Center for KDE Plasma (Plasma 6)
 * Features:
 *   - Glassmorphic card with rounded outer corners (radius: 24px)
 *   - Top bar: Live clock, Battery capsule, Settings, Lock, Power menu
 *   - Sliders: Audio Volume & Display Brightness
 *   - 2-Column Curved Pill Toggles with configurable visibility
 *   - Real toggles for Location, Camera, Microphone, and KDE Connect
 *   - Wi-Fi signal strength dynamic icon
 *   - MPRIS Media Player widget
 *   - Sub-views for Wi-Fi and Bluetooth
 */
Rectangle {
    id: root

    // Reference to mainItem holding state
    property var backend: mainItem

    property bool isDarkTheme: backend ? backend.isDarkTheme : true
    property string activeView: "main" // "main" | "network" | "bluetooth" | "camera" | "kdeconnect" | "power" | "dnd" | "settings"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.userBackgroundHints: PlasmaCore.Types.NoBackground

    WindowHelper {
        id: winHelper
    }

    property var _winHelperInstance: null

    function applyWindowMaskAndBlur() {
        var helper = null
        if (typeof winHelper !== "undefined" && winHelper) {
            helper = winHelper
        } else if (root._winHelperInstance) {
            helper = root._winHelperInstance
        } else {
            try {
                root._winHelperInstance = Qt.createQmlObject('import GnomeQuickSettingsPlugin; WindowHelper {}', root, "winHelperDynamic")
                helper = root._winHelperInstance
            } catch (e1) {
                try {
                    root._winHelperInstance = Qt.createQmlObject('import GnomeQuickSettingsPlugin 1.0; WindowHelper {}', root, "winHelperDynamic")
                    helper = root._winHelperInstance
                } catch (e2) {}
            }
        }

        if (helper) {
            try {
                helper.applyMask(root, 24, true)
            } catch (e) {}
        }
    }

    function getCardBgSvgPath() {
        var p = ""
        if (backend && typeof backend.getScriptPath === "function") {
            var sPath = backend.getScriptPath("audio.sh")
            if (sPath) {
                p = sPath.replace(/\/scripts\/[^\/]+$/, "/assets/card_background.svg")
            }
        }
        if (!p || p === "") {
            p = Qt.resolvedUrl("../assets/card_background.svg").toString().replace(/^file:\/\//, "")
        }
        return p
    }

    // Safe tracking for hooked items to prevent modifying C++ QObject dynamic properties
    property var _hookedItemsRegistry: []

    function isHooked(obj, key) {
        if (!obj) return true
        for (var i = 0; i < root._hookedItemsRegistry.length; ++i) {
            var item = root._hookedItemsRegistry[i]
            if (item.obj === obj && item.key === key) return true
        }
        return false
    }

    function recordHook(obj, key) {
        if (!obj) return
        root._hookedItemsRegistry.push({ obj: obj, key: key })
    }

    // Configure Plasma dialog background with exact 24px curved mask and sync popup window geometry
    function makeItemFullyTransparent(item) {
        if (!item) return
        try {
            item.visible = false
            item.opacity = 0
            if (item.imagePath !== undefined) item.imagePath = ""
            if (item.prefix !== undefined) item.prefix = ""
            if (item.elementId !== undefined) item.elementId = ""
            if (!isHooked(item, "transparency")) {
                recordHook(item, "transparency")
                if (item.visibleChanged) {
                    item.visibleChanged.connect(function() {
                        if (item.visible) item.visible = false
                    })
                }
                if (item.opacityChanged) {
                    item.opacityChanged.connect(function() {
                        if (item.opacity !== 0) item.opacity = 0
                    })
                }
                if (item.imagePathChanged) {
                    item.imagePathChanged.connect(function() {
                        if (item.imagePath !== "") item.imagePath = ""
                    })
                }
                if (item.prefixChanged) {
                    item.prefixChanged.connect(function() {
                        if (item.prefix !== "") item.prefix = ""
                    })
                }
            }
            if (item.children) {
                for (var i = 0; i < item.children.length; ++i) {
                    makeItemFullyTransparent(item.children[i])
                }
            }
        } catch (e) {
        }
    }

    // Completely eliminate native Plasma dialog background, borders, and shadows
    function removePlasmaBackground() {
        var win = null
        try {
            if (Window.window) win = Window.window
        } catch (e) {}
        if (!win && root.Window && root.Window.window) {
            win = root.Window.window
        }

        var topItem = null
        var p = root.parent
        while (p) {
            topItem = p
            if (!win && p.Window && p.Window.window) {
                win = p.Window.window
            }
            try {
                if (p !== root && p.parent && p.parent.children) {
                    for (var k = 0; k < p.parent.children.length; ++k) {
                        var sib = p.parent.children[k]
                        if (sib !== p && sib !== root) {
                            makeItemFullyTransparent(sib)
                        }
                    }
                }
            } catch (e) {}
            p = p.parent
        }

        try {
            if (topItem && !isHooked(topItem, "children")) {
                recordHook(topItem, "children")
                if (topItem.childrenChanged) {
                    topItem.childrenChanged.connect(function() {
                        root.removePlasmaBackground()
                        root.restartBackgroundFixTimers()
                    })
                }
            }
        } catch (e) {}

        if (win) {
            try {
                win.borders = 0
                if (win.backgroundHints !== undefined && win.backgroundHints !== 0) {
                    win.backgroundHints = 0
                }
                if (win.color !== undefined) {
                    win.color = "transparent"
                }
            } catch (e) {}

            try {
                if (win.contentItem && !isHooked(win.contentItem, "children")) {
                    recordHook(win.contentItem, "children")
                    if (win.contentItem.childrenChanged) {
                        win.contentItem.childrenChanged.connect(function() {
                            root.removePlasmaBackground()
                            root.restartBackgroundFixTimers()
                        })
                    }
                }
                if (win.contentItem && win.contentItem.children) {
                    for (var m = win.contentItem.children.length - 1; m >= 0; --m) {
                        var wChild = win.contentItem.children[m]
                        if (wChild !== root.parent && wChild !== root && wChild !== topItem) {
                            var wcName = wChild.toString()
                            if (wcName.indexOf("Overlay") === -1) {
                                makeItemFullyTransparent(wChild)
                            }
                        }
                    }
                }
            } catch (err) {}

            try {
                if (!isHooked(win, "winSignals")) {
                    recordHook(win, "winSignals")
                    if (win.bordersChanged) {
                        win.bordersChanged.connect(function() {
                            if (win.borders !== 0) win.borders = 0
                        })
                    }
                    if (win.backgroundHintsChanged) {
                        win.backgroundHintsChanged.connect(function() {
                            if (win.backgroundHints !== 0) win.backgroundHints = 0
                        })
                    }
                    if (win.colorChanged) {
                        win.colorChanged.connect(function() {
                            if (win.color.toString() !== "#00000000") win.color = "transparent"
                        })
                    }
                    if (win.widthChanged) {
                        win.widthChanged.connect(function() {
                            root.removePlasmaBackground()
                            root.applyWindowMaskAndBlur()
                        })
                    }
                    if (win.heightChanged) {
                        win.heightChanged.connect(function() {
                            root.removePlasmaBackground()
                            root.applyWindowMaskAndBlur()
                        })
                    }
                }
            } catch (e) {}
        }

        // Make DialogBackground and all underlying FrameSvgItems 100% transparent
        try {
            if (topItem && topItem.children) {
                for (var i = topItem.children.length - 1; i >= 0; --i) {
                    var child = topItem.children[i]
                    if (child !== root.parent && child !== root) {
                        var cName = child.toString()
                        if (cName.indexOf("Overlay") === -1) {
                            makeItemFullyTransparent(child)
                        }
                    }
                }
            }
        } catch (e) {}

        // Align appletParent at (0, 0) and remove extra dimensions with persistent hooks
        if (root.parent) {
            try {
                root.parent.x = 0
                root.parent.y = 0
                root.parent.extraHeight = 0
                root.parent.extraWidth = 0
                if (!isHooked(root.parent, "dims")) {
                    recordHook(root.parent, "dims")
                    if (root.parent.extraHeightChanged) {
                        root.parent.extraHeightChanged.connect(function() {
                            if (root.parent.extraHeight !== 0) root.parent.extraHeight = 0
                        })
                    }
                    if (root.parent.extraWidthChanged) {
                        root.parent.extraWidthChanged.connect(function() {
                            if (root.parent.extraWidth !== 0) root.parent.extraWidth = 0
                        })
                    }
                    if (root.parent.xChanged) {
                        root.parent.xChanged.connect(function() {
                            if (root.parent.x !== 0) root.parent.x = 0
                        })
                    }
                    if (root.parent.yChanged) {
                        root.parent.yChanged.connect(function() {
                            if (root.parent.y !== 0) root.parent.y = 0
                        })
                    }
                }
            } catch (e) {}

            try {
                if (root.parent.children) {
                    for (var j = 0; j < root.parent.children.length; ++j) {
                        var pChild = root.parent.children[j]
                        if (pChild !== root) {
                            makeItemFullyTransparent(pChild)
                        }
                    }
                }
                if (!isHooked(root.parent, "children")) {
                    recordHook(root.parent, "children")
                    if (root.parent.childrenChanged) {
                        root.parent.childrenChanged.connect(function() {
                            root.removePlasmaBackground()
                            root.restartBackgroundFixTimers()
                        })
                    }
                }
            } catch (e) {}
        }

        root.applyWindowMaskAndBlur()
    }

    function syncWindowGeometry() {
        var win = null
        try {
            if (Window.window) win = Window.window
        } catch (e) {}
        if (!win && root.Window && root.Window.window) {
            win = root.Window.window
        }
        if (win) {
            try {
                win.width = 390
                win.height = root.currentContentHeight
            } catch (e) {
                console.warn("Could not sync popup window geometry:", e)
            }
        }
        removePlasmaBackground()
        applyWindowMaskAndBlur()
    }

    function restartBackgroundFixTimers() {
        bgFixTimer.restart()
        bgMidFixTimer.restart()
        bgAnimFixTimer.restart()
        bgFinalFixTimer.restart()
        bgThemeFixTimer1.restart()
        bgThemeFixTimer2.restart()
    }

    function resetToFreshMainView() {
        if (powerOverlay) {
            powerOverlay.visible = false
        }
        if (typeof togglesSwipeView !== "undefined" && togglesSwipeView) {
            togglesSwipeView.currentIndex = 0
        }
        root.activeView = "main"
    }

    Component.onCompleted: {
        resetToFreshMainView()
        updateTogglePages()
        syncWindowGeometry()
        removePlasmaBackground()
        restartBackgroundFixTimers()
    }
    onWindowChanged: {
        syncWindowGeometry()
        removePlasmaBackground()
        restartBackgroundFixTimers()
    }
    onParentChanged: {
        syncWindowGeometry()
        removePlasmaBackground()
        restartBackgroundFixTimers()
    }
    onActiveViewChanged: {
        if (powerOverlay) powerOverlay.visible = false
        syncWindowGeometry()
        removePlasmaBackground()
        restartBackgroundFixTimers()
    }
    onIsDarkThemeChanged: {
        syncWindowGeometry()
        removePlasmaBackground()
        restartBackgroundFixTimers()
    }
    onVisibleChanged: {
        resetToFreshMainView()
        if (visible) {
            syncWindowGeometry()
            removePlasmaBackground()
            restartBackgroundFixTimers()
        }
    }

    Connections {
        target: backend
        ignoreUnknownSignals: true
        function onExpandedChanged() {
            resetToFreshMainView()
            if (backend && backend.expanded) {
                root.removePlasmaBackground()
                root.syncWindowGeometry()
                root.restartBackgroundFixTimers()
            }
        }
    }

    Connections {
        target: Kirigami.Theme
        function onColorsChanged() {
            root.syncWindowGeometry()
            root.removePlasmaBackground()
            root.restartBackgroundFixTimers()
        }
    }

    Timer {
        id: bgFixTimer
        interval: 30
        repeat: false
        onTriggered: {
            root.syncWindowGeometry()
            root.removePlasmaBackground()
            root.applyWindowMaskAndBlur()
        }
    }

    Timer {
        id: bgMidFixTimer
        interval: 100
        repeat: false
        onTriggered: {
            root.syncWindowGeometry()
            root.removePlasmaBackground()
            root.applyWindowMaskAndBlur()
        }
    }

    Timer {
        id: bgAnimFixTimer
        interval: 250
        repeat: false
        onTriggered: {
            root.syncWindowGeometry()
            root.removePlasmaBackground()
            root.applyWindowMaskAndBlur()
        }
    }

    Timer {
        id: bgFinalFixTimer
        interval: 500
        repeat: false
        onTriggered: {
            root.syncWindowGeometry()
            root.removePlasmaBackground()
            root.applyWindowMaskAndBlur()
        }
    }

    Timer {
        id: bgThemeFixTimer1
        interval: 850
        repeat: false
        onTriggered: {
            root.syncWindowGeometry()
            root.removePlasmaBackground()
            root.applyWindowMaskAndBlur()
        }
    }

    Timer {
        id: bgThemeFixTimer2
        interval: 1500
        repeat: false
        onTriggered: {
            root.syncWindowGeometry()
            root.removePlasmaBackground()
            root.applyWindowMaskAndBlur()
        }
    }

    // Dynamic Height Calculation: Configurable toggle rows per page (min 3, max 8)
    readonly property int maxRowsPerPage: (backend && backend.toggleRowsPerPage) ? Math.max(3, Math.min(8, backend.toggleRowsPerPage)) : 4
    readonly property int tilesPerPage: maxRowsPerPage * 2
    readonly property int togglePageCount: Math.max(1, Math.ceil(activeTileKeys.length / tilesPerPage))
    readonly property int visibleRowsOnPage: {
        var totalTiles = activeTileKeys.length
        if (totalTiles === 0) return 0
        if (totalTiles >= tilesPerPage) return maxRowsPerPage
        return Math.ceil(totalTiles / 2)
    }

    onMaxRowsPerPageChanged: {
        updateTogglePages()
    }
    onTogglePageCountChanged: {
        updateTogglePages()
    }

    readonly property real mainCalculatedHeight: {
        var tileH = (backend && backend.tileIconSize) ? Math.max(56, backend.tileIconSize + 36) : 56
        var togglesH = visibleRowsOnPage > 0 ? (visibleRowsOnPage * tileH + Math.max(0, visibleRowsOnPage - 1) * 10) : 0
        var dotsH = (togglePageCount > 1) ? 18 : 0
        var hasMedia = (backend && backend.mediaTitle && backend.mediaTitle !== "")
        var mediaH = hasMedia ? (14 + 70) : 0
        // Top bar (32) + Gap (14) + Sliders (56) + (Gap 14 if toggles) + togglesH + dotsH + mediaH + Margins (28)
        var exactH = 32 + 14 + 56 + (visibleRowsOnPage > 0 ? (14 + togglesH) : 0) + dotsH + mediaH + 28
        if (mainCol && mainCol.implicitHeight > 0) {
            return Math.max(180, Math.min(Math.max(exactH, mainCol.implicitHeight + 28), 950))
        }
        return Math.max(180, Math.min(exactH, 950))
    }

    readonly property real currentContentHeight: {
        if (root.activeView === "main") return mainCalculatedHeight
        if (root.activeView === "power") return 360
        if (root.activeView === "hotspot") return 360
        if (root.activeView === "dnd") return (backend && backend.dndEnabled) ? 440 : 360
        if (root.activeView === "camera") return 400
        if (root.activeView === "microphone") return 400
        if (root.activeView === "location") return 400
        if (root.activeView === "settings") return 540
        return 500 // network, bluetooth, kdeconnect
    }

    onCurrentContentHeightChanged: {
        syncWindowGeometry()
        removePlasmaBackground()
        applyWindowMaskAndBlur()
        restartBackgroundFixTimers()
    }

    function isTileEnabled(k) {
        if (!backend) return true
        switch (k) {
        case "wifi": return backend.tileShowWifi
        case "bluetooth": return backend.tileShowBluetooth
        case "location": return backend.tileShowLocation
        case "mic": return backend.tileShowMic
        case "camera": return backend.tileShowCamera
        case "kdeconnect": return backend.tileShowKdeConnect
        case "dark": return backend.tileShowDarkTheme
        case "night": return backend.tileShowNightLight
        case "airplane": return backend.tileShowAirplane
        case "dnd": return backend.tileShowDnd
        case "hotspot": return backend.tileShowHotspot
        case "power": return backend.tileShowPowerSaver
        default: return true
        }
    }

    readonly property var orderedTileKeys: {
        var str = (backend && backend.tilesOrder && backend.tilesOrder.length > 0) ? backend.tilesOrder : "wifi,bluetooth,location,mic,camera,kdeconnect,dark,night,airplane,dnd,hotspot,power"
        var parts = str.split(",")
        var res = []
        var valid = allToggleKeys
        for (var i = 0; i < parts.length; ++i) {
            var k = parts[i].trim()
            if (valid.indexOf(k) !== -1 && res.indexOf(k) === -1) {
                res.push(k)
            }
        }
        for (var j = 0; j < valid.length; ++j) {
            if (res.indexOf(valid[j]) === -1) {
                res.push(valid[j])
            }
        }
        return res
    }

    // Track active toggles in customized order to calculate rows & pages
    readonly property var activeTileKeys: {
        var list = []
        var order = orderedTileKeys
        for (var i = 0; i < order.length; ++i) {
            var k = order[i]
            if (isTileEnabled(k)) {
                list.push(k)
            }
        }
        return list
    }

    onActiveTileKeysChanged: {
        updateTogglePages()
    }

    // Standard fixed half-width for toggles: 2 per row. Odd toggle remains half-width, leaving the right slot empty.
    function tileWidth() {
        return 176
    }

    function getToggleByKey(k) {
        switch (k) {
        case "wifi": return toggleWifi
        case "bluetooth": return toggleBt
        case "location": return toggleLocation
        case "mic": return toggleMic
        case "camera": return toggleCamera
        case "kdeconnect": return toggleKde
        case "dark": return toggleDark
        case "night": return toggleNight
        case "airplane": return toggleAir
        case "dnd": return toggleDnd
        case "hotspot": return toggleHotspot
        case "power": return togglePower
        default: return null
        }
    }

    readonly property var allToggleKeys: ["wifi", "bluetooth", "location", "mic", "camera", "kdeconnect", "dark", "night", "airplane", "dnd", "hotspot", "power"]

    function syncSwipePages() {
        if (typeof togglesSwipeView === "undefined" || !togglesSwipeView || typeof page2Item === "undefined" || typeof page3Item === "undefined" || typeof hiddenPagesContainer === "undefined") return
        var count = root.togglePageCount // 1, 2, or 3
        
        // Page 2
        var hasPage2 = (togglesSwipeView.count >= 2 && togglesSwipeView.itemAt(1) === page2Item)
        if (count >= 2) {
            if (!hasPage2) togglesSwipeView.addItem(page2Item)
        } else {
            if (hasPage2) {
                var p2 = togglesSwipeView.takeItem(1)
                if (p2) p2.parent = hiddenPagesContainer
            }
        }
        
        // Page 3
        var hasPage3 = (togglesSwipeView.count >= 3 && togglesSwipeView.itemAt(2) === page3Item)
        if (count >= 3) {
            if (!hasPage3) togglesSwipeView.addItem(page3Item)
        } else {
            if (hasPage3) {
                var p3 = togglesSwipeView.takeItem(2)
                if (p3) p3.parent = hiddenPagesContainer
            }
        }
    }

    function updateTogglePages() {
        if (typeof page1Flow === "undefined" || !page1Flow || typeof hiddenTogglesContainer === "undefined" || !hiddenTogglesContainer) {
            return
        }
        syncSwipePages()
        var keys = root.activeTileKeys
        // 1. Move all toggles into hidden container to reset ordering
        for (var a = 0; a < allToggleKeys.length; ++a) {
            var item = getToggleByKey(allToggleKeys[a])
            if (item) {
                item.visible = false
                item.parent = hiddenTogglesContainer
            }
        }
        // 2. Re-attach active toggles in exact sequence to target flow pages
        for (var i = 0; i < keys.length; ++i) {
            var t = getToggleByKey(keys[i])
            if (t) {
                t.visible = true
                var pageIdx = Math.floor(i / root.tilesPerPage)
                var targetParent = page1Flow
                if (pageIdx === 1 && typeof page2Flow !== "undefined") targetParent = page2Flow
                else if (pageIdx >= 2 && typeof page3Flow !== "undefined") targetParent = page3Flow
                t.parent = targetParent
            }
        }
        if (typeof togglesSwipeView !== "undefined" && togglesSwipeView && togglesSwipeView.currentIndex >= root.togglePageCount) {
            togglesSwipeView.currentIndex = Math.max(0, root.togglePageCount - 1)
        }
    }

    Layout.preferredWidth: 390
    Layout.preferredHeight: currentContentHeight
    Layout.minimumWidth: 390
    Layout.maximumWidth: 390
    Layout.minimumHeight: currentContentHeight
    Layout.maximumHeight: currentContentHeight

    implicitWidth: 390
    implicitHeight: currentContentHeight
    width: 390
    height: currentContentHeight
    radius: 24

    antialiasing: true
    smooth: true

    // GNOME glassmorphic surface
    color: isDarkTheme ? "#1e1e24" : "#f0f2f5"
    border.color: isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
    border.width: 1

    clip: true



    // Main Quick Settings View
    Item {
        id: mainViewContainer
        anchors.fill: parent
        visible: root.activeView === "main"

        ScrollView {
            id: mainScroll
            anchors.fill: parent
            anchors.margins: 14
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                id: mainCol
                width: mainScroll.availableWidth
                spacing: 14

                // 1. Top Bar: User Profile (Avatar + Name & Role) + Battery + Action Icons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // User Profile Card (Circular Profile Pic + Name & Role, clicks to open User Management)
                    Rectangle {
                        id: userProfileCard
                        implicitHeight: 36
                        implicitWidth: userProfileRow.implicitWidth + 8
                        Layout.maximumWidth: 170
                        radius: 18
                        color: userProfileMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        RowLayout {
                            id: userProfileRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            spacing: 8

                            // Circular Profile Pic
                            Rectangle {
                                id: userProfileAvatar
                                width: 32
                                height: 32
                                radius: 16
                                color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                                border.width: 1.5
                                border.color: userProfileMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.4) : Qt.rgba(0, 0, 0, 0.28)) : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.18) : Qt.rgba(0, 0, 0, 0.12))

                                Behavior on border.color {
                                    ColorAnimation { duration: 150 }
                                }

                                Item {
                                    id: avatarContainer
                                    anchors.fill: parent
                                    anchors.margins: 2

                                    // Fallback user icon circle when no avatar image or loading
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
                                        visible: !avatarEffect.visible

                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            source: "user-identity"
                                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                        }
                                    }

                                    // Hidden source image
                                    Image {
                                        id: avatarImg
                                        anchors.fill: parent
                                        source: (backend && backend.userAvatarPath && backend.userAvatarPath !== "") ? ("file://" + backend.userAvatarPath) : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: false
                                        cache: false
                                    }

                                    // Circular mask
                                    Rectangle {
                                        id: maskCircle
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: "black"
                                        visible: false
                                        layer.enabled: true
                                    }

                                    // Masked circular avatar
                                    MultiEffect {
                                        id: avatarEffect
                                        anchors.fill: parent
                                        source: (avatarImg.status === Image.Ready && avatarImg.source != "") ? avatarImg : null
                                        maskEnabled: (avatarImg.status === Image.Ready && avatarImg.source != "")
                                        maskSource: (avatarImg.status === Image.Ready && avatarImg.source != "") ? maskCircle : null
                                        visible: avatarImg.status === Image.Ready && avatarImg.source != ""
                                    }
                                }
                            }

                            // User Name & Role text
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: (backend && backend.userRealName && backend.userRealName !== "") ? backend.userRealName : (backend ? backend.userName : "User")
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: (backend && backend.userRole && backend.userRole !== "") ? backend.userRole : "Administrator"
                                    font.pixelSize: 10
                                    color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.55) : Qt.rgba(0, 0, 0, 0.55)
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: userProfileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (backend && backend.openUserManagement) {
                                    backend.openUserManagement()
                                }
                            }
                        }

                        ToolTip.visible: userProfileMouse.containsMouse
                        ToolTip.delay: 400
                        ToolTip.text: (backend && backend.userRealName && backend.userRealName !== "") ? (backend.userRealName + " (" + (backend.userRole || "Administrator") + ") — " + i18n("Manage User Account")) : i18n("Manage User Account")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Battery Capsule (Click to toggle battery percentage on panel)
                    Rectangle {
                        implicitWidth: batRow.implicitWidth + 14
                        implicitHeight: 28
                        radius: 14
                        color: batMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.07))

                        RowLayout {
                            id: batRow
                            anchors.centerIn: parent
                            spacing: 4

                            Kirigami.Icon {
                                implicitWidth: 16
                                implicitHeight: 16
                                source: backend ? backend.batteryIconName : "battery-080"
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: (backend ? backend.batteryLevel : 85) + "%"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: (backend && backend.batteryLevel <= 20 && !backend.batteryCharging) ? "#e74c3c" : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
                            }
                        }

                        MouseArea {
                            id: batMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (backend && backend.toggleBatteryPercent) {
                                    backend.toggleBatteryPercent()
                                }
                            }
                        }
                    }

                    // Settings Launcher Button (Opens System Settings)
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: settingsMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: "settings-configure-symbolic"
                            isMask: true
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        }
                        MouseArea {
                            id: settingsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (backend && backend.openSystemSettings) {
                                    backend.openSystemSettings()
                                }
                            }
                        }

                        ToolTip.visible: settingsMouse.containsMouse
                        ToolTip.delay: 400
                        ToolTip.text: i18n("Open System Settings")
                    }

                    // Screenshot Button (triggers Spectacle or Flameshot based on configuration)
                    Rectangle {
                        id: screenshotBtnRect
                        width: 32
                        height: 32
                        radius: 16
                        readonly property bool hasTools: Boolean(backend && (backend.hasSpectacle || backend.hasFlameshot))
                        opacity: hasTools ? 1.0 : 0.4
                        color: (hasTools && screenshotMouse.containsMouse) ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: Qt.resolvedUrl("../assets/screenshot-symbolic.svg")
                            fallback: "camera-photo-symbolic"
                            isMask: true
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        }
                        MouseArea {
                            id: screenshotMouse
                            anchors.fill: parent
                            enabled: screenshotBtnRect.hasTools
                            hoverEnabled: true
                            cursorShape: screenshotBtnRect.hasTools ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (backend && backend.triggerScreenshot) {
                                    backend.triggerScreenshot()
                                }
                            }
                        }

                        ToolTip.visible: screenshotMouse.containsMouse
                        ToolTip.delay: 400
                        ToolTip.text: {
                            if (!screenshotBtnRect.hasTools) return i18n("No screenshot tool found (install Spectacle or Flameshot)")
                            var toolName = (backend && backend.screenshotTool === "flameshot") ? "Flameshot" : ((backend && backend.screenshotTool === "spectacle") ? "Spectacle" : (backend.hasFlameshot && !backend.hasSpectacle ? "Flameshot" : "Spectacle"))
                            return i18n("Take Screenshot (%1)", toolName)
                        }
                    }

                    // Power / Shutdown Button
                    Rectangle {
                        id: powerBtnRect
                        width: 32
                        height: 32
                        radius: 16
                        color: powerMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: "system-shutdown-symbolic"
                            isMask: true
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        }
                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerOverlay.visible = !powerOverlay.visible
                            }
                        }
                    }
                }

                // 2. Sliders Section: Volume & Brightness (Full width, slim vertical height ~24px)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Audio Volume Slider (Full Width)
                    CurvedSlider {
                        Layout.fillWidth: true
                        implicitHeight: 24
                        value: backend ? backend.volume : 65
                        isMuted: backend ? backend.isMuted : false
                        iconName: (backend && backend.volumeIconName) ? backend.volumeIconName : "audio-volume-high"
                        isDarkTheme: root.isDarkTheme
                        accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"
                        accentTextColor: (Kirigami.Theme.highlightedTextColor !== undefined && Kirigami.Theme.highlightedTextColor.a > 0) ? Kirigami.Theme.highlightedTextColor : "#ffffff"
                        onValueChangedByUser: function(newValue) { if (backend) backend.setVolume(newValue) }
                        onIconClicked: if (backend) backend.toggleMute()
                    }

                    // Display Brightness Slider (Full Width)
                    CurvedSlider {
                        Layout.fillWidth: true
                        implicitHeight: 24
                        value: backend ? backend.brightness : 75
                        isMuted: false
                        iconName: "brightness-high-symbolic"
                        isDarkTheme: root.isDarkTheme
                        accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"
                        accentTextColor: (Kirigami.Theme.highlightedTextColor !== undefined && Kirigami.Theme.highlightedTextColor.a > 0) ? Kirigami.Theme.highlightedTextColor : "#ffffff"
                        onValueChangedByUser: function(newValue) { if (backend) backend.setBrightness(newValue) }
                        onIconClicked: if (backend) backend.setBrightness(10)
                    }
                }

                // 3. Paged Curved Pill Toggles (restricted to at most 4 rows = 8 toggles per page)
                Item {
                    id: togglesContainer
                    Layout.fillWidth: true
                    implicitHeight: togglesSwipeView.implicitHeight + (pageDotsRow.visible ? (pageDotsRow.implicitHeight + 10) : 0)

                    SwipeView {
                        id: togglesSwipeView
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        implicitHeight: root.visibleRowsOnPage > 0 ? (root.visibleRowsOnPage * ((backend && backend.tileIconSize) ? Math.max(56, backend.tileIconSize + 36) : 56) + Math.max(0, root.visibleRowsOnPage - 1) * 10) : 0
                        height: implicitHeight
                        clip: true
                        currentIndex: 0
                        interactive: root.togglePageCount > 1

                        Item {
                            id: page1Item
                            width: togglesSwipeView.width
                            height: togglesSwipeView.height
                            Flow {
                                id: page1Flow
                                anchors.fill: parent
                                spacing: 10
                            }
                        }
                    }

                    // Offscreen holding area for pages 2 & 3 before dynamic addition to SwipeView
                    Item {
                        id: hiddenPagesContainer
                        visible: false
                        width: 0
                        height: 0

                        Item {
                            id: page2Item
                            width: togglesSwipeView.width
                            height: togglesSwipeView.height
                            Flow {
                                id: page2Flow
                                anchors.fill: parent
                                spacing: 10
                            }
                        }

                        Item {
                            id: page3Item
                            width: togglesSwipeView.width
                            height: togglesSwipeView.height
                            Flow {
                                id: page3Flow
                                anchors.fill: parent
                                spacing: 10
                            }
                        }
                    }

                    WheelHandler {
                        target: togglesSwipeView
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function(event) {
                            if (event.angleDelta.y < 0 && togglesSwipeView.currentIndex < root.togglePageCount - 1) {
                                togglesSwipeView.currentIndex++
                            } else if (event.angleDelta.y > 0 && togglesSwipeView.currentIndex > 0) {
                                togglesSwipeView.currentIndex--
                            }
                        }
                    }

                    // Dots indicator at the bottom (shows if more than 1 page)
                    RowLayout {
                        id: pageDotsRow
                        anchors.top: togglesSwipeView.bottom
                        anchors.topMargin: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.togglePageCount > 1
                        spacing: 8

                        Repeater {
                            model: root.togglePageCount
                            delegate: Rectangle {
                                id: dotRect
                                readonly property bool isCurrent: togglesSwipeView.currentIndex === index
                                implicitWidth: isCurrent ? 20 : 6
                                implicitHeight: 6
                                radius: 3
                                color: isCurrent
                                       ? ((Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : (root.isDarkTheme ? "#ffffff" : "#1a1a1a"))
                                       : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.35) : Qt.rgba(0, 0, 0, 0.25))

                                Behavior on implicitWidth {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: togglesSwipeView.currentIndex = index
                                }
                            }
                        }
                    }
                }

                // Invisible container for storing instantiated toggles before pagination parenting
                Item {
                    id: hiddenTogglesContainer
                    visible: false
                    width: 0
                    height: 0

                    // 1. Wi-Fi
                    PillToggle {
                        id: toggleWifi
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowWifi : true
                        title: "Wi-Fi"
                        subtitle: (backend && backend.wifiConnected) ? (backend.wifiSsid || "Connected") : ((backend && backend.wifiEnabled) ? "Disconnected" : ((backend && backend.hotspotEnabled) ? "Hotspot Active" : "Off"))
                        iconName: (backend && backend.wifiIconName) ? backend.wifiIconName : "network-wireless-symbolic"
                        checked: backend ? (!backend.hotspotEnabled && (backend.wifiConnected || backend.wifiEnabled)) : false
                        hasMenu: true
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.toggleWifi(newState)
                        onMenuClicked: {
                            if (backend) backend.refreshWifi()
                            root.activeView = "network"
                        }
                    }

                    // 2. Bluetooth
                    PillToggle {
                        id: toggleBt
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowBluetooth : true
                        title: "Bluetooth"
                        subtitle: (backend && backend.btConnected) ? ((backend.btDeviceName || "Connected") + (backend.btBattery > 0 ? " • " + backend.btBattery + "%" : "")) : ((backend && backend.btEnabled) ? "On" : "Off")
                        iconName: (backend && backend.btIconName) ? backend.btIconName : "preferences-system-bluetooth"
                        checked: backend ? backend.btEnabled : false
                        hasMenu: true
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.toggleBluetooth(newState)
                        onMenuClicked: {
                            if (backend) backend.refreshBluetoothDevices()
                            root.activeView = "bluetooth"
                        }
                    }

                    // 3. Location Services
                    PillToggle {
                        id: toggleLocation
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowLocation : true
                        title: "Location"
                        subtitle: {
                            if (!backend || !backend.locationEnabled) return "Off"
                            if (backend.locationApps && backend.locationApps.length > 0) {
                                return backend.locationApps.length === 1 ? (backend.locationApps[0].name || "In Use") : (backend.locationApps.length + " Active")
                            }
                            return "Enabled"
                        }
                        iconName: "find-location-symbolic"
                        checked: backend ? backend.locationEnabled : false
                        hasMenu: true
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.toggleLocation()
                        onMenuClicked: {
                            if (backend) backend.refreshLocation()
                            root.activeView = "location"
                        }
                    }

                    // 4. Microphone Mute / Privacy
                    PillToggle {
                        id: toggleMic
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowMic : true
                        title: "Microphone"
                        subtitle: {
                            if (backend && backend.micMuted) return "Muted"
                            if (backend && backend.micApps && backend.micApps.length > 0) {
                                return backend.micApps.length === 1 ? (backend.micApps[0].name || "In Use") : (backend.micApps.length + " Active")
                            }
                            return "Active"
                        }
                        iconName: (backend && backend.micMuted) ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic"
                        checked: backend ? !backend.micMuted : true
                        hasMenu: true
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.toggleMic()
                        onMenuClicked: {
                            if (backend) backend.refreshMic()
                            root.activeView = "microphone"
                        }
                    }

                    // 5. Camera Privacy
                    PillToggle {
                        id: toggleCamera
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowCamera : true
                        title: "Camera"
                        subtitle: {
                            if (backend && backend.cameraBlocked) return "Blocked"
                            if (backend && backend.cameraApps && backend.cameraApps.length > 0) {
                                return backend.cameraApps.length === 1 ? (backend.cameraApps[0].name || "In Use") : (backend.cameraApps.length + " Active")
                            }
                            return "Available"
                        }
                        iconName: (backend && backend.cameraBlocked) ? "camera-off-symbolic" : "camera-web-symbolic"
                        checked: backend ? !backend.cameraBlocked : true
                        hasMenu: true
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.toggleCamera()
                        onMenuClicked: {
                            if (backend) backend.refreshCamera()
                            root.activeView = "camera"
                        }
                    }

                    // 6. KDE Connect
                    PillToggle {
                        id: toggleKde
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowKdeConnect : true
                        title: "KDE Connect"
                        subtitle: (backend && backend.kdeConnectConnected) ? (backend.kdeConnectName || "Connected") : ((backend && backend.kdeConnectDevices && backend.kdeConnectDevices.length > 0) ? (backend.kdeConnectDevices.length + " Device(s)") : "Disconnected")
                        iconName: "kdeconnect-tray-symbolic"
                        checked: backend ? backend.kdeConnectConnected : false
                        hasMenu: true
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.openKdeConnect()
                        onMenuClicked: {
                            if (backend) backend.refreshKdeConnect()
                            root.activeView = "kdeconnect"
                        }
                    }

                    // 7. Dark Style / Light Theme
                    PillToggle {
                        id: toggleDark
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowDarkTheme : true
                        title: "Dark Style"
                        subtitle: root.isDarkTheme ? "Dark Mode" : "Light Mode"
                        iconName: "contrast-symbolic"
                        checked: root.isDarkTheme
                        hasMenu: false
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.toggleDarkMode(newState)
                    }

                    // 8. Night Light (Color Temp)
                    PillToggle {
                        id: toggleNight
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowNightLight : true
                        title: "Night Light"
                        subtitle: (backend && backend.nightLightEnabled) ? "3400 K" : "Off"
                        iconName: "redshift-status-on-symbolic"
                        checked: backend ? backend.nightLightEnabled : false
                        hasMenu: false
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.toggleNightLight(newState)
                    }

                    // 9. Airplane Mode
                    PillToggle {
                        id: toggleAir
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowAirplane : true
                        title: "Airplane Mode"
                        subtitle: (backend && backend.airplaneMode) ? "Enabled" : "Off"
                        iconName: "network-flightmode-on-symbolic"
                        checked: backend ? backend.airplaneMode : false
                        hasMenu: false
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.toggleAirplaneMode(newState)
                    }

                    // 10. Do Not Disturb (DND)
                    PillToggle {
                        id: toggleDnd
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowDnd : true
                        title: "Do Not Disturb"
                        subtitle: {
                            if (!backend || !backend.dndEnabled) return "Off"
                            return backend.dndUntilText || "On"
                        }
                        iconName: (backend && backend.dndEnabled) ? "notifications-disabled-symbolic" : "notifications-symbolic"
                        checked: backend ? backend.dndEnabled : false
                        hasMenu: true
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.toggleDnd(newState)
                        onMenuClicked: {
                            root.activeView = "dnd"
                        }
                    }

                    // 11. Hotspot
                    PillToggle {
                        id: toggleHotspot
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowHotspot : true
                        title: "Hotspot"
                        subtitle: (backend && backend.hotspotEnabled) ? (backend.hotspotSsid || "Active") : "Off"
                        iconName: "network-wireless-hotspot-symbolic"
                        checked: backend ? (backend.hotspotEnabled && !backend.wifiConnected && !backend.wifiEnabled) : false
                        hasMenu: true
                        isDarkTheme: root.isDarkTheme
                        onToggled: if (backend) backend.toggleHotspot(!backend.hotspotEnabled)
                        onMenuClicked: {
                            if (backend) backend.refreshHotspot()
                            root.activeView = "hotspot"
                        }
                    }

                    // 12. Power Mode (Performance, Balanced, Optimise)
                    PillToggle {
                        id: togglePower
                        width: root.tileWidth()
                        visible: backend ? backend.tileShowPowerSaver : true
                        title: "Power"
                        subtitle: {
                            var p = backend ? backend.powerProfile : "balanced"
                            if (p === "performance") return "Performance"
                            if (p === "power-saver") return "Optimise"
                            return "Balanced"
                        }
                        iconName: (backend && backend.powerProfileIconName) ? backend.powerProfileIconName : "battery-profile-balanced-symbolic"
                        checked: backend ? (backend.powerProfile !== "balanced") : false
                        hasMenu: true
                        isDarkTheme: root.isDarkTheme
                        onToggled: {
                            if (backend) {
                                if (backend.powerProfile === "balanced") {
                                    backend.setPowerProfile("power-saver")
                                } else {
                                    backend.setPowerProfile("balanced")
                                }
                            }
                        }
                        onMenuClicked: {
                            root.activeView = "power"
                        }
                    }
                }

                // 4. MPRIS Media Player Card (Visible only when media is playing)
                MediaCard {
                    Layout.fillWidth: true
                    visible: backend ? (backend.mediaTitle !== "") : false
                    trackTitle: backend ? backend.mediaTitle : ""
                    artist: backend ? backend.mediaArtist : ""
                    albumArt: backend ? backend.mediaAlbumArt : ""
                    isPlaying: backend ? backend.mediaPlaying : false
                    progress: backend ? backend.mediaProgress : 0.0
                    isDarkTheme: root.isDarkTheme
                    onPlayPauseClicked: if (backend) backend.toggleMediaPlay()
                    onPreviousClicked: if (backend) backend.mediaPrevious()
                    onNextClicked: if (backend) backend.mediaNext()
                    onSeek: function(ratio) { if (backend) backend.seekMedia(ratio) }
                }
            }
        }
    }

    // Power Actions Overlay (Suspend / Restart / Shutdown / Log Out)
    // Floats over the widget as a rounded panel anchored to top-right corner
    Rectangle {
        id: powerOverlay
        visible: false
        z: 99
        width: 180
        height: powerOverlayCol.implicitHeight + 16
        radius: 14
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 52      // below the top bar
        anchors.rightMargin: 14

        color: root.isDarkTheme ? "#2a2a32" : "#ffffff"
        border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.12)
        border.width: 1

        layer.enabled: true

        // Consume clicks so they don't fall through to the dismiss area
        MouseArea {
            anchors.fill: parent
            onClicked: { /* consume */ }
        }

        ColumnLayout {
            id: powerOverlayCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            spacing: 2

            component PowerMenuItem: Rectangle {
                id: pmItem
                property string iconSrc: ""
                property string label: ""
                signal actionTriggered()

                Layout.fillWidth: true
                height: 38
                radius: 8
                color: pmMouse.containsMouse
                       ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.07))
                       : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Kirigami.Icon {
                        implicitWidth: 16
                        implicitHeight: 16
                        source: pmItem.iconSrc
                        isMask: true
                        color: root.isDarkTheme ? "#e0e0e0" : "#1a1a1a"
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: pmItem.label
                        font.pixelSize: 13
                        color: root.isDarkTheme ? "#e0e0e0" : "#1a1a1a"
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: pmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        powerOverlay.visible = false
                        pmItem.actionTriggered()
                    }
                }
            }

            Item { height: 4; Layout.fillWidth: true }

            PowerMenuItem {
                iconSrc: "system-lock-screen-symbolic"
                label: "Lock"
                onActionTriggered: if (backend) backend.lockScreen()
            }

            PowerMenuItem {
                iconSrc: "system-suspend-symbolic"
                label: "Suspend"
                onActionTriggered: if (backend) backend.suspendSystem()
            }

            PowerMenuItem {
                iconSrc: "system-reboot-symbolic"
                label: "Restart…"
                onActionTriggered: if (backend) backend.rebootSystem()
            }

            PowerMenuItem {
                iconSrc: "system-shutdown-symbolic"
                label: "Power Off…"
                onActionTriggered: if (backend) backend.shutdownSystem()
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
                Layout.leftMargin: 8
                Layout.rightMargin: 8
            }

            PowerMenuItem {
                iconSrc: "system-log-out-symbolic"
                label: "Log Out…"
                onActionTriggered: if (backend) backend.logoutSession()
            }

            Item { height: 4; Layout.fillWidth: true }
        }
    }

    // Transparent dismiss area — clicking anywhere outside the overlay hides it
    MouseArea {
        id: overlayDismiss
        anchors.fill: parent
        z: 98
        visible: powerOverlay.visible
        onClicked: { powerOverlay.visible = false }
    }

    // Wi-Fi Sub-View Container
    NetworkView {
        anchors.fill: parent
        visible: root.activeView === "network"
        isDarkTheme: root.isDarkTheme
        wifiEnabled: backend ? backend.wifiEnabled : true
        hotspotEnabled: backend ? backend.hotspotEnabled : false
        activeSsid: backend ? backend.wifiSsid : ""
        networksModel: (backend && backend.wifiNetworks) ? backend.wifiNetworks : []
        onBackClicked: root.activeView = "main"
        onToggleWifi: if (backend) backend.toggleWifi(enabled)
        onConnectToSsid: if (backend) backend.connectWifi(ssid)
        onRefreshClicked: if (backend) backend.refreshWifi()
    }

    // Bluetooth Sub-View Container
    BluetoothView {
        anchors.fill: parent
        visible: root.activeView === "bluetooth"
        isDarkTheme: root.isDarkTheme
        btEnabled: backend ? backend.btEnabled : true
        isScanning: backend ? backend.btScanning : false
        devicesModel: (backend && backend.btDevices) ? backend.btDevices : []
        onBackClicked: root.activeView = "main"
        onToggleBt: if (backend) backend.toggleBluetooth(enabled)
        onToggleConnectDevice: if (backend) backend.toggleBtDevice(mac, currentlyConnected)
        onPairClicked: function(mac) { if (backend) backend.pairBtDevice(mac) }
        onOpenSettingsClicked: if (backend) backend.openBluetoothSettings()
        onScanClicked: if (backend) backend.refreshBluetoothDevices()
    }

    // KDE Connect Sub-View Container
    KdeConnectView {
        anchors.fill: parent
        visible: root.activeView === "kdeconnect"
        isDarkTheme: root.isDarkTheme
        devicesModel: (backend && backend.kdeConnectDevices) ? backend.kdeConnectDevices : []
        onBackClicked: root.activeView = "main"
        onRefreshClicked: if (backend) backend.refreshKdeConnect()
        onRingClicked: function(devId) { if (backend) backend.ringKdeConnect(devId) }
        onPingClicked: function(devId) { if (backend) backend.pingKdeConnect(devId) }
        onShareClicked: function(devId) { if (backend) backend.shareKdeConnect(devId) }
        onSmsClicked: function() { if (backend) backend.smsKdeConnect() }
        onBrowseClicked: function(devId) { if (backend) backend.browseKdeConnect(devId) }
        onPairClicked: function(devId) { if (backend) backend.pairKdeConnect(devId) }
        onUnpairClicked: function(devId) { if (backend) backend.unpairKdeConnect(devId) }
        onOpenSettingsClicked: if (backend) backend.openKdeConnect()
    }

    // Power Profile Sub-View Container
    PowerView {
        anchors.fill: parent
        visible: root.activeView === "power"
        isDarkTheme: root.isDarkTheme
        currentProfile: backend ? backend.powerProfile : "balanced"
        onBackClicked: root.activeView = "main"
        onSelectProfile: function(profile) {
            if (backend) backend.setPowerProfile(profile)
        }
    }

    // Do Not Disturb Sub-View Container
    DndView {
        anchors.fill: parent
        visible: root.activeView === "dnd"
        isDarkTheme: root.isDarkTheme
        dndEnabled: backend ? backend.dndEnabled : false
        dndMode: backend ? backend.dndMode : "until_off"
        dndUntilText: backend ? backend.dndUntilText : ""
        onBackClicked: root.activeView = "main"
        onToggleDnd: function(active) {
            if (backend) backend.toggleDnd(active)
        }
        onSelectOption: function(mode) {
            if (backend) backend.setDndMode(mode)
        }
    }

    // Camera Sub-View Container
    CameraView {
        anchors.fill: parent
        visible: root.activeView === "camera"
        isDarkTheme: root.isDarkTheme
        cameraBlocked: backend ? backend.cameraBlocked : false
        cameraApps: (backend && backend.cameraApps) ? backend.cameraApps : []
        onBackClicked: root.activeView = "main"
        onToggleCamera: if (backend) backend.toggleCamera()
        onRefreshClicked: if (backend) backend.refreshCamera()
        onStopApp: function(pid) {
            if (backend) backend.stopCameraApp(pid)
        }
    }

    // Microphone Sub-View Container
    MicrophoneView {
        anchors.fill: parent
        visible: root.activeView === "microphone"
        isDarkTheme: root.isDarkTheme
        micMuted: backend ? backend.micMuted : false
        micApps: (backend && backend.micApps) ? backend.micApps : []
        onBackClicked: root.activeView = "main"
        onToggleMic: if (backend) backend.toggleMic()
        onRefreshClicked: if (backend) backend.refreshMic()
        onStopApp: function(pid) {
            if (backend) backend.stopMicApp(pid)
        }
    }

    // Location Sub-View Container
    LocationView {
        anchors.fill: parent
        visible: root.activeView === "location"
        isDarkTheme: root.isDarkTheme
        locationEnabled: backend ? backend.locationEnabled : false
        locationApps: (backend && backend.locationApps) ? backend.locationApps : []
        onBackClicked: root.activeView = "main"
        onToggleLocation: if (backend) backend.toggleLocation()
        onRefreshClicked: if (backend) backend.refreshLocation()
        onStopApp: function(pid) {
            if (backend) backend.stopLocationApp(pid)
        }
    }

    // Hotspot Sub-View Container
    HotspotView {
        anchors.fill: parent
        visible: root.activeView === "hotspot"
        isDarkTheme: root.isDarkTheme
        hotspotEnabled: backend ? backend.hotspotEnabled : false
        hotspotSsid: (backend && backend.hotspotSsid) ? backend.hotspotSsid : "Hotspot"
        hotspotPassword: (backend && backend.hotspotPassword) ? backend.hotspotPassword : ""
        onBackClicked: root.activeView = "main"
        onToggleHotspot: if (backend) backend.toggleHotspot(!backend.hotspotEnabled)
        onRefreshClicked: if (backend) backend.refreshHotspot()
        onOpenSettingsClicked: if (backend) backend.openHotspotSettings()
    }

    // Widget Settings Sub-View Container
    WidgetSettingsView {
        anchors.fill: parent
        visible: root.activeView === "settings"
        backend: root.backend
        isDarkTheme: root.isDarkTheme
        onBackClicked: root.activeView = "main"
        onOpenWindowClicked: if (backend && backend.openWidgetSettings) backend.openWidgetSettings()
    }
}
