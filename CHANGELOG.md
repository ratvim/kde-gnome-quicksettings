# Changelog

All notable changes to the **GNOME Quick Settings** applet for KDE Plasma 6 are documented in this file.

## [1.1.2] - 2026-11-09

### Added & Improved
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
