#!/usr/bin/env bash
# ==============================================================================
# Installer for GNOME Quick Settings Applet for KDE Plasma 6
# Package: org.kde.plasma.gnomequicksettings
# ==============================================================================

set -e

APPLET_ID="org.kde.plasma.gnomequicksettings"
INSTALL_DIR="${HOME}/.local/share/plasma/plasmoids/${APPLET_ID}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  GNOME Quick Settings for KDE Plasma 6 — Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Preflight check for build dependencies
echo "==> Checking required build dependencies..."
missing_build=()

command -v g++ >/dev/null 2>&1 || missing_build+=("g++ (C++ compiler)")
command -v zip >/dev/null 2>&1 || missing_build+=("zip")
if ! command -v moc >/dev/null 2>&1 && [ ! -x /usr/lib/qt6/moc ]; then
    missing_build+=("qt6 moc (qt6-base-dev / qt6-base-devel)")
fi

if [ ${#missing_build[@]} -gt 0 ]; then
    echo "❌ Missing required build dependencies:"
    for dep in "${missing_build[@]}"; do
        echo "   • ${dep}"
    done
    echo ""
    echo "Please install the build dependencies before running install.sh."
    echo "Refer to README.md for distribution-specific package install commands."
    exit 1
fi

# 2. Check optional runtime tools and inform user
missing_runtime=()
command -v nmcli >/dev/null 2>&1 || missing_runtime+=("nmcli (for Wi-Fi management)")
command -v bluetoothctl >/dev/null 2>&1 || missing_runtime+=("bluetoothctl (for Bluetooth)")
command -v brightnessctl >/dev/null 2>&1 || missing_runtime+=("brightnessctl (for display brightness)")
if ! command -v wpctl >/dev/null 2>&1 && ! command -v pactl >/dev/null 2>&1; then
    missing_runtime+=("wpctl or pactl (for audio volume control)")
fi

if [ ${#missing_runtime[@]} -gt 0 ]; then
    echo "ℹ️  Note: Some optional runtime tools were not detected:"
    for rdep in "${missing_runtime[@]}"; do
        echo "   • ${rdep}"
    done
    echo "   (Associated toggles will activate once these packages are installed)"
fi

# 3. Make scripts executable and build package
echo "==> Ensuring backend scripts are executable..."
chmod +x "${SCRIPT_DIR}/contents/scripts/"*.sh 2>/dev/null || true
"${SCRIPT_DIR}/package.sh"

# 4. Check installation directory
echo "==> Target directory: ${INSTALL_DIR}"
mkdir -p "$(dirname "${INSTALL_DIR}")"

# 5. Clean any existing / legacy installation to clear cache
echo "==> Removing any previous installation..."
rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

# 6. Copy Plasma 6 applet files
echo "==> Copying Plasma 6 applet files to ${INSTALL_DIR}..."
cp -r "${SCRIPT_DIR}/metadata.json" "${INSTALL_DIR}/"
cp -r "${SCRIPT_DIR}/contents" "${INSTALL_DIR}/"
chmod +x "${INSTALL_DIR}/contents/scripts/"*.sh 2>/dev/null || true

# 7. Register with kpackagetool6 if available
if command -v kpackagetool6 >/dev/null 2>&1; then
    echo "==> Registering with kpackagetool6 (KDE Plasma 6)..."
    PACKAGE_FILE="${SCRIPT_DIR}/${APPLET_ID}.plasmoid"
    if [ -f "${PACKAGE_FILE}" ]; then
        kpackagetool6 -t Plasma/Applet --upgrade "${PACKAGE_FILE}" 2>/dev/null || \
        kpackagetool6 -t Plasma/Applet --install "${PACKAGE_FILE}" 2>/dev/null || true
    fi
fi

# 8. Refresh Plasma shell cache if running
if command -v qdbus6 >/dev/null 2>&1; then
    echo "==> Refreshing Plasma shell cache via qdbus6..."
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.refreshCurrentShell 2>/dev/null || true
fi

echo ""
echo "✅ Installation to KDE Plasma 6 successful!"
echo ""
echo "To use GNOME Quick Settings on your KDE Plasma 6 panel:"
echo "  1. Right-click your KDE panel (or desktop) and select 'Add Widgets...'"
echo "  2. Search for 'GNOME Quick Settings'"
echo "  3. Drag it onto your panel"
echo ""
echo "If your panel was already open, reload Plasma with:"
echo "  systemctl --user restart plasma-plasmashell"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
