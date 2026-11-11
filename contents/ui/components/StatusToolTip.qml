import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

/**
 * StatusToolTip.qml - Sleek status preview popup for KDE panel capsule indicators
 * Floats cleanly above or below the panel without clipping, providing live status.
 */
PlasmaComponents.ToolTip {
    id: root

    property string title: ""
    property string status: ""
    property string subStatus: ""
    property string iconName: ""
    property color iconColor: isDarkTheme ? "#f6f8fa" : "#1a1a1a"
    property bool showProgressBar: false
    property int progressValue: 0
    property color progressColor: "#3584e4"
    property bool isDarkTheme: true
    property bool isTopPanel: true

    delay: 150
    timeout: -1

    x: parent ? Math.round((parent.width - implicitWidth) / 2) : 0
    y: isTopPanel ? (parent ? (parent.height + 8) : 36) : (-implicitHeight - 8)

    margins: 0
    topPadding: 8
    bottomPadding: 8
    leftPadding: 12
    rightPadding: 12

    background: Rectangle {
        radius: 10
        color: root.isDarkTheme ? Qt.rgba(28/255, 28/255, 34/255, 0.96) : Qt.rgba(255/255, 255/255, 255/255, 0.96)
        border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(0, 0, 0, 0.14)
        border.width: 1
    }

    contentItem: Item {
        id: contentBox
        implicitWidth: Math.max(150, Math.min(280, mainCol.implicitWidth))
        implicitHeight: mainCol.implicitHeight

        ColumnLayout {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                Kirigami.Icon {
                    visible: Boolean(root.iconName && root.iconName !== "")
                    source: root.iconName
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    isMask: true
                    color: root.iconColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.title
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: root.isDarkTheme ? "#ffffff" : "#111111"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.maximumWidth: 250
                    }

                    Text {
                        visible: Boolean(root.status && root.status !== "")
                        text: root.status
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.82) : Qt.rgba(0, 0, 0, 0.80)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.maximumWidth: 250
                    }

                    Text {
                        visible: Boolean(root.subStatus && root.subStatus !== "")
                        text: root.subStatus
                        font.pixelSize: 10
                        color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.55) : Qt.rgba(0, 0, 0, 0.55)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.maximumWidth: 250
                    }
                }
            }

            // Mini status progress bar (Volume / Battery fill / Signal)
            Rectangle {
                visible: root.showProgressBar
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(0, 0, 0, 0.12)
                clip: true

                Rectangle {
                    width: Math.max(0, Math.min(parent.width, Math.round(parent.width * (Math.max(0, Math.min(100, root.progressValue)) / 100))))
                    height: parent.height
                    radius: 2
                    color: root.progressColor
                }
            }
        }
    }
}
