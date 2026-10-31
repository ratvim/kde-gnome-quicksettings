# 🎛️ GNOME Quick Settings for KDE Plasma 6

[![KDE Plasma](https://img.shields.io/badge/KDE%20Plasma-6.0%2B-blue.svg)](https://kde.org/plasma-desktop/)
[![Qt](https://img.shields.io/badge/Qt-6-41CD52.svg)](https://www.qt.io/)
[![Platform](https://img.shields.io/badge/Display%20Server-Wayland%20%7C%20X11-orange.svg)]()
[![Release](https://img.shields.io/badge/Release-v1.1.1-success.svg)]()
[![License](https://img.shields.io/badge/License-GPL--3.0-lightgrey.svg)](LICENSE)

A modern, pixel-perfect GNOME 43+ style **Quick Settings Control Center** applet built natively for **KDE Plasma 6**. Featuring glassmorphic 24px curved cards, uniform capsule pill toggles, smooth rounded sliders, expandable sub-drawers, user profile header, and dedicated C++ compositor effect management for zero background blur bleed.

---

## 🚀 What's New in v1.1.1

- ᛒ **Direct Native Bluetooth Device Pairing**:
  - Replaced in-drawer scanning with a streamlined **"Pair New Device"** action in the Bluetooth sub-drawer.
  - Directly invokes KDE Plasma's native Bluetooth pairing wizard, ensuring proper PIN code confirmation, two-way mobile device pairing verification, and persistent connection stability.
- 🧹 **Removed LocalSend Integration**:
  - Removed LocalSend tile toggle and panel status capsule indicator to focus Quick Settings strictly on native desktop and hardware controls.
  - Cleaned up configuration XML, general settings, and appearance reordering lists.
- ⚙️ **Standardized Default 12-Toggle Layout**:
  - Cleaned up default toggle ordering for a balanced 2-column grid: Wi-Fi, Bluetooth, Location, Microphone, Camera, KDE Connect, Dark Style, Night Light, Airplane Mode, Do Not Disturb, Hotspot, and Power Profiles.
- 💎 **Panel Capsule Indicator Refinements**:
  - Optimized indicator visibility checks and contrast in the panel capsule pill.

---

## ✨ Features

- **Glassmorphic Curved Card (`radius: 24px`)**:
  - Unified aesthetic inspired by GNOME 43/44/45/46 Quick Settings.
  - Native C++ `WindowHelper` plugin communicates directly with `KWindowEffects` and `QWindow` to eliminate rectangular compositor blur artifacts on both Wayland and X11.
  - Dynamically calculates height and margins to adapt precisely to the number of visible toggles.
- **User Profile Header**:
  - Displays user avatar, real name, and system role (`Administrator` / `Standard`).
  - Quick action buttons: System Settings, Lock Screen, and Power / Session menu.
  - Live battery percentage badge with dynamic charging indicator.
- **Dual Curved Sliders (`radius: 22px`)**:
  - **Audio Volume**: Continuous pill track with mute toggle icon and percentage readout (supports PipeWire WirePlumber, PulseAudio, and ALSA).
  - **Display Brightness**: Smooth rounded slider with dynamic brightness icon (via `brightnessctl` or DBus).
- **2-Column Pill Toggles**:
  - 📶 **Wi-Fi**: Status, active SSID name, and expandable network drawer.
  - ᛒ **Bluetooth**: Power toggle, connected device status, and expandable pairing drawer.
  - 📍 **Location**: Privacy toggle for location services.
  - 📷 **Camera**: Multi-layer privacy kill-switch with expandable `>` sub-drawer displaying active webcam applications, live status indicators, and process termination controls.
  - 🎙️ **Microphone**: Quick mute / un-mute toggle.
  - 📱 **KDE Connect**: Paired phone status with quick ping, ring, SMS, file browse, and photo share actions.
  - 🌙 **Dark Style**: Instant desktop theme switcher between Light and Dark mode.
  - 🌅 **Night Light**: Blue light filter toggle.
  - ✈️ **Airplane Mode**: Wireless radio kill-switch.
  - 🔕 **Do Not Disturb**: Notification suppression with preset duration timers.
  - 📡 **Hotspot**: Quick hotspot toggle.
  - ⚡ **Power Profile**: Performance, Balanced, and Power Saver switcher.
- **Expandable Sub-Drawers**:
  - Detailed sub-menus for Wi-Fi networks, Bluetooth devices, Camera active applications, KDE Connect actions, Power profiles, and Do Not Disturb durations with smooth transitions and consistent typography.
- **Panel Status Capsule**:
  - Compact representation on the KDE panel showing Wi-Fi, Bluetooth, Audio Volume, Battery percentage, and charging capsule.

---

## 📋 Prerequisites & Dependencies

To build and run this applet, your system must have the following dependencies installed.

### 1. Build-Time Dependencies
Required to compile the bundled C++ QML helper plugin (`libgnomequicksettingsplugin.so`) and package the plasmoid:

| Dependency | Purpose |
| :--- | :--- |
| **`g++`** (or `clang++`) | C++ compiler with C++17 support |
| **`qt6-base-dev`** / **`qt6-base-devel`** | Qt 6 core development headers & libraries |
| **`qt6-declarative-dev`** / **`qt6-declarative-devel`** | Qt 6 QML / Quick headers and `moc` meta-object compiler |
| **`libkf6windowsystem-dev`** / **`kf6-kwindowsystem-devel`** | KDE Frameworks 6 `KWindowEffects` for compositor control |
| **`kpackagetool6`** (optional, recommended) | Registers and updates the Plasmoid in Plasma 6 |
| **`zip`** | Generates the distributable `.plasmoid` archive |

### 2. Runtime Dependencies
Required by system scripts in `contents/scripts/` to query status and toggle system hardware:

| Tool | Package | Required For |
| :--- | :--- | :--- |
| **`nmcli`** | `network-manager` / `networkmanager` | Wi-Fi scanning, connection, and status |
| **`bluetoothctl`** | `bluez` / `bluez-utils` | Bluetooth adapter power and device management |
| **`wpctl`** or **`pactl`** | `wireplumber` or `pulseaudio-utils` | Audio volume and mute control |
| **`brightnessctl`** | `brightnessctl` | Display backlight brightness adjustment |
| **`upower`** | `upower` | Battery status and charging information |
| **`powerprofilesctl`** | `power-profiles-daemon` | Power profile switching (Performance/Balanced/Saver) |
| **`kdeconnect-cli`** | `kdeconnect` | Phone integration (ring, SMS, ping, file browsing) |

---

## 📦 Package Installation by Distribution

Run the single command below for your Linux distribution to install all build and runtime dependencies:

### 🔹 Arch Linux / Manjaro / EndeavourOS
```bash
sudo pacman -S --needed \
    base-devel gcc zip \
    qt6-base qt6-declarative \
    kf6-kwindowsystem kpackage \
    networkmanager bluez-utils brightnessctl \
    wireplumber upower power-profiles-daemon kdeconnect
```

### 🔹 Fedora 40+ / RHEL 10
```bash
sudo dnf install -y \
    gcc-c++ zip \
    qt6-qtbase-devel qt6-qtdeclarative-devel \
    kf6-kwindowsystem-devel kf6-kpackage \
    NetworkManager bluez brightnessctl \
    wireplumber upower power-profiles-daemon kde-connect
```

### 🔹 Ubuntu 24.04 LTS+ / Kubuntu / Debian 13+
```bash
sudo apt update && sudo apt install -y \
    build-essential g++ zip \
    qt6-base-dev qt6-declarative-dev \
    libkf6windowsystem-dev kpackagetool6 \
    network-manager bluez brightnessctl \
    wireplumber upower power-profiles-daemon kdeconnect
```

### 🔹 openSUSE Tumbleweed / Leap 16+
```bash
sudo zypper install -y \
    gcc-c++ zip \
    qt6-base-devel qt6-declarative-devel \
    kf6-kwindowsystem-devel kf6-kpackage-devel \
    NetworkManager bluez-util brightnessctl \
    wireplumber upower power-profiles-daemon kdeconnect-kde
```

---

## 🚀 Installation & Setup

### 1. Clone & Install
Clone the repository (or extract the source directory) and run the automated installer:
```bash
cd kde_gnome_tray
chmod +x install.sh
./install.sh
```

The installer will:
1. Validate all required build tools (`g++`, `moc`, `zip`).
2. Warn if any optional runtime tools (`nmcli`, `bluetoothctl`, `brightnessctl`, audio) are missing.
3. Automatically compile the C++ `libgnomequicksettingsplugin.so` plugin.
4. Package `org.kde.plasma.gnomequicksettings.plasmoid`.
5. Install the plasmoid into `~/.local/share/plasma/plasmoids/org.kde.plasma.gnomequicksettings`.
6. Register the applet with `kpackagetool6`.

### 2. Add to Your KDE Panel
1. Right-click on your KDE panel (or desktop) and select **"Add Widgets..."**.
2. Type **"GNOME Quick Settings"** into the search bar.
3. Drag and drop the widget onto your panel (recommended: in the system tray area or beside the clock).
4. Click the panel capsule icon to toggle open your GNOME Quick Settings!

### 3. Reloading Plasma (If updating an existing installation)
If you updated from a previous version while Plasma was running, reload `plasmashell`:
```bash
systemctl --user restart plasma-plasmashell
```

---

## ⌨️ Global Keyboard Shortcut

You can bind a global keyboard shortcut to toggle the Quick Settings popup (e.g. `Meta + A` or `Ctrl + Alt + Q`):
1. Open **System Settings** → **Keyboard** → **Shortcuts**.
2. Select **Plasma** → find **GNOME Quick Settings**.
3. Set your preferred shortcut key combination and click **Apply**.

---

## ⚙️ Configuration & Customization

Right-click the panel icon and choose **"Configure GNOME Quick Settings..."**:
- **Panel Visibility**: Choose whether to show/hide the battery indicator, volume pill, Wi-Fi icon, or Bluetooth indicator on the panel.
- **Toggle Visibility**: Enable or disable specific pill toggles in the popup control center.
- **Icon Sizing**: Configure panel and popup tile icon sizes to match your desktop scaling.

---

## 📂 Project Structure

```
kde_gnome_tray/
├── metadata.json                          # Plasma 6 applet metadata (version 1.1.1)
├── install.sh                             # Automated installer with dependency preflight
├── package.sh                             # Builds C++ plugin & packages .plasmoid
├── org.kde.plasma.gnomequicksettings.plasmoid # Distributable Plasma 6 package
├── README.md                              # Complete documentation & dependency guide
├── plugin/                                # C++ QML Extension Plugin
│   └── plugin.cpp                         # WindowHelper implementation (KWindowEffects blur control)
├── contents/
│   ├── config/                            # Applet configuration XML & UI
│   ├── icons/                             # GNOME Symbolic SVG icons
│   ├── scripts/                           # Native system control scripts
│   │   ├── network.sh                     # nmcli Wi-Fi control & scanning
│   │   ├── bluetooth.sh                   # bluetoothctl power & pairing
│   │   ├── audio.sh                       # wpctl / pactl / amixer volume & mute
│   │   ├── brightness.sh                  # brightnessctl & DBus display brightness
│   │   ├── power.sh                       # Battery, power profiles, and session actions
│   │   └── devices.sh                     # Location, Camera, Mic, and KDE Connect
│   └── ui/
│       ├── main.qml                       # Root Plasmoid item
│       ├── CompactRepresentation.qml      # Panel status indicator capsule
│       ├── FullRepresentation.qml         # Popup Quick Settings card
│       ├── components/
│       │   ├── PillToggle.qml             # Rounded capsule toggle button
│       │   ├── CurvedSlider.qml           # Rounded volume & brightness slider
│       │   └── MediaCard.qml              # MPRIS media player card
│       ├── views/
│       │   ├── NetworkView.qml            # Wi-Fi network scanner drawer
│       │   ├── BluetoothView.qml          # Bluetooth device drawer
│       │   ├── KdeConnectView.qml         # KDE Connect device drawer
│       │   ├── PowerView.qml              # Power profiles & battery drawer
│       │   ├── DndView.qml                # Do Not Disturb duration drawer
│       │   └── WidgetSettingsView.qml     # In-popup tile configuration drawer
│       └── plugin/                        # Compiled C++ plugin output
│           ├── libgnomequicksettingsplugin.so
│           └── qmldir
```

---

## ❓ Troubleshooting

### 1. "Cannot load library ... undefined symbol"
Ensure that `install.sh` built the plugin using `package.sh` on your current Qt6/KF6 installation. Running `./install.sh` recompiles the C++ plugin against your installed libraries.

### 2. Backlight Brightness slider does not adjust brightness
Ensure your user account has permission to adjust display backlight via `brightnessctl`:
```bash
sudo usermod -aG video $USER
```
Log out and log back in for group membership to take effect.

### 3. Audio volume does not adjust
Check if your system uses PipeWire (`wpctl`) or PulseAudio (`pactl`):
```bash
which wpctl pactl
```
Installing either `wireplumber` (for PipeWire) or `pulseaudio-utils` (for PulseAudio) resolves this immediately.

### 4. Background blur or rectangular corner artifacts
The bundled `WindowHelper` C++ extension automatically instructs KWin to disable rectangular window blur behind the popup. Ensure that `contents/ui/plugin/libgnomequicksettingsplugin.so` is present and that `kpackagetool6` upgraded the plasmoid.

---

## 📜 License

This project is licensed under the **GNU General Public License v3.0 or later** (GPL-3.0-or-later). See the LICENSE file for details.
