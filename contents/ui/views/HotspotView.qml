import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * HotspotView.qml - GNOME-style Mobile Hotspot Sub-View (Plasma 6)
 * Displays Hotspot active status, SSID, password, bidirectional editing,
 * and seamless synchronization with KDE Global Settings (~/.config/plasma-nm).
 */
Rectangle {
    id: root

    property bool isDarkTheme: true
    property bool hotspotEnabled: false
    property string hotspotSsid: ""
    property string hotspotPassword: ""
    property bool showPassword: false

    // Inline credential editor state
    property bool isEditing: false
    property string editSsid: ""
    property string editPassword: ""
    property string validationError: ""

    readonly property color accentColor: (Kirigami.Theme.highlightColor !== undefined && Kirigami.Theme.highlightColor.a > 0) ? Kirigami.Theme.highlightColor : "#3584e4"

    signal backClicked()
    signal toggleHotspot()
    signal refreshClicked()
    signal openSettingsClicked()
    signal configureHotspot(string ssid, string password)

    // Keep editing fields synchronized when external updates arrive
    onHotspotSsidChanged: {
        if (!root.isEditing) {
            root.editSsid = root.hotspotSsid
        }
    }
    onHotspotPasswordChanged: {
        if (!root.isEditing) {
            root.editPassword = root.hotspotPassword
        }
    }

    function startEditing() {
        root.editSsid = root.hotspotSsid || ""
        root.editPassword = root.hotspotPassword || ""
        root.validationError = ""
        root.isEditing = true
    }

    function validate() {
        if (!root.editSsid || root.editSsid.trim().length === 0) {
            root.validationError = "Network name (SSID) cannot be empty."
            return false
        }
        if (!root.editPassword || root.editPassword.length < 8) {
            root.validationError = "Password must be at least 8 characters (WPA2 requirement)."
            return false
        }
        root.validationError = ""
        return true
    }

    function saveCredentials() {
        if (validate()) {
            root.configureHotspot(root.editSsid.trim(), root.editPassword)
            root.isEditing = false
        }
    }

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // ============================================================
        // Header: Back button & Master Hotspot Switch
        // ============================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
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
                    onClicked: {
                        if (root.isEditing) {
                            root.isEditing = false
                        } else {
                            root.backClicked()
                        }
                    }
                }
            }

            Text {
                text: "Wi-Fi Hotspot"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
            }

            // Master Hotspot Switch (On = Active, Off = Disabled)
            Switch {
                checked: root.hotspotEnabled
                onToggled: root.toggleHotspot()
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }

        // Subtitle explanation
        Text {
            Layout.fillWidth: true
            text: {
                if (root.hotspotEnabled) {
                    return "Broadcasting Wi-Fi network. Other devices can connect using the credentials below:"
                }
                return "Share your internet connection with other devices over Wi-Fi. Simultaneous Wi-Fi client and Hotspot are supported on multi-interface and concurrency-capable hardware."
            }
            font.pixelSize: 11
            color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            wrapMode: Text.WordWrap
        }

        // ============================================================
        // MODE A: VIEW MODE (Displays SSID & Password Cards)
        // ============================================================
        ColumnLayout {
            Layout.fillWidth: true
            visible: !root.isEditing
            spacing: 8

            // 1. Network Name (SSID) Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                radius: 14
                color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.03)
                border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
                border.width: 1

                // Left Icon Badge
                Rectangle {
                    id: ssidBadge
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 10
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: "network-wireless-hotspot-symbolic"
                        fallback: Qt.resolvedUrl("../../icons/network-wireless-hotspot-symbolic.svg")
                        isMask: true
                        color: root.hotspotEnabled ? "#2ec27e" : (root.isDarkTheme ? "#f6f8fa" : "#1a1a1a")
                    }
                }

                // Right Status Badge (Active or Inactive)
                Rectangle {
                    id: activeBadge
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.hotspotEnabled ? 68 : 72
                    height: 28
                    radius: 14
                    color: root.hotspotEnabled ? (root.isDarkTheme ? Qt.rgba(46/255, 194/255, 126/255, 0.16) : Qt.rgba(46/255, 194/255, 126/255, 0.12))
                                               : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
                    border.color: root.hotspotEnabled ? "#2ec27e" : (root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.12))
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: root.hotspotEnabled ? "#2ec27e" : (root.isDarkTheme ? "#888888" : "#999999")
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.hotspotEnabled ? "Active" : "Inactive"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: root.hotspotEnabled ? "#2ec27e" : (root.isDarkTheme ? "#9aa0a6" : "#606770")
                        }
                    }
                }

                // Middle Text: Network Name
                Column {
                    anchors.left: ssidBadge.right
                    anchors.leftMargin: 12
                    anchors.right: activeBadge.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Network Name (SSID)"
                        font.pixelSize: 10
                        color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.hotspotSsid || "Hotspot"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        elide: Text.ElideRight
                    }
                }
            }

            // 2. Wi-Fi Password Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                radius: 14
                color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.03)
                border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
                border.width: 1

                // Left Icon Badge
                Rectangle {
                    id: passBadge
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 10
                    color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: "system-lock-screen-symbolic"
                        fallback: Qt.resolvedUrl("../../icons/system-lock-screen-symbolic.svg")
                        isMask: true
                        color: root.isDarkTheme ? "#f6f8fa" : "#1a1a1a"
                    }
                }

                // Right Show/Hide Action Button
                Rectangle {
                    id: showPassBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 64
                    height: 28
                    radius: 14
                    color: passMouse.containsMouse ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10))
                                                   : (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
                    border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.12)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.showPassword ? "Hide" : "Show"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                    }

                    MouseArea {
                        id: passMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showPassword = !root.showPassword
                    }
                }

                // Middle Text: Password
                Column {
                    anchors.left: passBadge.right
                    anchors.leftMargin: 12
                    anchors.right: showPassBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Wi-Fi Password"
                        font.pixelSize: 10
                        color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: {
                            if (!root.hotspotPassword) return "None (Open Network)"
                            return root.showPassword ? root.hotspotPassword : "••••••••••••"
                        }
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        font.family: root.showPassword ? "monospace" : "default"
                        color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                        elide: Text.ElideRight
                    }
                }
            }

            // 3. Quick Action Buttons: Configure & System Settings
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    Layout.fillWidth: true
                    text: "Configure Hotspot..."
                    icon.name: "document-edit-symbolic"
                    onClicked: root.startEditing()
                }

                Button {
                    Layout.fillWidth: true
                    text: "Global Settings..."
                    icon.name: "settings-configure-symbolic"
                    onClicked: root.openSettingsClicked()
                }
            }
        }

        // ============================================================
        // MODE B: EDIT MODE (Inline Hotspot Credentials Editor)
        // ============================================================
        Rectangle {
            Layout.fillWidth: true
            visible: root.isEditing
            radius: 14
            color: root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.03)
            border.color: root.isDarkTheme ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(0, 0, 0, 0.1)
            border.width: 1
            implicitHeight: editCol.implicitHeight + 24

            ColumnLayout {
                id: editCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    text: "Configure Hotspot Credentials"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: root.isDarkTheme ? "#ffffff" : "#1a1a1a"
                }

                Text {
                    Layout.fillWidth: true
                    text: "Changes synchronize directly with KDE Global Settings (~/.config/plasma-nm) and NetworkManager."
                    font.pixelSize: 10
                    color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                    wrapMode: Text.WordWrap
                }

                // SSID Input
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Network Name (SSID):"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: root.isDarkTheme ? "#cccccc" : "#333333"
                    }

                    TextField {
                        id: ssidInput
                        Layout.fillWidth: true
                        text: root.editSsid
                        placeholderText: "Enter hotspot network name"
                        onTextChanged: {
                            root.editSsid = text
                            root.validate()
                        }
                    }
                }

                // Password Input
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Wi-Fi Password (minimum 8 characters):"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: root.isDarkTheme ? "#cccccc" : "#333333"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        TextField {
                            id: passInput
                            Layout.fillWidth: true
                            text: root.editPassword
                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                            placeholderText: "Enter password (min 8 characters)"
                            onTextChanged: {
                                root.editPassword = text
                                root.validate()
                            }
                        }

                        Button {
                            text: root.showPassword ? "Hide" : "Show"
                            onClicked: root.showPassword = !root.showPassword
                        }
                    }
                }

                // Validation / Status Error Warning
                Text {
                    Layout.fillWidth: true
                    visible: root.validationError.length > 0 || (root.editPassword.length > 0 && root.editPassword.length < 8)
                    text: {
                        if (root.validationError.length > 0) return root.validationError
                        if (root.editPassword.length > 0 && root.editPassword.length < 8) {
                            return "Password must have at least 8 characters (current: " + root.editPassword.length + ")."
                        }
                        return ""
                    }
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: "#e74c3c"
                    wrapMode: Text.WordWrap
                }

                // Edit Action Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        Layout.fillWidth: true
                        text: "Cancel"
                        onClicked: {
                            root.isEditing = false
                            root.validationError = ""
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "Save & Synchronize"
                        highlighted: true
                        enabled: root.editSsid.trim().length > 0 && root.editPassword.length >= 8
                        onClicked: root.saveCredentials()
                    }
                }
            }
        }

        // ============================================================
        // Footer: KDE System Sync Badge
        // ============================================================
        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            opacity: 0.75

            Kirigami.Icon {
                implicitWidth: 14
                implicitHeight: 14
                source: "emblem-ok-symbolic"
                fallback: Qt.resolvedUrl("../../icons/emblem-ok-symbolic.svg")
                isMask: true
                color: root.isDarkTheme ? "#9aa0a6" : "#606770"
            }

            Text {
                text: "Global Settings: ~/.config/plasma-nm"
                font.pixelSize: 10
                color: root.isDarkTheme ? "#9aa0a6" : "#606770"
                Layout.fillWidth: true
            }
        }
    }

    Component.onCompleted: root.refreshClicked()
}
