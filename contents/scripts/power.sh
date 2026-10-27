#!/usr/bin/env bash
# power.sh - Helper script for Power, Battery, Lock, Theme & Night Light in KDE GNOME Quick Settings (Plasma 6)
set -euo pipefail

CMD="${1:-battery}"

get_qdbus() {
    if command -v qdbus6 >/dev/null 2>&1; then
        echo "qdbus6"
    elif command -v qdbus >/dev/null 2>&1; then
        echo "qdbus"
    fi
}

get_power_profile() {
    local profile=""
    if command -v powerprofilesctl >/dev/null 2>&1; then
        profile=$(powerprofilesctl get 2>/dev/null || true)
    fi
    if [[ -z "$profile" ]] && command -v qdbus6 >/dev/null 2>&1; then
        profile=$(qdbus6 --system net.hadess.PowerProfiles /net/hadess/PowerProfiles org.freedesktop.DBus.Properties.Get net.hadess.PowerProfiles ActiveProfile 2>/dev/null || true)
    fi
    if [[ -z "$profile" ]] && command -v qdbus >/dev/null 2>&1; then
        profile=$(qdbus --system net.hadess.PowerProfiles /net/hadess/PowerProfiles org.freedesktop.DBus.Properties.Get net.hadess.PowerProfiles ActiveProfile 2>/dev/null || true)
    fi
    if [[ -z "$profile" ]] && command -v busctl >/dev/null 2>&1; then
        local raw
        raw=$(busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile 2>/dev/null || true)
        if [[ -n "$raw" ]]; then
            profile=$(echo "$raw" | awk '{print $2}' | tr -d '"')
        fi
    fi
    echo "${profile:-balanced}"
}

set_power_profile() {
    local target="${1:-balanced}"
    if [[ "$target" == "optimise" || "$target" == "optimize" || "$target" == "powersave" || "$target" == "power_saver" ]]; then
        target="power-saver"
    elif [[ "$target" == "balance" ]]; then
        target="balanced"
    fi

    local success="false"
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set "$target" 2>/dev/null && success="true" || true
    fi
    if [[ "$success" != "true" ]] && command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 --system net.hadess.PowerProfiles /net/hadess/PowerProfiles org.freedesktop.DBus.Properties.Set net.hadess.PowerProfiles ActiveProfile "$target" 2>/dev/null && success="true" || true
    fi
    if [[ "$success" != "true" ]] && command -v qdbus >/dev/null 2>&1; then
        qdbus --system net.hadess.PowerProfiles /net/hadess/PowerProfiles org.freedesktop.DBus.Properties.Set net.hadess.PowerProfiles ActiveProfile "$target" 2>/dev/null && success="true" || true
    fi
    if [[ "$success" != "true" ]] && command -v busctl >/dev/null 2>&1; then
        busctl set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s "$target" 2>/dev/null && success="true" || true
    fi

    cat <<EOF
{
  "power_profile": "$target",
  "success": $success
}
EOF
}

get_battery() {
    local percentage=100
    local charging="false"
    local state="discharging"

    # 1. Try reading directly from /sys/class/power_supply
    for bat in /sys/class/power_supply/BAT* /sys/class/power_supply/battery; do
        if [[ -d "$bat" ]]; then
            if [[ -f "$bat/capacity" ]]; then
                percentage=$(cat "$bat/capacity")
            fi
            if [[ -f "$bat/status" ]]; then
                local st
                st=$(cat "$bat/status" | tr '[:upper:]' '[:lower:]')
                if [[ "$st" == "charging" || "$st" == "full" ]]; then
                    charging="true"
                    state="charging"
                fi
            fi
            break
        fi
    done

    local is_dark="false"
    local cur_scheme
    cur_scheme=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || echo "BreezeLight")
    if [[ "$cur_scheme" =~ [Dd]ark ]]; then
        is_dark="true"
    fi

    local prof
    prof=$(get_power_profile)

    local nl
    nl=$(get_nightlight)

    cat <<EOF
{
  "percentage": $percentage,
  "charging": $charging,
  "state": "$state",
  "dark_mode": $is_dark,
  "power_profile": "$prof",
  "night_light": $nl
}
EOF
}

get_nightlight() {
    local qcmd
    qcmd=$(get_qdbus)
    local nl="false"
    if [[ -n "$qcmd" ]]; then
        local running
        running=$($qcmd org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight.running 2>/dev/null || echo "")
        if [[ "$running" == "true" ]]; then
            nl="true"
        elif [[ "$running" == "false" ]]; then
            nl="false"
        else
            local cc
            cc=$($qcmd org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.nightColorActive 2>/dev/null || echo "false")
            if [[ "$cc" == "true" ]]; then
                nl="true"
            fi
        fi
    fi
    echo "$nl"
}

lock_screen() {
    local qcmd
    qcmd=$(get_qdbus)
    # Prefer KDE's own screen lock via DBus (handles auth properly)
    if [[ -n "$qcmd" ]]; then
        $qcmd org.kde.screensaver /ScreenSaver Lock 2>/dev/null \
            || $qcmd org.freedesktop.ScreenSaver /ScreenSaver Lock 2>/dev/null \
            || true
    fi
    # Fallback: loginctl
    if command -v loginctl >/dev/null 2>&1; then
        loginctl lock-session 2>/dev/null || true
    fi
    echo '{"success": true, "action": "lock"}'
}

