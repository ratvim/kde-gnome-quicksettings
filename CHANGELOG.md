# Changelog

All notable changes to the **GNOME Quick Settings** applet for KDE Plasma 6 are documented in this file.

## [1.1.9] - 2026-11-13

### Added & Improved
- **Dedicated Volume & Audio Stream Mixer Sub-View (`VolumeView.qml`)**:
  - Redesigned volume details to open as a dedicated full sub-view via a chevron `>` button (`go-next-symbolic`) placed directly beside the volume slider, matching the navigation pattern of `NetworkView` and `BluetoothView`.
  - Replaces inline accordion expansion, keeping the main Quick Settings drawer compact without pushing brightness sliders, toggles, or media players downwards.
  - Features a standard sub-view header with a `<` back button (`go-previous-symbolic`) to return to the main toggles view, a refresh button, and a direct shortcut to open KDE System Settings Sound module (`kcm_pulseaudio`).
  - Scrollable view includes:
    - **Master Output**: Full curved volume slider with live percentage and instant mute toggle.
    - **Applications (Playback Streams)**: Individual per-app volume sliders and mute buttons for active audio streams (Firefox, Spotify, Chrome, VLC, Discord, etc.).
    - **Output Devices (Sinks)**: Device selection list with radio check to switch the default playback sink (Built-in Speakers, Headphones, HDMI Audio), plus per-device volume controls.
    - **Input Devices (Microphones)**: Recording input level sliders and microphone mute toggles.
    - **Footer**: One-click action to configure audio devices in KDE System Settings.

- **Capsule Indicator Mouse Hover Status Tooltips (`StatusToolTip.qml`)**:
  - Implemented floating real-time status popups when hovering the mouse cursor over capsule pill indicators on the KDE panel.
  - Provides instant glimpse of status without opening the full control center:
    - **Battery**: Percentage, power adapter connection state, charging indicator, and visual fill progress bar.
    - **Volume**: Current percentage, active audio output device name, mute state, and volume progress bar.
    - **Wi-Fi**: Connected SSID name, signal strength percentage, and signal quality bar.
    - **Bluetooth**: Connected device name and battery level.
    - **Privacy (Camera / Microphone / Location)**: Formatted list of application names currently accessing the camera, recording microphone audio, or querying geolocation.
    - **Night Light**: Color temperature status (active vs off).
    - **Do Not Disturb**: Active alert state and "until" time.
    - **Wi-Fi Hotspot**: Hotspot SSID and password.
    - **Power Profile**: Active performance, balanced, or power saver mode.
    - **KDE Connect**: Device name, battery level, and sync state.
  - Built as real native top-level windows using `PlasmaCore.Dialog.Tooltip` positioned cleanly outside panel boundaries.
  - **Dynamic Edge-Aware Placement**: Automatically repositions outside the panel based on containment orientation (below for top panels, above for bottom panels, and to the left/right for vertical side panels).
  - Suppressed conflicting Plasma default applet tooltips (`org.kde.desktop-CompactApplet` ToolTipArea) to eliminate popup collision.

- **"Support Me" Configuration Page & In-App Card (`ConfigSupport.qml`)**:
  - Added a dedicated "Support Me" category to the native Plasma Plasmoid configuration dialog with developer bio and donation links.
  - Integrated a one-click PayPal donation button (`https://paypal.me/VimleshRaturi`), selectable URL link, and one-click copy-to-clipboard action.
  - Added a matching "Support Development" card in `WidgetSettingsView.qml` with direct external link handling.

- **Adaptive Panel Background, Transparency & KWin Blur Synchronization**:
  - Expanded Quick Settings control center dynamically tracks and adopts the background color, transparency/opacity, and blur of whichever panel it is attached to.
  - Full native Plasma 6 panel modes (`Translucent`, `Adaptive`, `Opaque`) as well as third-party panel colorizers (e.g. `luisbocanegra.panel.colorizer` presets including `Transparent`).
  - Restricts KWin compositor blur behind window and background contrast strictly inside the 24px curved card mask with zero corner bleed or rectangular halos.

