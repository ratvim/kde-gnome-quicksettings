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
                            item.checkedState = Qt.binding(function() { return backend ? backend.showVolumePercent : false })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Wi-Fi Indicator"
                            item.subtitle = "Show Wi-Fi status on panel capsule"
                            item.configKey = "showWifi"
                            item.checkedState = Qt.binding(function() { return backend ? backend.showWifi : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Volume Indicator"
                            item.subtitle = "Show sound volume icon on panel capsule"
                            item.configKey = "showVolume"
                            item.checkedState = Qt.binding(function() { return backend ? backend.showVolume : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Bluetooth Indicator"
                            item.subtitle = "Show Bluetooth status on panel capsule"
                            item.configKey = "showBluetooth"
                            item.checkedState = Qt.binding(function() { return backend ? backend.showBluetooth : true })
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: settingToggleRow
                        onLoaded: {
                            item.title = "Battery Indicator"
                            item.subtitle = "Show battery icon on panel capsule"
                            item.configKey = "showBattery"
                            item.checkedState = Qt.binding(function() { return backend ? backend.showBattery : true })
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
            }
        }
    }
}