logout_session() {
    local qcmd
    qcmd=$(get_qdbus)
    # Use KDE session manager — handles save/restore and auth
    if [[ -n "$qcmd" ]]; then
        $qcmd org.kde.Shutdown /Shutdown logout 2>/dev/null || true
        echo '{"success": true, "action": "logout"}'
        return
    fi
    if command -v loginctl >/dev/null 2>&1; then
        loginctl terminate-session "${XDG_SESSION_ID:-self}" 2>/dev/null || true
    fi
    echo '{"success": true, "action": "logout"}'
}

suspend_system() {
    local qcmd
    qcmd=$(get_qdbus)
    # Prefer DBus to login1 (polkit-aware, works inside Plasma DataSource)
    if [[ -n "$qcmd" ]]; then
        $qcmd org.freedesktop.login1 /org/freedesktop/login1 \
            org.freedesktop.login1.Manager.Suspend true 2>/dev/null || true
    fi
    # Fallback: systemctl suspend (usually works without sudo via polkit)
    if command -v systemctl >/dev/null 2>&1; then
        systemctl suspend 2>/dev/null || true
    fi
    echo '{"success": true, "action": "suspend"}'
}

reboot_system() {
    local qcmd
    qcmd=$(get_qdbus)
    # Prefer KDE session manager — shows save-dialog, handles auth
    if [[ -n "$qcmd" ]]; then
        $qcmd org.kde.Shutdown /Shutdown logoutAndReboot 2>/dev/null || true
        echo '{"success": true, "action": "reboot"}'
        return
    fi
    # Fallback: systemctl (may need polkit rule)
    if command -v systemctl >/dev/null 2>&1; then
        systemctl reboot 2>/dev/null || true
    fi
    echo '{"success": true, "action": "reboot"}'
}

shutdown_system() {
    local qcmd
    qcmd=$(get_qdbus)
    # Prefer KDE session manager — shows save-dialog, handles auth
    if [[ -n "$qcmd" ]]; then
        $qcmd org.kde.Shutdown /Shutdown logoutAndShutdown 2>/dev/null || true
        echo '{"success": true, "action": "shutdown"}'
        return
    fi
    # Fallback: systemctl (may need polkit rule)
    if command -v systemctl >/dev/null 2>&1; then
        systemctl poweroff 2>/dev/null || true
    fi
    echo '{"success": true, "action": "shutdown"}'
}

open_settings() {
    for cmd in systemsettings systemsettings6 systemsettings5 gnome-control-center; do
        if command -v "$cmd" >/dev/null 2>&1; then
            "$cmd" >/dev/null 2>&1 &
            echo "{\"success\": true, \"launched\": \"$cmd\"}"
            return 0
        fi
    done
    echo '{"success": false, "error": "No settings app found"}'
}

toggle_darkmode() {
    local target="${2:-toggle}"
    local is_dark="false"
    local cur_scheme
    cur_scheme=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || echo "BreezeLight")
    if [[ "$cur_scheme" =~ [Dd]ark ]]; then
        is_dark="true"
    fi

    local switch_to=""
    if [[ "$target" == "dark" || "$target" == "on" ]]; then
        switch_to="dark"
    elif [[ "$target" == "light" || "$target" == "off" ]]; then
        switch_to="light"
    else
        if [[ "$is_dark" == "true" ]]; then
            switch_to="light"
        else
            switch_to="dark"
        fi
    fi

    if [[ "$switch_to" == "dark" ]]; then
        if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
            plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
        elif command -v lookandfeeltool >/dev/null 2>&1; then
            lookandfeeltool -a org.kde.breezedark.desktop >/dev/null 2>&1 || true
        fi
        echo '{"dark_mode": true}'
    else
        if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
            plasma-apply-colorscheme BreezeLight >/dev/null 2>&1 || true
        elif command -v lookandfeeltool >/dev/null 2>&1; then
            lookandfeeltool -a org.kde.breeze.desktop >/dev/null 2>&1 || true
        fi
        echo '{"dark_mode": false}'
    fi
}

toggle_nightlight() {
    local qcmd
    qcmd=$(get_qdbus)
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "Toggle Night Color" >/dev/null 2>&1 || true
    elif [[ -n "$qcmd" ]]; then
        $qcmd org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "Toggle Night Color" >/dev/null 2>&1 || true
    fi
    local nl
    nl=$(get_nightlight)
    echo "{\"night_light\": $nl}"
}

case "$CMD" in
    battery)
        get_battery
        ;;
    profile)
        echo "{\"power_profile\": \"$(get_power_profile)\"}"
        ;;
    set_profile)
        set_power_profile "${2:-balanced}"
        ;;
    lock)
        lock_screen
        ;;
    logout)
        logout_session
        ;;
    suspend)
        suspend_system
        ;;
    reboot)
        reboot_system
        ;;
    shutdown)
        shutdown_system
        ;;
    settings)
        open_settings
        ;;
    darkmode)
        toggle_darkmode "$@"
        ;;
    nightlight)
        toggle_nightlight
        ;;
    *)
        echo "Usage: $0 {battery|lock|logout|suspend|reboot|shutdown|settings|darkmode|nightlight}"
        exit 1
        ;;
esac