### Fixed & Refined
- **Full Dark & Light Theme Adaptation for Capsule & Tooltips**:
  - Decoupled tooltip window colors from panel colors, ensuring tooltip icons render in high-contrast dark charcoal (`#1a1a1a`) on light cards during light theme (BreezeLight), eliminating invisible white-on-white icons.
  - Panel status capsule (`CompactRepresentation.qml`) now dynamically follows `root.isDarkTheme`: capsule icons, battery text, and borders render in white (`#f6f8fa`) in dark theme and dark charcoal (`#1a1a1a`) in light theme.
  - Updated capsule Dark Style toggle icon to dynamically switch symbols: displays Moon (`weather-clear-night-symbolic`) in dark mode and Sun (`weather-clear-symbolic`) in light mode, remaining visible in both modes when enabled.
  - Fixed battery percentage text and empty fallback arrow color binding so they never invert to black on dark panels.
  - Added `property int kdeConnectBattery: -1` in `main.qml` to prevent undefined type-cast warnings in QML engine logs.

## [1.1.2] - 2026-11-09

### Added & Improved
- **Dynamic Installed Screenshot Utilities Detection**:
  - Filtered screenshot utility selection in both the Plasma native configuration dialog (`ConfigGeneral.qml`) and the in-app Quick Settings drawer (`WidgetSettingsView.qml`) to only display applications actually installed on the system (e.g. Spectacle, Flameshot, GNOME Screenshot, Ksnip, XFCE Screenshooter, Scrot, Grim/Slurp).
  - Automatically queries host binaries via `devices.sh check_screenshot_tools` on demand and dynamically updates the UI models, hiding uninstalled utilities from the user.

- **Resolution & DPI Responsive Scaling Engine**:
  - Implemented automatic, multi-factor responsive scaling for the expanded Quick Settings panel across all display resolutions, aspect ratios, and scaling factors without requiring manual configuration.
  - Dynamically computes `resolutionScale` combining normalized viewport resolution (1080p reference, clamped against 16:9 equivalent to prevent horizontal distortion on ultrawide monitors) with system `Kirigami.Units.gridUnit` DPI metrics, smoothly clamped between `0.85` (low-resolution displays) and `1.50` (4K UHD displays).
  - Automatically bounds popup width (`responsiveWidth`), corner radii, content margins, tile spacing, and slider heights:
    - **720p / 768p / 800p (Steam Deck, compact displays)**: Panel width scales down cleanly (~347px), preventing the widget from overwhelming small displays while keeping all controls readable.
    - **1080p (Standard Full HD)**: Native 390px panel width and standard 176px 2-column tiles.
    - **1440p / 2K / Ultrawide**: Scales smoothly to ~520px width, expanding tiles and typography proportionally.
    - **4K UHD (3840x2160)**: Scales to ~566px width with enlarged touch/click targets and proportional font sizes, eliminating the tiny popup issue on high-DPI displays.
  - **Dynamic Two-Column Tile Grid**:
    - `tileWidth()` evaluates available width in real time (`Math.floor((responsiveWidth - 2 * contentMargin - tileSpacing) / 2)`), ensuring tiles always fill the panel grid with zero gaps or awkward wrapping.
  - **Viewport Clamping & Safe Scrolling**:
    - Panel height is clamped against `maxScreenSafeHeight` (`screenHeight - 64`), paired with `ScrollView` (`ScrollBar.vertical.policy: ScrollBar.AsNeeded`) to guarantee popup contents never clip outside the physical desktop boundaries.

- **Concurrent Wi-Fi Client & Hotspot Coexistence Support**:
  - Removed artificial mutual exclusivity between Wi-Fi Station and Hotspot across `network.sh`, `main.qml`, `FullRepresentation.qml`, and `CompactRepresentation.qml`.
  - Added smart multi-interface detection (`get_wifi_devices()`, `get_hotspot_device()`). On multi-adapter systems or setups with virtual AP interfaces, Wi-Fi client and Hotspot operate concurrently without terminating each other.
  - Updated `CompactRepresentation.qml` to display both Wi-Fi and Hotspot icons simultaneously in the top bar capsule pill when both are active.
  - Updated `FullRepresentation.qml` so both the Wi-Fi tile and the Hotspot tile can remain active and display their independent connection details simultaneously.

- **Hotspot Configuration & KDE Global Settings Bidirectional Synchronization**:
  - Resolved credential desynchronization between KDE Global Settings (`kcm_mobile_hotspot` / `~/.config/plasma-nm`) and Quick Settings / NetworkManager.
  - Automatically queries and prioritizes authoritative Hotspot credentials (`HotspotName`, `HotspotPassword`) from `~/.config/plasma-nm` whenever status is polled or displayed, immediately keeping NetworkManager's profile aligned.
  - Added an inline credential editor to `HotspotView.qml` allowing users to configure both SSID and Password directly within Quick Settings whether the Hotspot is currently active or inactive.
  - Saving changes via `set_hotspot_credentials` atomically updates `~/.config/plasma-nm`, modifies the NetworkManager `Hotspot` connection, and dynamically reapplies settings if broadcasting is active.

