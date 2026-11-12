import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * WidgetSettingsView.qml - In-place Widget Settings & Customization Sub-View (Plasma 6)
 * Allows customizing panel status capsule icons, sizing, and quick setting tile visibility.
 */
Rectangle {
    id: root

    property var backend: null
    property bool isDarkTheme: true

    signal backClicked()
    signal openWindowClicked()

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Back button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: backMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "go-previous-symbolic"
                    isMask: true
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
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
                text: "Widget Settings"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
            }

            // Open Native Configuration Window Button
            Rectangle {
                implicitWidth: winRow.implicitWidth + 14
                implicitHeight: 28
                radius: 14
                color: winMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))
                border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(0, 0, 0, 0.08)
                border.width: 1

                RowLayout {
                    id: winRow
                    anchors.centerIn: parent
                    spacing: 4

                    Kirigami.Icon {
                        width: 13
                        height: 13
                        source: "settings-configure-symbolic"
                        isMask: true
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    }

                    Text {
                        text: "Window"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    }
                }

                MouseArea {
                    id: winMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (backend && backend.openWidgetSettings) {
                            backend.openWidgetSettings()
                        } else {
                            root.openWindowClicked()
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

        // Scrollable settings list
        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: scroll.availableWidth
                spacing: 14

                // Section 1: Panel Status Capsule
                Text {
                    text: "Panel Status Capsule"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: root.accentColor
                }

                // Panel Icon Size Stepper
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 12
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "Panel Icon Size"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: minusPanelMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.15)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08))

                            Text {
                                anchors.centerIn: parent
                                text: "-"
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            }
                            MouseArea {
                                id: minusPanelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var cur = backend ? backend.panelIconSize : 15
                                    if (cur > 10) {
                                        if (backend) backend.setWidgetConfig("panelIconSize", cur - 1)
                                    }
                                }
                            }
                        }

                        Text {
                            text: (backend ? backend.panelIconSize : 15) + " px"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            horizontalAlignment: Text.AlignHCenter
                            Layout.preferredWidth: 42
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: plusPanelMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.15)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08))

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            }
                            MouseArea {
                                id: plusPanelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var cur = backend ? backend.panelIconSize : 15
                                    if (cur < 28) {
                                        if (backend) backend.setWidgetConfig("panelIconSize", cur + 1)
                                    }
                                }
                            }
                        }
                    }
                }

                // Panel Toggles List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Show Battery %
                    Component {
                        id: settingToggleRow
                        Rectangle {
                            id: rowCard
                            property string title: ""
                            property string subtitle: ""
                            property bool checkedState: false
                            property string configKey: ""

                            Layout.fillWidth: true
                            height: 44
                            radius: 12
                            color: rowMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03))

                            // Switch rigidly locked to right margin: 12
                            Switch {
                                id: settingSwitch
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                checked: rowCard.checkedState
                                onToggled: {
                                    if (backend) backend.setWidgetConfig(rowCard.configKey, checked)
                                }
                            }

                            // Text Column bound between left margin: 12 and settingSwitch
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: settingSwitch.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: rowCard.title
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    visible: rowCard.subtitle !== ""
                                    text: rowCard.subtitle
                                    font.pixelSize: 10
                                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                anchors.rightMargin: 56
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (backend) backend.setWidgetConfig(rowCard.configKey, !rowCard.checkedState)
                                }
                            }
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Show Battery Percentage on Panel"
                            item.subtitle = "Displays number (e.g. 85%) next to battery icon"
                            item.configKey = "showBatteryPercent"
                            item.checkedState = Qt.binding(function() { return backend ? backend.showBatteryPercent : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Show Volume Percentage on Panel"
                            item.subtitle = "Displays number (e.g. 65%) next to volume icon"
                            item.configKey = "showVolumePercent"
                            item.checkedState = Qt.binding(function() { return Boolean(backend && backend.showVolumePercent) })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Wi-Fi Indicator"
                            item.subtitle = "Show Wi-Fi status on panel capsule"
                            item.configKey = "showWifi"
                            item.checkedState = Qt.binding(function() { return backend ? Boolean(backend.showWifi) : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Volume Indicator"
                            item.subtitle = "Show sound volume icon on panel capsule"
                            item.configKey = "showVolume"
                            item.checkedState = Qt.binding(function() { return backend ? Boolean(backend.showVolume) : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Bluetooth Indicator"
                            item.subtitle = "Show Bluetooth status on panel capsule"
                            item.configKey = "showBluetooth"
                            item.checkedState = Qt.binding(function() { return backend ? Boolean(backend.showBluetooth) : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Battery Indicator"
                            item.subtitle = "Show battery icon on panel capsule"
                            item.configKey = "showBattery"
                            item.checkedState = Qt.binding(function() { return backend ? Boolean(backend.showBattery) : true })
                        }
                    }
                }

                // Section 2: Screenshot Tool Configuration
                Text {
                    text: "Screenshot Tool"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: root.accentColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: screenshotBoxCol.implicitHeight + 24
                    radius: 12
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)

                    ColumnLayout {
                        id: screenshotBoxCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        readonly property bool anyAvailable: Boolean(backend && (backend.hasScreenshotTool || backend.hasSpectacle || backend.hasFlameshot || backend.hasGnomeScreenshot || backend.hasKsnip || backend.hasXfceScreenshooter || backend.hasScrot || backend.hasGrim))

                        function getScreenshotTools() {
                            if (backend && backend.installedScreenshotTools && backend.installedScreenshotTools.length > 0) {
                                return backend.installedScreenshotTools
                            }
                            var list = [{ text: "Auto Detect", value: "auto" }]
                            if (backend && backend.hasSpectacle) list.push({ text: "Spectacle", value: "spectacle" })
                            if (backend && backend.hasFlameshot) list.push({ text: "Flameshot", value: "flameshot" })
                            if (backend && backend.hasGnomeScreenshot) list.push({ text: "GNOME Screenshot", value: "gnome-screenshot" })
                            if (backend && backend.hasKsnip) list.push({ text: "Ksnip", value: "ksnip" })
                            if (backend && backend.hasXfceScreenshooter) list.push({ text: "XFCE", value: "xfce4-screenshooter" })
                            if (backend && backend.hasScrot) list.push({ text: "Scrot", value: "scrot" })
                            if (backend && backend.hasGrim) list.push({ text: "Grim / Slurp", value: "grim" })
                            return list
                        }

                        Text {
                            text: "Select Screenshot Application:"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: screenshotBoxCol.anyAvailable ? (root.isDarkTheme ? "#ffffff" : "#1a1a1a") : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.35) : Qt.rgba(0, 0, 0, 0.35))
                        }

                        Text {
                            visible: !screenshotBoxCol.anyAvailable
                            text: "No screenshot utility detected. Install Spectacle, Flameshot, GNOME Screenshot, or Ksnip to capture screenshots."
                            font.pixelSize: 11
                            color: "#e74c3c"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 12
                            enabled: screenshotBoxCol.anyAvailable || (!backend || backend.screenshotTool === "auto")

                            Repeater {
                                model: screenshotBoxCol.getScreenshotTools()

                                RadioButton {
                                    text: modelData.text
                                    checked: Boolean(backend && (backend.screenshotTool === modelData.value || (modelData.value === "auto" && (!backend.screenshotTool || backend.screenshotTool === "auto"))))
                                    onToggled: if (checked && backend) backend.setWidgetConfig("screenshotTool", modelData.value)
                                }
                            }
                        }
                    }
                }

                // Section 2: Quick Settings Tiles Visibility
                Text {
                    text: "Quick Settings Tiles Visibility"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: root.accentColor
                }

                // Tile Icon Size Stepper
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 12
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "Tile Icon Size"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: minusTileMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.15)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08))

                            Text {
                                anchors.centerIn: parent
                                text: "-"
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            }
                            MouseArea {
                                id: minusTileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var cur = backend ? backend.tileIconSize : 20
                                    if (cur > 14) {
                                        if (backend) backend.setWidgetConfig("tileIconSize", cur - 1)
                                    }
                                }
                            }
                        }

                        Text {
                            text: (backend ? backend.tileIconSize : 20) + " px"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            horizontalAlignment: Text.AlignHCenter
                            Layout.preferredWidth: 42
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: plusTileMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.15)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08))

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            }
                            MouseArea {
                                id: plusTileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var cur = backend ? backend.tileIconSize : 20
                                    if (cur < 32) {
                                        if (backend) backend.setWidgetConfig("tileIconSize", cur + 1)
                                    }
                                }
                            }
                        }
                    }
                }

                // Tiles List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Wi-Fi Tile"
                            item.configKey = "tileShowWifi"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowWifi : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Bluetooth Tile"
                            item.configKey = "tileShowBluetooth"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowBluetooth : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Power Mode Tile"
                            item.configKey = "tileShowPowerSaver"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowPowerSaver : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Night Light Tile"
                            item.configKey = "tileShowNightLight"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowNightLight : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Dark Theme Tile"
                            item.configKey = "tileShowDarkTheme"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowDarkTheme : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Airplane Mode Tile"
                            item.configKey = "tileShowAirplane"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowAirplane : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Do Not Disturb Tile"
                            item.configKey = "tileShowDnd"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowDnd : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Mobile Hotspot Tile"
                            item.configKey = "tileShowHotspot"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowHotspot : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Location Services Tile"
                            item.configKey = "tileShowLocation"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowLocation : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Camera Privacy Tile"
                            item.configKey = "tileShowCamera"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowCamera : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Microphone Mute Tile"
                            item.configKey = "tileShowMic"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowMic : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "KDE Connect Tile"
                            item.configKey = "tileShowKdeConnect"
                            item.checkedState = Qt.binding(function() { return backend ? backend.tileShowKdeConnect : true })
                        }
                    }

                }

                // Section 4: Background & Blur
                Text {
                    text: "Background & Blur"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: root.accentColor
                }

                // Background Mode Selection
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 12
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "Background Mode"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            Layout.fillWidth: true
                        }

                        // Mode Selector Buttons
                        Row {
                            spacing: 4

                            component ModeBtn: Rectangle {
                                id: mb
                                property string modeKey: ""
                                property string label: ""
                                readonly property bool selected: backend ? (backend.panelBackgroundMode === modeKey) : (modeKey === "follow_panel")
                                width: Math.max(54, labelTxt.implicitWidth + 14)
                                height: 26
                                radius: 13
                                color: selected ? root.accentColor : (mbMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)))

                                Text {
                                    id: labelTxt
                                    anchors.centerIn: parent
                                    text: mb.label
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: mb.selected ? "#ffffff" : (root.isDarkTheme ? "#ffffff" : "#1a1a1a")
                                }

                                MouseArea {
                                    id: mbMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (backend) backend.setWidgetConfig("panelBackgroundMode", mb.modeKey)
                                }
                            }

                            ModeBtn {
                                modeKey: "follow_panel"
                                label: "Follow Panel"
                            }
                            ModeBtn {
                                modeKey: "translucent"
                                label: "Translucent"
                            }
                            ModeBtn {
                                modeKey: "opaque"
                                label: "Opaque"
                            }
                        }
                    }
                }

                // Custom Opacity Stepper (active in translucent mode)
                Rectangle {
                    visible: backend ? (backend.panelBackgroundMode === "translucent") : false
                    Layout.fillWidth: true
                    height: 48
                    radius: 12
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "Custom Opacity"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: minusOpMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.15)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08))

                            Text {
                                anchors.centerIn: parent
                                text: "-"
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            }
                            MouseArea {
                                id: minusOpMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var cur = backend ? backend.customOpacity : 0.75
                                    var next = Math.max(0.20, Math.round((cur - 0.05) * 100) / 100)
                                    if (backend) backend.setWidgetConfig("customOpacity", next)
                                }
                            }
                        }

                        Text {
                            text: Math.round((backend ? backend.customOpacity : 0.75) * 100) + "%"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: plusOpMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.15)) : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08))

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                            }
                            MouseArea {
                                id: plusOpMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var cur = backend ? backend.customOpacity : 0.75
                                    var next = Math.min(1.00, Math.round((cur + 0.05) * 100) / 100)
                                    if (backend) backend.setWidgetConfig("customOpacity", next)
                                }
                            }
                        }
                    }
                }

                // Blur Behind Toggle
                Loader {
                    Layout.fillWidth: true
                    sourceComponent: settingToggleRow
                    onLoaded: {
                        item.title = "KWin Blur Behind Window"
                        item.subtitle = "Frosted glass blur restricted to card region"
                        item.configKey = "panelBlurEnabled"
                        item.checkedState = Qt.binding(function() { return backend ? backend.panelBlurEnabled : true })
                    }
                }

                // Section 4: Support Development
                Text {
                    text: "Support Development"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: root.accentColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: supportCol.implicitHeight + 24
                    radius: 12
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.06)
                    border.width: 1

                    ColumnLayout {
                        id: supportCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            spacing: 8
                            Layout.fillWidth: true

                            Kirigami.Icon {
                                source: "help-donate"
                                implicitWidth: 20
                                implicitHeight: 20
                                isMask: true
                                color: root.accentColor
                            }

                            Text {
                                text: "Support Me on PayPal"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: "If you enjoy using GNOME Quick Settings, please consider supporting ongoing development and new features!"
                            font.pixelSize: 11
                            color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            implicitWidth: donateBtnRow.implicitWidth + 24
                            implicitHeight: 32
                            radius: 16
                            color: donateMouse.containsMouse ? Qt.darker(root.accentColor, 1.1) : root.accentColor

                            RowLayout {
                                id: donateBtnRow
                                anchors.centerIn: parent
                                spacing: 6

                                Kirigami.Icon {
                                    source: "help-donate"
                                    implicitWidth: 14
                                    implicitHeight: 14
                                    isMask: true
                                    color: "#ffffff"
                                }

                                Text {
                                    text: "Donate via PayPal"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: "#ffffff"
                                }
                            }

                            MouseArea {
                                id: donateMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.openUrlExternally("https://paypal.me/VimleshRaturi")
                            }
                        }
                    }
                }
            }
        }
    }
}

