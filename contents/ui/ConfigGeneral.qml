import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    // Panel properties
    property alias cfg_showBattery: showBatteryCheck.checked
    property alias cfg_showBatteryPercent: showBatteryPercentCheck.checked
    property alias cfg_showVolume: showVolumeCheck.checked
    property alias cfg_panelIconSize: panelIconSizeSpin.value
    property alias cfg_tileIconSize: tileIconSizeSpin.value

    // Panel status capsule toggle icon properties (shown when active)
    property alias cfg_panelShowWifi: panelWifiCheck.checked
    property alias cfg_panelShowBluetooth: panelBtCheck.checked
    property alias cfg_panelShowNightLight: panelNightCheck.checked
    property alias cfg_panelShowAirplane: panelAirCheck.checked
    property alias cfg_panelShowDnd: panelDndCheck.checked
    property alias cfg_panelShowHotspot: panelHotspotCheck.checked
    property alias cfg_panelShowDarkTheme: panelDarkCheck.checked
    property alias cfg_panelShowPowerProfile: panelPowerCheck.checked
    property alias cfg_panelShowLocation: panelLocationCheck.checked
    property alias cfg_panelShowCamera: panelCameraCheck.checked
    property alias cfg_panelShowMic: panelMicCheck.checked
    property alias cfg_panelShowKdeConnect: panelKdeCheck.checked

    // Tile visibility properties (inside dropdown)
    property alias cfg_tileShowWifi: tileWifiCheck.checked
    property alias cfg_tileShowBluetooth: tileBtCheck.checked
    property alias cfg_tileShowNightLight: tileNightCheck.checked
    property alias cfg_tileShowAirplane: tileAirCheck.checked
    property alias cfg_tileShowDnd: tileDndCheck.checked
    property alias cfg_tileShowHotspot: tileHotspotCheck.checked
    property alias cfg_tileShowDarkTheme: tileDarkCheck.checked
    property alias cfg_tileShowPowerSaver: tilePowerCheck.checked
    property alias cfg_tileShowLocation: tileLocationCheck.checked
    property alias cfg_tileShowCamera: tileCameraCheck.checked
    property alias cfg_tileShowMic: tileMicCheck.checked
    property alias cfg_tileShowKdeConnect: tileKdeCheck.checked

    Kirigami.FormLayout {
        // --- 1. Panel Status Capsule Section ---
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Panel Status Capsule")
            Kirigami.FormData.isSection: true
        }

        SpinBox {
            id: panelIconSizeSpin
            Kirigami.FormData.label: i18n("Panel Icon Size (px):")
            from: 10
            to: 32
            stepSize: 1
        }

        CheckBox {
            id: showBatteryCheck
            text: i18n("Show Battery indicator")
        }

        CheckBox {
            id: showBatteryPercentCheck
            text: i18n("Show Battery percentage on panel (e.g. 85%)")
        }

        CheckBox {
            id: showVolumeCheck
            text: i18n("Show Volume indicator")
        }

        // --- 2. Panel Capsule Toggle Icons Section ---
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Panel Capsule Toggle Icons")
            Kirigami.FormData.isSection: true
        }

        Label {
            text: i18n("Display icon in panel capsule when toggle is enabled / active:")
            font.weight: Font.DemiBold
        }

        GridLayout {
            columns: 2
            columnSpacing: 24
            rowSpacing: 4
            Layout.fillWidth: true

            CheckBox {
                id: panelWifiCheck
                text: i18n("Wi-Fi (when on / connected)")
            }

            CheckBox {
                id: panelBtCheck
                text: i18n("Bluetooth (when on / connected)")
            }

            CheckBox {
                id: panelPowerCheck
                text: i18n("Power Mode (Performance / Optimise)")
            }

            CheckBox {
                id: panelNightCheck
                text: i18n("Night Light (when on)")
            }

            CheckBox {
                id: panelAirCheck
                text: i18n("Airplane Mode (when on)")
            }

            CheckBox {
                id: panelDndCheck
                text: i18n("Do Not Disturb (when on)")
            }

            CheckBox {
                id: panelHotspotCheck
                text: i18n("Mobile Hotspot (when on)")
            }

            CheckBox {
                id: panelDarkCheck
                text: i18n("Dark Theme (when on)")
            }

            CheckBox {
                id: panelLocationCheck
                text: i18n("Location Services (when on)")
            }

            CheckBox {
                id: panelCameraCheck
                text: i18n("Camera (when in use or blocked)")
            }

            CheckBox {
                id: panelMicCheck
                text: i18n("Microphone (when in use or muted)")
            }

            CheckBox {
                id: panelKdeCheck
                text: i18n("KDE Connect (when connected)")
            }
        }

        // --- 3. Quick Settings Tiles Section ---
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Quick Settings Dropdown Tiles")
            Kirigami.FormData.isSection: true
        }

        SpinBox {
            id: tileIconSizeSpin
            Kirigami.FormData.label: i18n("Tile Icon Size (px):")
            from: 14
            to: 36
            stepSize: 1
        }

        Label {
            text: i18n("Select which toggles are visible in Quick Settings:")
            font.weight: Font.DemiBold
        }

        GridLayout {
            columns: 2
            columnSpacing: 24
            rowSpacing: 4
            Layout.fillWidth: true

            CheckBox {
                id: tileWifiCheck
                text: i18n("Wi-Fi")
            }

            CheckBox {
                id: tileBtCheck
                text: i18n("Bluetooth")
            }

            CheckBox {
                id: tileNightCheck
                text: i18n("Night Light")
            }

            CheckBox {
                id: tileAirCheck
                text: i18n("Airplane Mode")
            }

            CheckBox {
                id: tileDndCheck
                text: i18n("Do Not Disturb")
            }

            CheckBox {
                id: tileHotspotCheck
                text: i18n("Mobile Hotspot")
            }

            CheckBox {
                id: tileDarkCheck
                text: i18n("Dark Theme")
            }

            CheckBox {
                id: tilePowerCheck
                text: i18n("Power Mode (Performance / Balance / Optimise)")
            }

            CheckBox {
                id: tileLocationCheck
                text: i18n("Location Services")
            }

            CheckBox {
                id: tileCameraCheck
                text: i18n("Camera Privacy")
            }

            CheckBox {
                id: tileMicCheck
                text: i18n("Microphone Mute")
            }

            CheckBox {
                id: tileKdeCheck
                text: i18n("KDE Connect")
            }
        }
    }
}
