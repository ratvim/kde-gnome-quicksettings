#!/usr/bin/env bash
# brightness.sh - Helper script for Display Brightness control in KDE GNOME Quick Settings (Plasma 6)
set -euo pipefail

CMD="${1:-status}"

get_qdbus() {
    if command -v qdbus6 >/dev/null 2>&1; then
        echo "qdbus6"
    elif command -v qdbus >/dev/null 2>&1; then
        echo "qdbus"
    fi
}

get_brightness() {
    local b=100
    local qcmd
    qcmd=$(get_qdbus)

    if [[ -n "$qcmd" ]]; then
        local cur max
        cur=$($qcmd org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightness 2>/dev/null || echo "100")
        max=$($qcmd org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightnessMax 2>/dev/null || echo "100")
        if [[ "$max" -gt 0 ]]; then
            b=$(( cur * 100 / max ))
        fi
    elif command -v brightnessctl >/dev/null 2>&1; then
        local cur max
        cur=$(brightnessctl get 2>/dev/null || echo "100")
        max=$(brightnessctl max 2>/dev/null || echo "100")
        if [[ "$max" -gt 0 ]]; then
            b=$(( cur * 100 / max ))
        fi
    elif command -v xbacklight >/dev/null 2>&1; then
        local cur_f
        cur_f=$(xbacklight -get 2>/dev/null || echo "100")
        b=$(printf "%.0f" "$cur_f")
    fi

    cat <<EOF
{
  "brightness": $b
}
EOF
}

set_brightness() {
    local val="${2:-100}"
    if (( val < 1 )); then val=1; fi
    if (( val > 100 )); then val=100; fi

    local qcmd
    qcmd=$(get_qdbus)

    if [[ -n "$qcmd" ]]; then
        local max
        max=$($qcmd org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightnessMax 2>/dev/null || echo "100")
        local target=$(( val * max / 100 ))
        $qcmd org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.setBrightness "$target" >/dev/null 2>&1 || true
    elif command -v brightnessctl >/dev/null 2>&1; then
        brightnessctl set "${val}%" >/dev/null 2>&1 || true
    elif command -v xbacklight >/dev/null 2>&1; then
        xbacklight -set "$val" >/dev/null 2>&1 || true
    fi
    get_brightness
}

case "$CMD" in
    status|get)
        get_brightness
        ;;
    set)
        set_brightness "$@"
        ;;
    *)
        echo "Usage: $0 {status|get|set <0-100>}"
        exit 1
        ;;
esac
