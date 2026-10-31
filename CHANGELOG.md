# Changelog

All notable changes to the **GNOME Quick Settings** applet for KDE Plasma 6 are documented in this file.

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
- **Panel Status Capsule**:
  - Optimized indicator visibility checks and contrast in the panel capsule pill.

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
