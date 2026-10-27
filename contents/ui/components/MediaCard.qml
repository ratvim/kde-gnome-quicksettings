import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * MediaCard.qml - GNOME-style curved MPRIS media player card
 * Features:
 *   - Rounded card with glassmorphic background (radius: 18px)
 *   - Album artwork / cover thumbnail (radius: 12px)
 *   - Track title & Artist display
 *   - Timeline seekbar / progress track
 *   - Play / Pause, Previous, Next controls
 */
Rectangle {
    id: root

    property string trackTitle: "Starboy (feat. Daft Punk)"
    property string artist: "The Weeknd"
    property string albumArt: ""
    property bool isPlaying: true
    property real progress: 0.42 // 0.0 to 1.0
    property string currentTimeText: "1:32"
    property string totalTimeText: "3:50"
    property bool isDarkTheme: true

    signal playPauseClicked()
    signal previousClicked()
    signal nextClicked()
    signal seek(real ratio)

    implicitWidth: 360
    implicitHeight: 92
    radius: 18
    color: isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
    border.color: isDarkTheme ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.08)
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Album Art Box
        Rectangle {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: 12
            color: isDarkTheme ? "#2c3e50" : "#bdc3c7"
            clip: true

            Image {
                id: albumImg
                anchors.fill: parent
                source: root.albumArt
                fillMode: Image.PreserveAspectCrop
                visible: root.albumArt !== ""
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                visible: !albumImg.visible
                implicitWidth: 28
                implicitHeight: 28
                source: "audio-x-generic"
                isMask: true
                color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            }
        }

        // Info and Controls Column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                // Track and Artist
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: root.trackTitle
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.artist
                        font.pixelSize: 11
                        color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                        elide: Text.ElideRight
                    }
                }

                // Controls: Prev, Play/Pause, Next
                RowLayout {
                    spacing: 4

                    // Previous Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            implicitWidth: 14
                            implicitHeight: 14
                            source: "media-skip-backward-symbolic"
                            isMask: true
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        }
                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.previousClicked()
                        }
                    }

                    // Play/Pause Button (Primary Pill)
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: root.isDarkTheme ? "#ffffff" : "#3584e4"

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            implicitWidth: 16
                            implicitHeight: 16
                            source: root.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                            isMask: true
                            color: root.isDarkTheme ? "#1a1a1a" : "#ffffff"
                        }
                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playPauseClicked()
                        }
                    }

                    // Next Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            implicitWidth: 14
                            implicitHeight: 14
                            source: "media-skip-forward-symbolic"
                            isMask: true
                            color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        }
                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.nextClicked()
                        }
                    }
                }
            }

            // Progress Timeline Bar
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 14

                Rectangle {
                    id: progressTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 2
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.15)

                    Rectangle {
                        height: parent.height
                        width: parent.width * root.progress
                        radius: 2
                        color: root.isDarkTheme ? "#3584e4" : "#3584e4"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var ratio = Math.max(0, Math.min(1, mouse.x / width))
                        root.seek(ratio)
                    }
                }
            }
        }
    }
}
