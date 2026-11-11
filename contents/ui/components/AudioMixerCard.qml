import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * AudioMixerCard.qml - Expandable Audio Stream & Device Mixer for GNOME Quick Settings
 * Provides per-application playback sliders, output device selection, and microphone controls,
 * matching KDE Global Volume Settings (kcm_pulseaudio).
 */
Rectangle {
    id: root

    property var backend: null
    property bool isDarkTheme: true
    property real resolutionScale: 1.0

    signal closeRequested()

    implicitWidth: parent ? parent.width : 360
    implicitHeight: mainLayout.implicitHeight + (Math.round(16 * resolutionScale))

    radius: Math.round(14 * resolutionScale)
    color: isDarkTheme ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.04)
    border.color: isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.07)
    border.width: 1

    clip: true

    readonly property color textColor: isDarkTheme ? "#f6f8fa" : "#1a1a1a"
    readonly property color subTextColor: isDarkTheme ? Qt.rgba(255, 255, 255, 0.65) : Qt.rgba(0, 0, 0, 0.60)
    readonly property color headerColor: isDarkTheme ? Qt.rgba(255, 255, 255, 0.50) : Qt.rgba(0, 0, 0, 0.50)
    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"
    readonly property color accentTextColor: (Kirigami.Theme.highlightedTextColor !== undefined && Kirigami.Theme.highlightedTextColor.a > 0) ? Kirigami.Theme.highlightedTextColor : "#ffffff"

    // Auto-refresh timer while mixer is open to catch newly launched apps
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
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Math.round(12 * root.resolutionScale)
        spacing: Math.round(12 * root.resolutionScale)

        // 1. Header Bar: Title, Count badge, Refresh & Close
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(6 * root.resolutionScale)

            Kirigami.Icon {
                source: "audio-card-symbolic"
                implicitWidth: Math.round(16 * root.resolutionScale)
                implicitHeight: implicitWidth
                isMask: true
                color: root.accentColor
            }

            Text {
                text: "Audio Mixer"
                font.pixelSize: Math.round(12 * root.resolutionScale)
                font.weight: Font.DemiBold
                color: root.textColor
            }

            Item { Layout.fillWidth: true }

            // Refresh Button
            Rectangle {
                implicitWidth: Math.round(24 * root.resolutionScale)
                implicitHeight: implicitWidth
                radius: implicitWidth / 2
                color: refMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "view-refresh-symbolic"
                    implicitWidth: Math.round(13 * root.resolutionScale)
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

            // Close / Collapse Button
            Rectangle {
                implicitWidth: Math.round(24 * root.resolutionScale)
                implicitHeight: implicitWidth
                radius: implicitWidth / 2
                color: closeMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "go-up-symbolic"
                    implicitWidth: Math.round(13 * root.resolutionScale)
                    implicitHeight: implicitWidth
                    isMask: true
                    color: root.subTextColor
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        // =========================================================================
        // SECTION 1: APPLICATIONS (PLAYBACK STREAMS)
        // =========================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(6 * root.resolutionScale)

            // Section Header
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
                    implicitWidth: appCountText.implicitWidth + 8
                    implicitHeight: Math.round(14 * root.resolutionScale)
                    radius: implicitHeight / 2
                    color: root.accentColor

                    Text {
                        id: appCountText
                        anchors.centerIn: parent
                        text: backend && backend.audioSinkInputs ? backend.audioSinkInputs.length : "0"
                        font.pixelSize: Math.round(9 * root.resolutionScale)
                        font.weight: Font.Bold
                        color: root.accentTextColor
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // If no apps are currently playing audio
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

            // List of Application Streams
            Repeater {
                model: (backend && backend.audioSinkInputs) ? backend.audioSinkInputs : []

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: appCol.implicitHeight + Math.round(12 * root.resolutionScale)
                    radius: Math.round(8 * root.resolutionScale)
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.025)
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(0, 0, 0, 0.05)
                    border.width: 1

                    ColumnLayout {
                        id: appCol
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
        // SECTION 2: OUTPUT DEVICES (PLAYBACK SINKS)
        // =========================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(6 * root.resolutionScale)

            // Section Header
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

            // List of Output Sinks
            Repeater {
                model: (backend && backend.audioSinks) ? backend.audioSinks : []

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: sinkCol.implicitHeight + Math.round(12 * root.resolutionScale)
                    radius: Math.round(8 * root.resolutionScale)
                    color: modelData.is_default
                        ? (root.isDarkTheme ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08))
                        : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.025))
                    border.color: modelData.is_default ? root.accentColor : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(0, 0, 0, 0.05))
                    border.width: 1

                    ColumnLayout {
                        id: sinkCol
                        anchors.fill: parent
                        anchors.margins: Math.round(6 * root.resolutionScale)
                        spacing: Math.round(4 * root.resolutionScale)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(6 * root.resolutionScale)

                            // Default Sink Selector Radio / Check
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

                            // "Default" badge
                            Rectangle {
                                visible: modelData.is_default
                                implicitWidth: defText.implicitWidth + 8
                                implicitHeight: Math.round(15 * root.resolutionScale)
                                radius: implicitHeight / 2
                                color: root.accentColor

                                Text {
                                    id: defText
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
        // SECTION 3: INPUT DEVICES (MICROPHONES / SOURCES)
        // =========================================================================
        ColumnLayout {
            visible: backend && backend.audioSources && backend.audioSources.length > 0
            Layout.fillWidth: true
            spacing: Math.round(6 * root.resolutionScale)

            // Section Header
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

            // List of Input Sources
            Repeater {
                model: (backend && backend.audioSources) ? backend.audioSources : []

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: srcCol.implicitHeight + Math.round(12 * root.resolutionScale)
                    radius: Math.round(8 * root.resolutionScale)
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.025)
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(0, 0, 0, 0.05)
                    border.width: 1

                    ColumnLayout {
                        id: srcCol
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
        // SECTION 4: FOOTER ACTION - LAUNCH SOUND SETTINGS
        // =========================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.round(30 * root.resolutionScale)
            radius: Math.round(8 * root.resolutionScale)
            color: settingsMouse.containsMouse
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
                    text: "Configure Audio Devices..."
                    font.pixelSize: Math.round(11 * root.resolutionScale)
                    font.weight: Font.Medium
                    color: root.textColor
                }
            }

            MouseArea {
                id: settingsMouse
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
