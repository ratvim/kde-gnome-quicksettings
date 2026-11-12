import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as Plasma5Support

KCM.SimpleKCM {
    id: root

    // Shell clipboard helper for Wayland / X11
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
        }
    }

    function copyToClipboard(url) {
        linkField.selectAll()
        linkField.copy()
        execSource.connectSource("bash -c 'echo -n \"" + url + "\" | (wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null || true)'")
        copiedTimer.restart()
    }

    Timer {
        id: copiedTimer
        interval: 2500
        repeat: false
    }

    Kirigami.FormLayout {
        id: formLayout

        // --- 1. About & Developer Info ---
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("About the Project")
            Kirigami.FormData.isSection: true
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: infoCol.implicitHeight + 24
            radius: 8
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
            border.width: 1

            ColumnLayout {
                id: infoCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    spacing: 12
                    Layout.fillWidth: true

                    Kirigami.Icon {
                        source: "help-donate"
                        implicitWidth: 36
                        implicitHeight: 36
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: i18n("GNOME Quick Settings for KDE Plasma 6")
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }

                        Label {
                            text: i18n("Developed with ❤️ by Vimlesh Raturi")
                            font.pixelSize: 11
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: i18n("Thank you for using GNOME Quick Settings! This project is free, open source, and actively maintained. If you enjoy this widget and want to support ongoing development, maintenance, and new features, your contribution is greatly appreciated.")
                    wrapMode: Text.WordWrap
                    font.pixelSize: 11
                }
            }
        }

        // --- 2. PayPal Donation Section ---
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Support & Donations")
            Kirigami.FormData.isSection: true
        }

        Button {
            Kirigami.FormData.label: i18n("PayPal:")
            text: i18n("Donate via PayPal")
            icon.name: "help-donate"
            onClicked: Qt.openUrlExternally("https://paypal.me/VimleshRaturi")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Donation Link:")
            spacing: 6
            Layout.fillWidth: true

            TextField {
                id: linkField
                text: "https://paypal.me/VimleshRaturi"
                readOnly: true
                selectByMouse: true
                Layout.fillWidth: true
                font.family: "monospace"
            }

            Button {
                text: copiedTimer.running ? i18n("Copied!") : i18n("Copy Link")
                icon.name: copiedTimer.running ? "emblem-ok-symbolic" : "edit-copy"
                onClicked: root.copyToClipboard("https://paypal.me/VimleshRaturi")
            }
        }

        Label {
            text: i18n("Clickable link: <a href=\"https://paypal.me/VimleshRaturi\">https://paypal.me/VimleshRaturi</a>")
            textFormat: Text.RichText
            wrapMode: Text.WordWrap
            onLinkActivated: function(link) { Qt.openUrlExternally(link) }
        }

        // --- 3. Community & Feedback ---
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Feedback & Community")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("KDE Store:")
            spacing: 6

            Button {
                text: i18n("Rate & Review on KDE Store")
                icon.name: "get-hot-new-stuff"
                onClicked: Qt.openUrlExternally("https://store.kde.org/p/2380429")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Developer Email:")
            spacing: 6

            Button {
                text: i18n("Send Feedback (vimleshraturi@gmail.com)")
                icon.name: "mail-message-new"
                onClicked: Qt.openUrlExternally("mailto:vimleshraturi@gmail.com")
            }
        }
    }
}