### Fixed & Refined
- **Panel Status Capsule High-Contrast Theme Contrast & Icon Tinting Fix**:
  - Explicitly configured `Kirigami.Theme.colorSet: Kirigami.Theme.Complementary` on the panel status capsule pill.
  - Ensures panel indicators always render in crisp, high-contrast theme foreground (`#fcfcfc` / white) even when the system application color scheme is set to `BreezeLight`.
  - Prevents indicators from resolving to `#1a1a1a` (charcoal black on dark panels).
  - Resolved KDE Breeze dual-color SVG rendering (`camera-off-symbolic`, etc.) where hardcoded `#232629` was bypassing mask tinting, rendering as pitch black.
  - Inactive, muted, or blocked indicators now consistently render in soft light grey (`45%` alpha), remaining clearly visible under all desktop themes.
  - Bundled clean fallback SVGs (`contents/icons/camera-off-symbolic.svg`).

## [1.1.1] - 2026-10-29

### Added & Improved
- **Direct Native Bluetooth Device Pairing**:
  - Replaced in-drawer Bluetooth scanning with a direct **"Pair New Device"** action in the Bluetooth sub-drawer.
  - Directly invokes KDE Plasma's native Bluetooth pairing interface, ensuring proper PIN code exchange, two-way confirmation prompts on mobile devices, and reliable connection stability.
- **Standardized Default 12-Toggle Layout**:
  - Re-indexed and standardized the default quick settings layout to 12 essential system controls: Wi-Fi, Bluetooth, Location, Microphone, Camera, KDE Connect, Dark Style, Night Light, Airplane Mode, Do Not Disturb, Hotspot, and Power Profiles.

### Removed
- **LocalSend Integration**:
  - Removed LocalSend tile toggle and panel status capsule indicator to focus Quick Settings strictly on native desktop hardware and privacy controls.
  - Cleaned configuration settings, XML definitions, and appearance reordering lists.

### Fixed & Refined
- **Universal Multi-Distro Screenshot Capture**:
  - Fixed an issue where the screenshot button in the Quick Settings header was disabled due to empty DND JSON output and failed to trigger captures.
  - Implemented detached, non-blocking background process spawning (`nohup`) so screenshot commands reliably survive popup window closure.
  - Added universal application support and fallback chains across all Linux desktop environments (Spectacle on KDE, GNOME Screenshot, Flameshot, Ksnip, XFCE Screenshooter, Scrot, and Grim/Slurp).
  - Enhanced both Plasma configuration (`ConfigGeneral.qml`) and in-app settings (`WidgetSettingsView.qml`) to select any installed screenshot tool with automatic fallback.
- **Panel Status Capsule & Toggle Icon Masking (Eliminated Black Dot Glitch)**:
  - Enabled `isMask: true` on all Kirigami.Icon elements across the panel status capsule and Quick Settings toggles, ensuring icons strictly inherit theme colors instead of hardcoded SVG fill colors.
  - Styled inactive/unset settings with soft, light-greyed tones (`inactiveIndicatorColor` and `inactiveIconColor`) identical to Quick Settings toggles.
  - Added robust local bundled SVG fallbacks (`contents/icons/`) for all 12 system toggles and status indicators (including `contrast-symbolic.svg`, `location-services-active-symbolic.svg`, camera, mic, network, and battery) ensuring compatibility across all Linux distros and custom icon packs.
- **Volume Slider Click & Unmute Behavior**:
  - Fixed an issue where clicking on the volume slider track while muted would slide back to 0% and remain muted; clicking or dragging anywhere on the slider now immediately un-mutes the audio and sets the volume to that percentage.
  - Clicking the speaker icon on the extreme left continues to cleanly toggle mute/unmute and restore the previous volume level.

---

## [1.1.0] - 2026-10-20
- Dynamic multi-page pagination for quick settings tiles (configurable rows per page).
- Smooth SwipeView navigation with animated page dots.
- Camera and microphone active application detection and privacy controls.
- KDE Connect device status and quick action integration.

---

## [1.0.0] - Initial Release
- GNOME 43+ Quick Settings style floating card for KDE Plasma 6.
- 24px curved corners with C++ WindowHelper for zero blur bleed.
- Dual pill sliders for audio volume and display brightness.
- 2-column curved pill toggles with sub-drawers for Wi-Fi and Bluetooth.
