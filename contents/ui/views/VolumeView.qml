import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import "../components"

/**
 * VolumeView.qml - GNOME-style Sound & Audio Mixer Sub-View (Plasma 6)
 * Displays master output volume, individual application playback streams,
 * output device selection, and microphone input controls.
 * Appears as a dedicated full sub-view when the volume details button is clicked,
 * matching NetworkView and BluetoothView without displaying other toggles.
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

    // Live auto-refresh while the volume view is visible
    Timer {
        id: autoRefreshTimer
        interval: 2500
        repeat: true
        running: root.visible && (backend !== null)
        onTriggered: {
            if (backend && typeof backend.fetchAudioMixer === "function") {
                backend.fetchAudioMixer()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(14 * root.resolutionScale)
        spacing: Math.round(10 * root.resolutionScale)

        // 1. Header Bar: Back Button, Title, Refresh, and System Settings Shortcut
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
                text: "Sound & Volume"
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
                        if (backend && typeof backend.fetchAudioMixer === "function") {
                            backend.fetchAudioMixer()
                        }
                    }
                }
            }

            // System Settings Shortcut Button
            Rectangle {
                implicitWidth: Math.round(28 * root.resolutionScale)
                implicitHeight: implicitWidth
                radius: implicitWidth / 2
                color: extSettingsMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "preferences-desktop-sound"
                    fallback: "configure"
                    implicitWidth: Math.round(14 * root.resolutionScale)
                    implicitHeight: implicitWidth
                    isMask: true
                    color: root.subTextColor
                }

                MouseArea {
                    id: extSettingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (backend && typeof backend.openSoundSettings === "function") {
                            backend.openSoundSettings()
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
                // SECTION 1: MASTER OUTPUT VOLUME
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
                                text: "MASTER OUTPUT"
                                font.pixelSize: Math.round(10 * root.resolutionScale)
                                font.weight: Font.Bold
                                font.capitalization: Font.AllUppercase
                                color: root.headerColor
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: (backend && backend.isMuted) ? "Muted" : ((backend ? backend.volume : 65) + "%")
                                font.pixelSize: Math.round(11 * root.resolutionScale)
                                font.weight: Font.DemiBold
                                color: (backend && backend.isMuted) ? (root.isDarkTheme ? "#f66" : "#c00") : root.subTextColor
                            }
                        }

                        CurvedSlider {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(24, Math.round(26 * root.resolutionScale))
                            value: backend ? backend.volume : 65
                            isMuted: backend ? backend.isMuted : false
                            iconName: (backend && backend.volumeIconName) ? backend.volumeIconName : "audio-volume-high"
                            isDarkTheme: root.isDarkTheme
                            accentColor: root.accentColor
                            accentTextColor: root.accentTextColor
                            onValueChangedByUser: function(newValue) { if (backend) backend.setVolume(newValue) }
                            onIconClicked: if (backend) backend.toggleMute()
                        }
                    }
                }

                // =========================================================================
                // SECTION 2: APPLICATIONS (PER-APP PLAYBACK STREAMS)
                // =========================================================================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(6 * root.resolutionScale)

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.round(6 * root.resolutionScale)

                        Text {
                            text: "APPLICATIONS"
                            font.pixelSize: Math.round(10 * root.resolutionScale)
                            font.weight: Font.Bold
                            font.capitalization: Font.AllUppercase
                            color: root.headerColor
                        }

                        Rectangle {
                            visible: backend && backend.audioSinkInputs && backend.audioSinkInputs.length > 0
                            implicitWidth: appBadgeText.implicitWidth + 8
                            implicitHeight: Math.round(14 * root.resolutionScale)
                            radius: implicitHeight / 2
                            color: root.accentColor

                            Text {
                                id: appBadgeText
                                anchors.centerIn: parent
                                text: backend && backend.audioSinkInputs ? backend.audioSinkInputs.length : "0"
                                font.pixelSize: Math.round(9 * root.resolutionScale)
                                font.weight: Font.Bold
                                color: root.accentTextColor
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Empty State
                    Rectangle {
                        visible: !backend || !backend.audioSinkInputs || backend.audioSinkInputs.length === 0
                        Layout.fillWidth: true
                        implicitHeight: Math.round(36 * root.resolutionScale)
                        radius: Math.round(8 * root.resolutionScale)
                        color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.02)

                        Text {
                            anchors.centerIn: parent
                            text: "No applications currently playing audio"
                            font.pixelSize: Math.round(11 * root.resolutionScale)
                            color: root.subTextColor
                            font.italic: true
                        }
                    }

                    // Application Stream Sliders
                    Repeater {
                        model: (backend && backend.audioSinkInputs) ? backend.audioSinkInputs : []

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: appItemCol.implicitHeight + Math.round(12 * root.resolutionScale)
                            radius: Math.round(8 * root.resolutionScale)
                            color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.025)
                            border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(0, 0, 0, 0.05)
                            border.width: 1

                            ColumnLayout {
                                id: appItemCol
                                anchors.fill: parent
                                anchors.margins: Math.round(6 * root.resolutionScale)
                                spacing: Math.round(4 * root.resolutionScale)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.round(6 * root.resolutionScale)

                                    Kirigami.Icon {
                                        source: (modelData.icon && modelData.icon !== "") ? modelData.icon : "audio-speakers-symbolic"
                                        implicitWidth: Math.round(16 * root.resolutionScale)
                                        implicitHeight: implicitWidth
                                        fallback: "application-x-executable"
                                    }

                                    Text {
                                        text: modelData.name || "Application"
                                        font.pixelSize: Math.round(11 * root.resolutionScale)
                                        font.weight: Font.Medium
                                        color: root.textColor
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.muted ? "Muted" : (modelData.volume + "%")
                                        font.pixelSize: Math.round(10 * root.resolutionScale)
                                        font.weight: Font.DemiBold
                                        color: modelData.muted ? (root.isDarkTheme ? "#f66" : "#c00") : root.subTextColor
                                    }
                                }

                                CurvedSlider {
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(20, Math.round(22 * root.resolutionScale))
                                    value: modelData.volume
                                    isMuted: modelData.muted
                                    iconName: modelData.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
                                    isDarkTheme: root.isDarkTheme
                                    accentColor: root.accentColor
                                    accentTextColor: root.accentTextColor
                                    onValueChangedByUser: function(v) {
                                        if (backend) backend.setSinkInputVolume(modelData.index, v)
                                    }
                                    onIconClicked: {
                                        if (backend) backend.toggleSinkInputMute(modelData.index)
                                    }
                                }
                            }
                        }
                    }
                }

                // =========================================================================
                // SECTION 3: OUTPUT DEVICES (SINKS)
                // =========================================================================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(6 * root.resolutionScale)

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.round(6 * root.resolutionScale)

                        Text {
                            text: "OUTPUT DEVICES"
                            font.pixelSize: Math.round(10 * root.resolutionScale)
                            font.weight: Font.Bold
                            font.capitalization: Font.AllUppercase
                            color: root.headerColor
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Sinks List
                    Repeater {
                        model: (backend && backend.audioSinks) ? backend.audioSinks : []

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: sinkItemCol.implicitHeight + Math.round(12 * root.resolutionScale)
                            radius: Math.round(8 * root.resolutionScale)
                            color: modelData.is_default
                                ? (root.isDarkTheme ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08))
                                : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.025))
                            border.color: modelData.is_default ? root.accentColor : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(0, 0, 0, 0.05))
                            border.width: 1

                            ColumnLayout {
                                id: sinkItemCol
                                anchors.fill: parent
                                anchors.margins: Math.round(6 * root.resolutionScale)
                                spacing: Math.round(4 * root.resolutionScale)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.round(6 * root.resolutionScale)

                                    // Default Sink Selector Radio
                                    Rectangle {
                                        implicitWidth: Math.round(16 * root.resolutionScale)
                                        implicitHeight: implicitWidth
                                        radius: implicitWidth / 2
                                        color: modelData.is_default ? root.accentColor : "transparent"
                                        border.color: modelData.is_default ? root.accentColor : root.subTextColor
                                        border.width: 1.5

                                        Kirigami.Icon {
                                            visible: modelData.is_default
                                            anchors.centerIn: parent
                                            source: "checkmark-symbolic"
                                            implicitWidth: Math.round(10 * root.resolutionScale)
                                            implicitHeight: implicitWidth
                                            isMask: true
                                            color: root.accentTextColor
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (backend && !modelData.is_default) {
                                                    backend.setDefaultSink(modelData.name)
                                                }
                                            }
                                        }
                                    }

                                    Kirigami.Icon {
                                        source: (modelData.icon && modelData.icon !== "") ? modelData.icon : "audio-speakers-symbolic"
                                        implicitWidth: Math.round(16 * root.resolutionScale)
                                        implicitHeight: implicitWidth
                                        isMask: true
                                        color: modelData.is_default ? root.accentColor : root.textColor
                                    }

                                    Text {
                                        text: modelData.description || modelData.name || "Output Device"
                                        font.pixelSize: Math.round(11 * root.resolutionScale)
                                        font.weight: modelData.is_default ? Font.DemiBold : Font.Normal
                                        color: root.textColor
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // Default Badge
                                    Rectangle {
                                        visible: modelData.is_default
                                        implicitWidth: defaultBadgeText.implicitWidth + 8
                                        implicitHeight: Math.round(15 * root.resolutionScale)
                                        radius: implicitHeight / 2
                                        color: root.accentColor

                                        Text {
                                            id: defaultBadgeText
                                            anchors.centerIn: parent
                                            text: "Default"
                                            font.pixelSize: Math.round(9 * root.resolutionScale)
                                            font.weight: Font.Bold
                                            color: root.accentTextColor
                                        }
                                    }

                                    Text {
                                        text: modelData.muted ? "Muted" : (modelData.volume + "%")
                                        font.pixelSize: Math.round(10 * root.resolutionScale)
                                        font.weight: Font.DemiBold
                                        color: modelData.muted ? (root.isDarkTheme ? "#f66" : "#c00") : root.subTextColor
                                    }
                                }

                                CurvedSlider {
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(20, Math.round(22 * root.resolutionScale))
                                    value: modelData.volume
                                    isMuted: modelData.muted
                                    iconName: modelData.muted ? "audio-volume-muted-symbolic" : (modelData.icon || "audio-speakers-symbolic")
                                    isDarkTheme: root.isDarkTheme
                                    accentColor: root.accentColor
                                    accentTextColor: root.accentTextColor
                                    onValueChangedByUser: function(v) {
                                        if (backend) backend.setSinkVolume(modelData.index, v)
                                    }
                                    onIconClicked: {
                                        if (backend) backend.toggleSinkMute(modelData.index)
                                    }
                                }
                            }
                        }
                    }
                }

                // =========================================================================
                // SECTION 4: INPUT DEVICES (MICROPHONES / SOURCES)
                // =========================================================================
                ColumnLayout {
                    visible: backend && backend.audioSources && backend.audioSources.length > 0
                    Layout.fillWidth: true
                    spacing: Math.round(6 * root.resolutionScale)

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.round(6 * root.resolutionScale)

                        Text {
                            text: "INPUT DEVICES (MICROPHONES)"
                            font.pixelSize: Math.round(10 * root.resolutionScale)
                            font.weight: Font.Bold
                            font.capitalization: Font.AllUppercase
                            color: root.headerColor
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Sources List
                    Repeater {
                        model: (backend && backend.audioSources) ? backend.audioSources : []

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: srcItemCol.implicitHeight + Math.round(12 * root.resolutionScale)
                            radius: Math.round(8 * root.resolutionScale)
                            color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.025)
                            border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(0, 0, 0, 0.05)
                            border.width: 1

                            ColumnLayout {
                                id: srcItemCol
                                anchors.fill: parent
                                anchors.margins: Math.round(6 * root.resolutionScale)
                                spacing: Math.round(4 * root.resolutionScale)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.round(6 * root.resolutionScale)

                                    Kirigami.Icon {
                                        source: (modelData.icon && modelData.icon !== "") ? modelData.icon : "audio-input-microphone-symbolic"
                                        implicitWidth: Math.round(16 * root.resolutionScale)
                                        implicitHeight: implicitWidth
                                        isMask: true
                                        color: modelData.muted ? (root.isDarkTheme ? "#f66" : "#c00") : root.textColor
                                    }

                                    Text {
                                        text: modelData.description || modelData.name || "Microphone"
                                        font.pixelSize: Math.round(11 * root.resolutionScale)
                                        font.weight: Font.Medium
                                        color: root.textColor
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.muted ? "Muted" : (modelData.volume + "%")
                                        font.pixelSize: Math.round(10 * root.resolutionScale)
                                        font.weight: Font.DemiBold
                                        color: modelData.muted ? (root.isDarkTheme ? "#f66" : "#c00") : root.subTextColor
                                    }
                                }

                                CurvedSlider {
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(20, Math.round(22 * root.resolutionScale))
                                    value: modelData.volume
                                    isMuted: modelData.muted
                                    iconName: modelData.muted ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic"
                                    isDarkTheme: root.isDarkTheme
                                    accentColor: root.accentColor
                                    accentTextColor: root.accentTextColor
                                    onValueChangedByUser: function(v) {
                                        if (backend) backend.setSourceVolume(modelData.index, v)
                                    }
                                    onIconClicked: {
                                        if (backend) backend.toggleSourceMute(modelData.index)
                                    }
                                }
                            }
                        }
                    }
                }

                // =========================================================================
                // SECTION 5: FOOTER - CONFIGURE SOUND IN SYSTEM SETTINGS
                // =========================================================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * root.resolutionScale)
                    radius: Math.round(8 * root.resolutionScale)
                    color: soundSettingsMouse.containsMouse
                        ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))
                        : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03))
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.07)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Math.round(6 * root.resolutionScale)

                        Kirigami.Icon {
                            source: "preferences-desktop-sound"
                            implicitWidth: Math.round(14 * root.resolutionScale)
                            implicitHeight: implicitWidth
                            fallback: "configure"
                        }

                        Text {
                            text: "Configure Audio Devices in System Settings..."
                            font.pixelSize: Math.round(11 * root.resolutionScale)
                            font.weight: Font.Medium
                            color: root.textColor
                        }
                    }

                    MouseArea {
                        id: soundSettingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (backend && typeof backend.openSoundSettings === "function") {
                                backend.openSoundSettings()
                            }
                        }
                    }
                }
            }
        }
    }
}
