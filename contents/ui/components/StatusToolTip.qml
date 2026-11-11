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
    y: isTopPanel ? (parent ? (parent.height + 6) : 32) : (-implicitHeight - 6)

    margins: 4
    topPadding: 8
    bottomPadding: 8
    leftPadding: 10
    rightPadding: 10

    background: Rectangle {
        radius: 10
        color: root.isDarkTheme ? Qt.rgba(26/255, 26/255, 32/255, 0.96) : Qt.rgba(250/255, 250/255, 252/255, 0.96)
        border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(0, 0, 0, 0.14)
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: 5
        implicitWidth: Math.max(130, Math.min(230, textCol.implicitWidth + 32))

        RowLayout {
            spacing: 8
            Layout.fillWidth: true

            Kirigami.Icon {
                visible: Boolean(root.iconName)
                source: root.iconName
                implicitWidth: 16
                implicitHeight: 16
                isMask: true
                color: root.iconColor
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                id: textCol
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: root.title
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: Boolean(root.status)
                    text: root.status
                    font.pixelSize: 11
                    color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.78) : Qt.rgba(0, 0, 0, 0.78)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: Boolean(root.subStatus)
                    text: root.subStatus
                    font.pixelSize: 10
                    color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.52) : Qt.rgba(0, 0, 0, 0.52)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // Mini status progress bar (Volume / Battery fill)
        Rectangle {
            visible: root.showProgressBar
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(0, 0, 0, 0.12)

            Rectangle {
                width: Math.max(0, Math.min(parent.width, Math.round(parent.width * (Math.max(0, Math.min(100, root.progressValue)) / 100))))
                height: parent.height
                radius: 2
                color: root.progressColor
            }
        }
    }
}
