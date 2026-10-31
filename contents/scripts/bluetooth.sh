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

    local conn_lines paired_lines all_dev_lines
    conn_lines=$(bluetoothctl devices Connected 2>/dev/null || true)
    paired_lines=$(bluetoothctl devices Paired 2>/dev/null || bluetoothctl paired-devices 2>/dev/null || true)
    all_dev_lines=$(bluetoothctl devices 2>/dev/null || true)

    local all_lines
    all_lines=$(printf "%s\n%s\n%s\n" "$conn_lines" "$paired_lines" "$all_dev_lines" | awk '!seen[$2]++' | grep -v '^[[:space:]]*$')

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

        # Check alias/name from dev_info if available
        local info_alias info_name
        info_alias=$(echo "$dev_info" | grep -m1 "Alias:" | sed 's/^[[:space:]]*Alias:[[:space:]]*//' || true)
        info_name=$(echo "$dev_info" | grep -m1 "Name:" | sed 's/^[[:space:]]*Name:[[:space:]]*//' || true)
        if [[ -n "$info_alias" ]]; then
            name="$info_alias"
        elif [[ -n "$info_name" ]]; then
            name="$info_name"
        fi

        # Determine pairing state
        local is_paired="false"
        if echo "$dev_info" | grep -qi "Paired: yes"; then
            is_paired="true"
        fi

        # If not paired and name is empty or matches raw MAC with hyphens, skip nameless BLE beacons
        local mac_hyphen="${mac//:/-}"
        if [[ "$is_paired" == "false" ]]; then
            if [[ -z "$name" || "$name" == "$mac" || "$name" == "$mac_hyphen" ]]; then
                continue
            fi
        fi

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
        elif echo "$dev_info" | grep -qiE "Icon: (phone|smartphone)"; then
            dev_type="phone"
        elif echo "$dev_info" | grep -qiE "Icon: (computer|laptop)"; then
            dev_type="computer"
        fi

        local safe_name="${name//\"/\\\"}"
        if [[ $first -eq 0 ]]; then
            echo ","
        fi
        first=0
        printf '  {"name": "%s", "mac": "%s", "connected": %s, "paired": %s, "type": "%s", "battery": %d}' \
            "$safe_name" "$mac" "$is_conn" "$is_paired" "$dev_type" "$bat"
    done <<< "$all_lines"
    echo ""
    echo "]"
}

pair_device() {
    # Open native KDE Plasma Bluetooth pairing dialog/settings
    open_settings "$@"
}

open_settings() {
    if command -v kcmshell6 >/dev/null 2>&1; then
        nohup kcmshell6 kcm_bluetooth >/dev/null 2>&1 &
    elif command -v systemsettings >/dev/null 2>&1; then
        nohup systemsettings kcm_bluetooth >/dev/null 2>&1 &
    elif command -v bluedevil-wizard >/dev/null 2>&1; then
        nohup bluedevil-wizard >/dev/null 2>&1 &
    fi
    echo '{"status": "settings_opened"}'
}

connect_device() {
    local mac="${2:-}"
    if [[ -n "$mac" ]] && command -v bluetoothctl >/dev/null 2>&1; then
        local dev_info
        dev_info=$(bluetoothctl info "$mac" 2>/dev/null || true)
        if ! echo "$dev_info" | grep -qi "Paired: yes"; then
            pair_device "$@"
            return
        fi
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
        # Ensure Bluetooth controller is on
        local show_out
        show_out=$(bluetoothctl show 2>/dev/null || true)
        if ! echo "$show_out" | grep -qi "Powered: yes"; then
            bluetoothctl power on >/dev/null 2>&1 || true
            sleep 0.5
        fi

        # Reset any stuck scan and initiate discovery scan for 4 seconds
        bluetoothctl scan off >/dev/null 2>&1 || true
        if command -v timeout >/dev/null 2>&1; then
            timeout 4 bluetoothctl scan on >/dev/null 2>&1 || true
        else
            bluetoothctl --timeout 4 scan on >/dev/null 2>&1 || true
        fi
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
    pair)
        pair_device "$@"
        ;;
    disconnect)
        disconnect_device "$@"
        ;;
    open_settings)
        open_settings
        ;;
    *)
        echo "Usage: $0 {status|toggle [on|off]|devices|scan|pair <mac>|connect <mac>|disconnect <mac>|open_settings}"
        exit 1
        ;;
esac
