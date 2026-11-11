#!/usr/bin/env bash
# audio.sh - Helper script for Audio volume, mute & stream mixer management in KDE GNOME Quick Settings
set -euo pipefail

if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

CMD="${1:-status}"

get_audio_status() {
    local volume=50
    local muted="false"

    if command -v wpctl >/dev/null 2>&1; then
        local out
        out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
        if [[ -n "$out" ]]; then
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
        if (( val > 0 )); then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 >/dev/null 2>&1 || true
        else
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 1 >/dev/null 2>&1 || true
        fi
    elif command -v pactl >/dev/null 2>&1; then
        pactl set-sink-volume @DEFAULT_SINK@ "${val}%" >/dev/null 2>&1 || true
        if (( val > 0 )); then
            pactl set-sink-mute @DEFAULT_SINK@ 0 >/dev/null 2>&1 || true
        else
            pactl set-sink-mute @DEFAULT_SINK@ 1 >/dev/null 2>&1 || true
        fi
    elif command -v amixer >/dev/null 2>&1; then
        if (( val > 0 )); then
            amixer sset Master "${val}%" unmute >/dev/null 2>&1 || true
        else
            amixer sset Master 0% mute >/dev/null 2>&1 || true
        fi
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

get_audio_mixer() {
    python3 -c '
import subprocess, json, os

env = os.environ.copy()
if "XDG_RUNTIME_DIR" not in env or not env["XDG_RUNTIME_DIR"]:
    env["XDG_RUNTIME_DIR"] = f"/run/user/{os.getuid()}"

def run_pactl(args):
    try:
        r = subprocess.run(["pactl", "-f", "json"] + args, capture_output=True, text=True, env=env)
        if r.stdout.strip():
            return json.loads(r.stdout)
    except Exception:
        pass
    return []

def get_def_sink():
    try:
        r = subprocess.run(["pactl", "info"], capture_output=True, text=True, env=env)
        for line in r.stdout.splitlines():
            if line.startswith("Default Sink:"):
                return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return ""

def parse_volume(vol_dict):
    if not isinstance(vol_dict, dict):
        return 0
    for ch, v in vol_dict.items():
        if isinstance(v, dict) and "value_percent" in v:
            try:
                return int(v["value_percent"].replace("%", "").strip())
            except ValueError:
                pass
    return 0

def get_mixer_data():
    def_sink = get_def_sink()
    raw_sinks = run_pactl(["list", "sinks"])
    raw_inputs = run_pactl(["list", "sink-inputs"])
    raw_sources = run_pactl(["list", "sources"])

    sinks = []
    master_vol = 50
    master_muted = False

    for s in raw_sinks:
        name = s.get("name", "")
        desc = s.get("description") or name or "Audio Output"
        vol = parse_volume(s.get("volume", {}))
        muted = bool(s.get("mute", False))
        is_default = (name == def_sink)
        if is_default:
            master_vol = vol
            master_muted = muted
        icon = "audio-speakers-symbolic"
        if "headphone" in desc.lower() or "headset" in desc.lower():
            icon = "audio-headphones-symbolic"
        elif "hdmi" in desc.lower() or "display" in desc.lower():
            icon = "video-display-symbolic"
        sinks.append({
            "index": s.get("index"),
            "name": name,
            "description": desc,
            "volume": vol,
            "muted": muted,
            "is_default": is_default,
            "icon": icon
        })

    inputs = []
    for si in raw_inputs:
        props = si.get("properties", {})
        app_name = props.get("application.name") or props.get("media.name") or "Application"
        icon = props.get("application.icon_name") or "audio-speakers-symbolic"
        vol = parse_volume(si.get("volume", {}))
        muted = bool(si.get("mute", False))
        inputs.append({
            "index": si.get("index"),
            "name": app_name,
            "icon": icon,
            "volume": vol,
            "muted": muted
        })

    sources = []
    for src in raw_sources:
        name = src.get("name", "")
        if "monitor" in name.lower():
            continue
        desc = src.get("description") or name or "Audio Input"
        vol = parse_volume(src.get("volume", {}))
        muted = bool(src.get("mute", False))
        sources.append({
            "index": src.get("index"),
            "name": name,
            "description": desc,
            "volume": vol,
            "muted": muted,
            "icon": "audio-input-microphone-symbolic"
        })

    res = {
        "volume": master_vol,
        "muted": master_muted,
        "default_sink": def_sink,
        "sinks": sinks,
        "sink_inputs": inputs,
        "sources": sources
    }
    print(json.dumps(res))

get_mixer_data()
'
}

set_sink_input_volume() {
    local idx="${2}"
    local val="${3:-50}"
    if (( val < 0 )); then val=0; fi
    if (( val > 100 )); then val=100; fi
    pactl set-sink-input-volume "$idx" "${val}%" >/dev/null 2>&1 || true
    if (( val > 0 )); then
        pactl set-sink-input-mute "$idx" 0 >/dev/null 2>&1 || true
    fi
}

toggle_sink_input_mute() {
    local idx="${2}"
    pactl set-sink-input-mute "$idx" toggle >/dev/null 2>&1 || true
    get_audio_mixer
}

set_sink_volume() {
    local idx="${2}"
    local val="${3:-50}"
    if (( val < 0 )); then val=0; fi
    if (( val > 100 )); then val=100; fi
    pactl set-sink-volume "$idx" "${val}%" >/dev/null 2>&1 || true
    if (( val > 0 )); then
        pactl set-sink-mute "$idx" 0 >/dev/null 2>&1 || true
    fi
}

toggle_sink_mute() {
    local idx="${2}"
    pactl set-sink-mute "$idx" toggle >/dev/null 2>&1 || true
    get_audio_mixer
}

set_default_sink() {
    local target="${2}"
    pactl set-default-sink "$target" >/dev/null 2>&1 || true
    get_audio_mixer
}

set_source_volume() {
    local idx="${2}"
    local val="${3:-50}"
    if (( val < 0 )); then val=0; fi
    if (( val > 100 )); then val=100; fi
    pactl set-source-volume "$idx" "${val}%" >/dev/null 2>&1 || true
    if (( val > 0 )); then
        pactl set-source-mute "$idx" 0 >/dev/null 2>&1 || true
    fi
}

toggle_source_mute() {
    local idx="${2}"
    pactl set-source-mute "$idx" toggle >/dev/null 2>&1 || true
    get_audio_mixer
}

open_settings() {
    if command -v kcmshell6 >/dev/null 2>&1; then
        nohup kcmshell6 kcm_pulseaudio >/dev/null 2>&1 &
    elif command -v systemsettings >/dev/null 2>&1; then
        nohup systemsettings kcm_pulseaudio >/dev/null 2>&1 &
    fi
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
    mixer)
        get_audio_mixer
        ;;
    set_sink_input_volume)
        set_sink_input_volume "$@"
        ;;
    toggle_sink_input_mute)
        toggle_sink_input_mute "$@"
        ;;
    set_sink_volume)
        set_sink_volume "$@"
        ;;
    toggle_sink_mute)
        toggle_sink_mute "$@"
        ;;
    set_default_sink)
        set_default_sink "$@"
        ;;
    set_source_volume)
        set_source_volume "$@"
        ;;
    toggle_source_mute)
        toggle_source_mute "$@"
        ;;
    open_settings)
        open_settings
        ;;
    *)
        echo "Usage: $0 {status|set_volume <0-100>|toggle_mute|mixer|set_sink_input_volume|toggle_sink_input_mute|set_sink_volume|toggle_sink_mute|set_default_sink|set_source_volume|toggle_source_mute|open_settings}"
        exit 1
        ;;
esac
