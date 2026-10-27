#!/usr/bin/env bash
# ==============================================================================
# Packager for GNOME Quick Settings Applet for KDE Plasma 6
# Produces: org.kde.plasma.gnomequicksettings.plasmoid
# ==============================================================================

set -e

APPLET_ID="org.kde.plasma.gnomequicksettings"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/${APPLET_ID}.plasmoid"

echo "==> Packaging ${APPLET_ID} into ${OUTPUT_FILE}..."

# Build C++ QML helper plugin if source is present
if [ -f "${SCRIPT_DIR}/plugin/plugin.cpp" ]; then
    echo "==> Building C++ QML plugin..."
    mkdir -p "${SCRIPT_DIR}/contents/ui/plugin"
    /usr/lib/qt6/moc "${SCRIPT_DIR}/plugin/plugin.cpp" -o "${SCRIPT_DIR}/plugin/plugin.moc" 2>/dev/null || moc "${SCRIPT_DIR}/plugin/plugin.cpp" -o "${SCRIPT_DIR}/plugin/plugin.moc"
    g++ -shared -fPIC -I/usr/include/qt6 -I/usr/include/qt6/QtCore -I/usr/include/qt6/QtGui -I/usr/include/qt6/QtQml -I/usr/include/qt6/QtQuick -I/usr/include/KF6/KWindowSystem -I/usr/include/KF6 \
        -lQt6Core -lQt6Gui -lQt6Qml -lQt6Quick -lKF6WindowSystem \
        "${SCRIPT_DIR}/plugin/plugin.cpp" -o "${SCRIPT_DIR}/contents/ui/plugin/libgnomequicksettingsplugin.so"
    echo "module GnomeQuickSettingsPlugin" > "${SCRIPT_DIR}/contents/ui/plugin/qmldir"
    echo "plugin gnomequicksettingsplugin" >> "${SCRIPT_DIR}/contents/ui/plugin/qmldir"
fi

# Ensure backend scripts are executable
chmod +x "${SCRIPT_DIR}/contents/scripts/"*.sh 2>/dev/null || true

# Remove old bundle if exists
rm -f "${OUTPUT_FILE}"

cd "${SCRIPT_DIR}"

# Create zip bundle matching KDE Plasma 6 Plasmoid specification
zip -r "${OUTPUT_FILE}" \
    metadata.json \
    contents/ \
    -x "*.git*" "*.DS_Store*" "*__pycache__*" "*.swp" "metadata.desktop"

echo "✅ Package created successfully: ${OUTPUT_FILE} ($(du -h "${OUTPUT_FILE}" | cut -f1))"
