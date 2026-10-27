#!/usr/bin/env bash
# audio.sh - Helper script for Audio volume & mute management in KDE GNOME Quick Settings
set -euo pipefail

CMD="${1:-status}"

get_audio_status() {
    local volume=50
    local muted="false"

    if command -v wpctl >/dev/null 2>&1; then
        local out
        out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
        if [[ -n "$out" ]]; then
            # Format: Volume: 0.65 [MUTED]
            local vol_float
            vol_float=$(echo "$out" | grep -o -E '[0-9]+\.[0-9]+' || echo "0.50")
            volume=$(awk -v v="$vol_float" 'BEGIN { printf "%.0f", v * 100 }')
            if echo "$out" | grep -qi "MUTED"; then
                muted="true"
            fi
        fi
    elif command -v pactl >/dev/null 2>&1; then
        local sink_info
        sink_info=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null || true)
        if [[ -n "$sink_info" ]]; then
            volume=$(echo "$sink_info" | grep -o -E '[0-9]+%' | head -n 1 | tr -d '%' || echo "50")
        fi
        local mute_info
        mute_info=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null || true)
        if echo "$mute_info" | grep -qi "yes"; then
            muted="true"
        fi
    elif command -v amixer >/dev/null 2>&1; then
        local sget_out
        sget_out=$(amixer sget Master 2>/dev/null || true)
        if [[ -n "$sget_out" ]]; then
            volume=$(echo "$sget_out" | grep -o -E '\[[0-9]+%\]' | head -n 1 | tr -d '[]%' || echo "50")
            if echo "$sget_out" | grep -qi '\[off\]'; then
                muted="true"
            fi
        fi
    fi

    cat <<EOF
{
  "volume": $volume,
  "muted": $muted
}
EOF
}

set_volume() {
    local val="${2:-50}"
    # Clamp between 0 and 100
    if (( val < 0 )); then val=0; fi
    if (( val > 100 )); then val=100; fi

    if command -v wpctl >/dev/null 2>&1; then
        local float_val
        float_val=$(awk -v v="$val" 'BEGIN { printf "%.2f", v / 100 }')
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "$float_val" >/dev/null 2>&1 || true
    elif command -v pactl >/dev/null 2>&1; then
        pactl set-sink-volume @DEFAULT_SINK@ "${val}%" >/dev/null 2>&1 || true
    elif command -v amixer >/dev/null 2>&1; then
        amixer sset Master "${val}%" >/dev/null 2>&1 || true
    fi
    get_audio_status
}

toggle_mute() {
    if command -v wpctl >/dev/null 2>&1; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle >/dev/null 2>&1 || true
    elif command -v pactl >/dev/null 2>&1; then
        pactl set-sink-mute @DEFAULT_SINK@ toggle >/dev/null 2>&1 || true
    elif command -v amixer >/dev/null 2>&1; then
        amixer sset Master toggle >/dev/null 2>&1 || true
    fi
    get_audio_status
}

case "$CMD" in
    status)
        get_audio_status
        ;;
    set_volume)
        set_volume "$@"
        ;;
    toggle_mute)
        toggle_mute
        ;;
    *)
        echo "Usage: $0 {status|set_volume <0-100>|toggle_mute}"
        exit 1
        ;;
esac
