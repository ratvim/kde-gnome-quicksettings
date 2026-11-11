import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    readonly property string defaultOrder: "wifi,bluetooth,location,mic,camera,kdeconnect,dark,night,airplane,dnd,hotspot,power"
    property string cfg_tilesOrder: defaultOrder
    property alias cfg_toggleRowsPerPage: rowsSpinBox.value
    property string cfg_panelBackgroundMode: "follow_panel"
    property real cfg_customOpacity: 0.75
    property alias cfg_panelBlurEnabled: blurCheck.checked

    function getMeta(key) {
        switch (key) {
        case "wifi": return { name: i18n("Wi-Fi"), icon: "network-wireless-symbolic" }
        case "bluetooth": return { name: i18n("Bluetooth"), icon: "preferences-system-bluetooth" }
        case "location": return { name: i18n("Location Access"), icon: "find-location-symbolic" }
        case "mic": return { name: i18n("Microphone Access"), icon: "audio-input-microphone-symbolic" }
        case "camera": return { name: i18n("Camera Access"), icon: "camera-photo-symbolic" }
        case "kdeconnect": return { name: i18n("KDE Connect"), icon: "kdeconnect" }
        case "dark": return { name: i18n("Dark Style"), icon: "weather-clear-night" }
        case "night": return { name: i18n("Night Light"), icon: "redshift-status-on" }
        case "airplane": return { name: i18n("Airplane Mode"), icon: "airplane-mode-symbolic" }
        case "dnd": return { name: i18n("Do Not Disturb"), icon: "notifications-disabled" }
        case "hotspot": return { name: i18n("Wi-Fi Hotspot"), icon: "network-wireless-hotspot" }
        case "power": return { name: i18n("Power Saver"), icon: "battery-profile-powersave" }
        default: return { name: key, icon: "application-x-addon" }
        }
    }

    function syncFromCfg() {
        var str = (cfg_tilesOrder && cfg_tilesOrder.length > 0) ? cfg_tilesOrder : defaultOrder
        var parts = str.split(",")
        var clean = []
        var valid = defaultOrder.split(",")
        for (var i = 0; i < parts.length; ++i) {
            var k = parts[i].trim()
            if (valid.indexOf(k) !== -1 && clean.indexOf(k) === -1) {
                clean.push(k)
            }
        }
        for (var j = 0; j < valid.length; ++j) {
            if (clean.indexOf(valid[j]) === -1) {
                clean.push(valid[j])
            }
        }
        
        togglesListModel.clear()
        for (var m = 0; m < clean.length; ++m) {
            var meta = getMeta(clean[m])
            togglesListModel.append({
                "key": clean[m],
                "title": meta.name,
                "iconName": meta.icon
            })
        }
    }

    function saveOrderFromModel() {
        var arr = []
        for (var i = 0; i < visualModel.items.count; ++i) {
            arr.push(visualModel.items.get(i).model.key)
        }
        cfg_tilesOrder = arr.join(",")
    }

    function moveItem(fromIndex, toIndex) {
        if (fromIndex < 0 || toIndex < 0 || fromIndex >= visualModel.items.count || toIndex >= visualModel.items.count || fromIndex === toIndex) {
            return
        }
        visualModel.items.move(fromIndex, toIndex)
        saveOrderFromModel()
    }

    Component.onCompleted: {
        syncFromCfg()
    }

    onCfg_tilesOrderChanged: {
        // Only re-sync if the model count is empty or does not match
        if (togglesListModel.count === 0) {
            syncFromCfg()
        }
    }

    ListModel {
        id: togglesListModel
    }

    DelegateModel {
        id: visualModel
        model: togglesListModel

        delegate: Item {
            id: delegateRoot
            readonly property int visualIndex: DelegateModel.itemsIndex
            readonly property int itemsPerPage: rowsSpinBox.value * 2
            readonly property int pageNum: Math.floor(visualIndex / itemsPerPage) + 1

            width: reorderListView.width
            height: 50

            DropArea {
                anchors.fill: parent
                onEntered: function(drag) {
                    var from = drag.source.visualIndex
                    var to = delegateRoot.visualIndex
                    if (from !== undefined && to !== undefined && from !== to) {
                        visualModel.items.move(from, to)
                    }
                }
            }

            Rectangle {
                id: itemCard
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 44
                radius: 8

                color: dragMouse.drag.active
                       ? (Kirigami.Theme.highlightColor ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : Qt.rgba(0.2, 0.6, 1.0, 0.2))
                       : (delegateRoot.visualIndex % 2 === 0 ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04) : "transparent")

                border.color: dragMouse.drag.active
                              ? (Kirigami.Theme.highlightColor || "#3584e4")
                              : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                border.width: dragMouse.drag.active ? 2 : 1
                scale: dragMouse.drag.active ? 1.02 : 1.0
                z: dragMouse.drag.active ? 99 : 1

                Behavior on scale { NumberAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Drag.active: dragMouse.drag.active
                Drag.source: delegateRoot
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2

                states: [
                    State {
                        when: dragMouse.drag.active
                        ParentChange { target: itemCard; parent: root }
                        AnchorChanges { target: itemCard; anchors.horizontalCenter: undefined; anchors.verticalCenter: undefined }
                    }
                ]

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    // Drag Grip Handle Icon
                    Kirigami.Icon {
                        source: "view-list-tree"
                        fallback: "handle-sort"
                        implicitWidth: 16
                        implicitHeight: 16
                        opacity: dragMouse.containsMouse ? 1.0 : 0.4
                        color: Kirigami.Theme.textColor
                    }

                    // Position Number
                    Label {
                        text: (delegateRoot.visualIndex + 1) + "."
                        font.bold: true
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: 24
                        horizontalAlignment: Text.AlignRight
                    }

                    // Symbolic Icon
                    Kirigami.Icon {
                        source: model.iconName
                        implicitWidth: 20
                        implicitHeight: 20
                    }

                    // Title
                    Label {
                        text: model.title
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Dynamic Page Badge
                    Rectangle {
                        radius: 10
                        color: delegateRoot.pageNum === 1
                               ? Qt.rgba(0.2, 0.6, 1.0, 0.15)
                               : (delegateRoot.pageNum === 2 ? Qt.rgba(0.2, 0.8, 0.4, 0.15) : Qt.rgba(0.9, 0.6, 0.1, 0.15))
                        Layout.preferredHeight: 20
                        Layout.preferredWidth: pageTagLabel.implicitWidth + 12

                        Label {
                            id: pageTagLabel
                            anchors.centerIn: parent
                            text: i18n("Page %1", delegateRoot.pageNum)
                            font.pixelSize: 10
                            font.bold: true
                            color: delegateRoot.pageNum === 1
                                   ? (Kirigami.Theme.highlightColor || "#3584e4")
                                   : (delegateRoot.pageNum === 2 ? "#2ec27e" : "#f57900")
                        }
                    }

                    // Step Up Button
                    ToolButton {
                        icon.name: "arrow-up"
                        text: i18n("Move Up")
                        display: AbstractButton.IconOnly
                        enabled: delegateRoot.visualIndex > 0
                        onClicked: root.moveItem(delegateRoot.visualIndex, delegateRoot.visualIndex - 1)
                    }

                    // Step Down Button
                    ToolButton {
                        icon.name: "arrow-down"
                        text: i18n("Move Down")
                        display: AbstractButton.IconOnly
                        enabled: delegateRoot.visualIndex < visualModel.items.count - 1
                        onClicked: root.moveItem(delegateRoot.visualIndex, delegateRoot.visualIndex + 1)
                    }
                }

                MouseArea {
                    id: dragMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    drag.target: itemCard
                    drag.axis: Drag.YAxis

                    onReleased: {
                        root.saveOrderFromModel()
                    }
                }
            }
        }
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // Section 1: Page Layout & Rows Configuration
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Page Layout & Pagination")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Label {
                text: i18n("Toggle Rows per Page:")
                font.bold: true
            }

            SpinBox {
                id: rowsSpinBox
                from: 3
                to: 8
                value: 4
                editable: false
            }

            Label {
                text: i18n("(%1 toggles per page)", rowsSpinBox.value * 2)
                color: Kirigami.Theme.disabledTextColor
            }

            Item { Layout.fillWidth: true }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Drag toggles up or down to rearrange their order. You can drag by grabbing anywhere on a row. The Page badges dynamically show which page each toggle will appear on based on your chosen rows per page.")
            visible: true
        }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: i18n("Reset to Default Order")
                icon.name: "edit-undo"
                onClicked: {
                    cfg_tilesOrder = defaultOrder
                    syncFromCfg()
                }
            }
            Item { Layout.fillWidth: true }
        }

        ListView {
            id: reorderListView
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            interactive: false
            model: visualModel

            displaced: Transition {
                NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutQuad }
            }
        }

        // Section 2: Panel Background & Blur
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Panel Background, Transparency & Blur")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Label {
                text: i18n("Background Appearance:")
                font.bold: true
            }

            ComboBox {
                id: bgModeCombo
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: i18n("Follow Attached Panel (Automatic)"), value: "follow_panel" },
                    { text: i18n("Frosted Glass Translucent"), value: "translucent" },
                    { text: i18n("Solid Opaque"), value: "opaque" }
                ]
                currentIndex: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].value === root.cfg_panelBackgroundMode) return i
                    }
                    return 0
                }
                onActivated: {
                    root.cfg_panelBackgroundMode = currentValue
                }
            }

            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            visible: root.cfg_panelBackgroundMode === "translucent"

            Label {
                text: i18n("Custom Opacity:")
                font.bold: true
            }

            Slider {
                id: opacitySlider
                from: 0.20
                to: 1.00
                stepSize: 0.05
                value: root.cfg_customOpacity
                onMoved: {
                    root.cfg_customOpacity = Math.round(value * 100) / 100
                }
            }

            Label {
                text: Math.round(opacitySlider.value * 100) + "%"
                color: Kirigami.Theme.disabledTextColor
            }

            Item { Layout.fillWidth: true }
        }

        CheckBox {
            id: blurCheck
            text: i18n("Enable blur behind card (restricted to curved card region via KWin)")
            checked: true
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("In 'Follow Attached Panel' mode, Quick Settings automatically adopts the attached panel's background color, opacity (including custom panel colorizer presets), and blur behind window.")
            visible: true
        }
    }
}
