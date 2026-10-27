#!/usr/bin/env bash
# bluetooth.sh - Helper script for Bluetooth management in KDE GNOME Quick Settings
set -euo pipefail

CMD="${1:-status}"

get_bt_status() {
    local enabled="false"
    local connected="false"
    local dev_name=""
    local dev_mac=""
    local battery=0

    if command -v bluetoothctl >/dev/null 2>&1; then
        local show_out
        show_out=$(bluetoothctl show 2>/dev/null || true)
        if echo "$show_out" | grep -qi "Powered: yes"; then
            enabled="true"
        fi

        # Find connected devices
        local conn_lines
        conn_lines=$(bluetoothctl devices Connected 2>/dev/null || true)
        if [[ -z "$conn_lines" ]]; then
            conn_lines=$(bluetoothctl devices Paired 2>/dev/null || bluetoothctl paired-devices 2>/dev/null || true)
        fi

        while read -r _ mac name; do
            [[ -z "$mac" ]] && continue
            local dev_info
            dev_info=$(bluetoothctl info "$mac" 2>/dev/null || true)
            if echo "$dev_info" | grep -qi "Connected: yes"; then
                connected="true"
                dev_name="$name"
                dev_mac="$mac"

                local bat_line
                bat_line=$(echo "$dev_info" | grep -i "Battery Percentage" || true)
                if [[ "$bat_line" =~ \(([0-9]+)\) ]]; then
                    battery="${BASH_REMATCH[1]}"
                elif [[ "$bat_line" =~ Battery\ Percentage:\ *([0-9]+) ]]; then
                    battery="${BASH_REMATCH[1]}"
                fi
                break
            fi
        done <<< "$conn_lines"
    fi

    cat <<EOF
{
  "enabled": $enabled,
  "connected": $connected,
  "device_name": "$dev_name",
  "device_mac": "$dev_mac",
  "battery": $battery
}
EOF
}

toggle_bt() {
    local target="${2:-toggle}"
    if command -v bluetoothctl >/dev/null 2>&1; then
        if [[ "$target" == "on" ]]; then
            bluetoothctl power on >/dev/null 2>&1 || true
        elif [[ "$target" == "off" ]]; then
            bluetoothctl power off >/dev/null 2>&1 || true
        else
            local show_out
            show_out=$(bluetoothctl show 2>/dev/null || true)
            if echo "$show_out" | grep -qi "Powered: yes"; then
                bluetoothctl power off >/dev/null 2>&1 || true
            else
                bluetoothctl power on >/dev/null 2>&1 || true
            fi
        fi
    fi
    get_bt_status
}

list_devices() {
    if ! command -v bluetoothctl >/dev/null 2>&1; then
        echo "[]"
        return
    fi

    local conn_lines paired_lines all_lines
    conn_lines=$(bluetoothctl devices Connected 2>/dev/null || true)
    paired_lines=$(bluetoothctl devices Paired 2>/dev/null || bluetoothctl paired-devices 2>/dev/null || true)

    all_lines=$(printf "%s\n%s\n" "$conn_lines" "$paired_lines" | awk '!seen[$2]++' | grep -v '^[[:space:]]*$')

    if [[ -z "$all_lines" ]]; then
        echo "[]"
        return
    fi

    echo "["
    local first=1
    while read -r _ mac name; do
        [[ -z "$mac" ]] && continue
        local dev_info
        dev_info=$(bluetoothctl info "$mac" 2>/dev/null || true)
        local is_conn="false"
        if echo "$dev_info" | grep -qi "Connected: yes"; then
            is_conn="true"
        fi
        
        local bat=0
        local bat_line
        bat_line=$(echo "$dev_info" | grep -i "Battery Percentage" || true)
        if [[ "$bat_line" =~ \(([0-9]+)\) ]]; then
            bat="${BASH_REMATCH[1]}"
        elif [[ "$bat_line" =~ Battery\ Percentage:\ *([0-9]+) ]]; then
            bat="${BASH_REMATCH[1]}"
        fi

        local dev_type="bluetooth"
        if echo "$dev_info" | grep -qiE "Icon: (audio-card|audio-headphones|audio-headset)"; then
            dev_type="audio-headphones"
        elif echo "$dev_info" | grep -qiE "Icon: (input-mouse|input-keyboard|input-gaming)"; then
            dev_type="input-mouse"
        fi

        if [[ $first -eq 0 ]]; then
            echo ","
        fi
        first=0
        printf '  {"name": "%s", "mac": "%s", "connected": %s, "type": "%s", "battery": %d}' \
            "$name" "$mac" "$is_conn" "$dev_type" "$bat"
    done <<< "$all_lines"
    echo ""
    echo "]"
}

connect_device() {
    local mac="${2:-}"
    if [[ -n "$mac" ]] && command -v bluetoothctl >/dev/null 2>&1; then
        bluetoothctl connect "$mac" >/dev/null 2>&1 || true
    fi
    get_bt_status
}

disconnect_device() {
    local mac="${2:-}"
    if [[ -n "$mac" ]] && command -v bluetoothctl >/dev/null 2>&1; then
        bluetoothctl disconnect "$mac" >/dev/null 2>&1 || true
    fi
    get_bt_status
}

scan_devices() {
    if command -v bluetoothctl >/dev/null 2>&1; then
        bluetoothctl --timeout 4 scan on >/dev/null 2>&1 || true
    fi
    list_devices
}

case "$CMD" in
    status)
        get_bt_status
        ;;
    toggle)
        toggle_bt "$@"
        ;;
    devices)
        list_devices
        ;;
    scan)
        scan_devices
        ;;
    connect)
        connect_device "$@"
        ;;
    disconnect)
        disconnect_device "$@"
        ;;
    *)
        echo "Usage: $0 {status|toggle [on|off]|devices|scan|connect <mac>|disconnect <mac>}"
        exit 1
        ;;
esac
