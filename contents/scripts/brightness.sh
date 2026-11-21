#!/usr/bin/env bash
# brightness.sh - Helper script for Display Brightness & Advanced Display Controls in KDE GNOME Quick Settings (Plasma 6)
set -euo pipefail

# Ensure environment for kscreen-doctor and Wayland compositor connection
if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi
if [[ -z "${WAYLAND_DISPLAY:-}" && -d "${XDG_RUNTIME_DIR:-}" ]]; then
    for s in "$XDG_RUNTIME_DIR"/wayland-*; do
        if [[ -S "$s" ]]; then
            export WAYLAND_DISPLAY="$(basename "$s")"
            break
        fi
    done
fi

CMD="${1:-status}"
CACHE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gnomequicksettings"
if ! mkdir -p "$CACHE_DIR" 2>/dev/null; then
    CACHE_DIR="/tmp/gnomequicksettings"
    mkdir -p "$CACHE_DIR" 2>/dev/null || true
fi
CONFIG_FILE="$CACHE_DIR/display.json"

get_qdbus() {
    if command -v qdbus6 >/dev/null 2>&1; then
        echo "qdbus6"
    elif command -v qdbus >/dev/null 2>&1; then
        echo "qdbus"
    fi
}

get_display_status() {
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

    # Read advanced display properties directly from KDE KWin/KScreen live & config state
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$b" "$CONFIG_FILE" << 'PYEOF'
import sys, os, subprocess, re, json

brightness = int(sys.argv[1])
config_file = sys.argv[2]

abm_level = 1
abm_supported = False
color_profile = "Built-in"
srgb_intensity = 100
output_name = "eDP-1"

# 1. Inspect live outputs from kscreen-doctor -o
if os.path.exists("/usr/bin/kscreen-doctor"):
    try:
        env = dict(os.environ)
        if "XDG_RUNTIME_DIR" not in env or not env["XDG_RUNTIME_DIR"]:
            env["XDG_RUNTIME_DIR"] = f"/run/user/{os.getuid()}"
        if "WAYLAND_DISPLAY" not in env or not env["WAYLAND_DISPLAY"]:
            rdir = env.get("XDG_RUNTIME_DIR", "")
            if os.path.isdir(rdir):
                for name in os.listdir(rdir):
                    if name.startswith("wayland-") and not name.endswith(".lock"):
                        env["WAYLAND_DISPLAY"] = name
                        break

        raw = subprocess.check_output(["kscreen-doctor", "-o"], universal_newlines=True, stderr=subprocess.DEVNULL, env=env)
        clean = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', raw)

        m_out = re.search(r"Output:\s*\d+\s+([A-Za-z0-9\-_]+)", clean)
        if m_out:
            output_name = m_out.group(1)

        m_abm = re.search(r"Adaptive backlight modulation:\s*([^,\n]+)(?:,\s*set to\s*(\d+))?", clean)
        if m_abm:
            abm_supported = "supported" in m_abm.group(1).lower()
            if m_abm.group(2):
                abm_level = int(m_abm.group(2))

        m_col = re.search(r"Color profile source:\s*(\S+)", clean)
        if m_col:
            raw_col = m_col.group(1).strip()
            if raw_col == "sRGB":
                color_profile = "None"
            elif raw_col == "EDID":
                color_profile = "Built-in"
            elif raw_col == "ICC":
                color_profile = "ICC profile"
            else:
                color_profile = raw_col
    except Exception:
        pass

# 2. Read authoritative state from ~/.config/kwinoutputconfig.json (shared with KDE System Settings)
kwin_cfg = os.path.expanduser("~/.config/kwinoutputconfig.json")
if os.path.isfile(kwin_cfg):
    try:
        with open(kwin_cfg, "r") as f:
            cfg = json.load(f)
            outputs = []
            for item in cfg:
                if item.get("name") == "outputs":
                    outputs = item.get("data", [])
                    break
            target = None
            for out in outputs:
                if out.get("connectorName") == output_name:
                    target = out
                    break
            if not target and outputs:
                target = outputs[0]
                output_name = target.get("connectorName", output_name)

            if target:
                if "sdrGamutWideness" in target:
                    try:
                        # sdrGamutWideness is 0.0 to 1.0; convert to 0 to 100 percentage
                        srgb_intensity = int(round(float(target["sdrGamutWideness"]) * 100))
                    except (ValueError, TypeError):
                        pass
                if "colorProfileSource" in target:
                    raw_col = target["colorProfileSource"]
                    if raw_col == "sRGB":
                        color_profile = "None"
                    elif raw_col == "EDID":
                        color_profile = "Built-in"
                    elif raw_col == "ICC":
                        color_profile = "ICC profile"
                if "abmLevel" in target:
                    try:
                        abm_level = int(target["abmLevel"])
                    except (ValueError, TypeError):
                        pass
                if "brightness" in target and brightness == 100:
                    try:
                        brightness = int(round(float(target["brightness"]) * 100))
                    except (ValueError, TypeError):
                        pass
    except Exception:
        pass
elif os.path.isfile(config_file):
    # Fallback to local cache if kwinoutputconfig.json does not exist
    try:
        with open(config_file, "r") as f:
            c = json.load(f)
            abm_level = c.get("abm_level", abm_level)
            color_profile = c.get("color_profile_source", color_profile)
            srgb_intensity = c.get("srgb_intensity", srgb_intensity)
    except Exception:
        pass

# Normalize nomenclature matching KDE System Settings exactly
if color_profile == "sRGB":
    color_profile = "None"
elif color_profile == "EDID":
    color_profile = "Built-in"
elif color_profile == "ICC":
    color_profile = "ICC profile"

print(json.dumps({
    "brightness": brightness,
    "abm_level": abm_level,
    "abm_supported": abm_supported,
    "color_profile_source": color_profile,
    "srgb_intensity": srgb_intensity,
    "output_name": output_name
}))
PYEOF
    else
        cat <<EOF
{
  "brightness": $b,
  "abm_level": 1,
  "abm_supported": true,
  "color_profile_source": "Built-in",
  "srgb_intensity": 100,
  "output_name": "eDP-1"
}
EOF
    fi
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
    get_display_status
}

set_abm() {
    local level="${2:-1}"
    if (( level < 0 )); then level=0; fi
    if (( level > 4 )); then level=4; fi

    local out_name="eDP-1"
    if command -v kscreen-doctor >/dev/null 2>&1; then
        local raw
        raw=$(kscreen-doctor -o 2>/dev/null || true)
        if [[ "$raw" =~ Output:[[:space:]]*([0-9]+)[[:space:]]*([A-Za-z0-9_-]+) ]]; then
            out_name="${BASH_REMATCH[2]}"
        fi
        kscreen-doctor "output.${out_name}.abm.${level}" >/dev/null 2>&1 || true
    fi

    # Update kwinoutputconfig.json directly as sync safeguard
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$out_name" "$level" << 'PYEOF'
import sys, os, json
out_name = sys.argv[1]
level = int(sys.argv[2])
kwin_cfg = os.path.expanduser("~/.config/kwinoutputconfig.json")
if os.path.isfile(kwin_cfg):
    try:
        with open(kwin_cfg, "r") as f:
            data = json.load(f)
        for item in data:
            if item.get("name") == "outputs":
                for out in item.get("data", []):
                    if out.get("connectorName") == out_name or not out_name:
                        out["abmLevel"] = level
        with open(kwin_cfg, "w") as f:
            json.dump(data, f, indent=4)
    except Exception:
        pass
PYEOF
    fi

    get_display_status
}

set_color_profile() {
    local source="${2:-Built-in}"
    local kscreen_src="EDID"
    if [[ "$source" == "None" || "$source" == "sRGB" ]]; then
        source="None"
        kscreen_src="sRGB"
    elif [[ "$source" == "Built-in" || "$source" == "EDID" ]]; then
        source="Built-in"
        kscreen_src="EDID"
    elif [[ "$source" == "ICC" || "$source" == "ICC profile" ]]; then
        source="ICC profile"
        kscreen_src="ICC"
    fi

    local out_name="eDP-1"
    if command -v kscreen-doctor >/dev/null 2>&1; then
        local raw
        raw=$(kscreen-doctor -o 2>/dev/null || true)
        if [[ "$raw" =~ Output:[[:space:]]*([0-9]+)[[:space:]]*([A-Za-z0-9_-]+) ]]; then
            out_name="${BASH_REMATCH[2]}"
        fi
        kscreen-doctor "output.${out_name}.colorProfileSource.${kscreen_src}" >/dev/null 2>&1 || true
    fi

    # Update kwinoutputconfig.json directly as sync safeguard
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$out_name" "$kscreen_src" << 'PYEOF'
import sys, os, json
out_name = sys.argv[1]
kscreen_src = sys.argv[2]
kwin_cfg = os.path.expanduser("~/.config/kwinoutputconfig.json")
if os.path.isfile(kwin_cfg):
    try:
        with open(kwin_cfg, "r") as f:
            data = json.load(f)
        for item in data:
            if item.get("name") == "outputs":
                for out in item.get("data", []):
                    if out.get("connectorName") == out_name or not out_name:
                        out["colorProfileSource"] = kscreen_src
        with open(kwin_cfg, "w") as f:
            json.dump(data, f, indent=4)
    except Exception:
        pass
PYEOF
    fi

    get_display_status
}

set_srgb_intensity() {
    local intensity="${2:-100}"
    if (( intensity < 0 )); then intensity=0; fi
    if (( intensity > 100 )); then intensity=100; fi

    local out_name="eDP-1"
    if command -v kscreen-doctor >/dev/null 2>&1; then
        local raw
        raw=$(kscreen-doctor -o 2>/dev/null || true)
        if [[ "$raw" =~ Output:[[:space:]]*([0-9]+)[[:space:]]*([A-Za-z0-9_-]+) ]]; then
            out_name="${BASH_REMATCH[2]}"
        fi
        # kscreen-doctor parses sdrGamut as an integer 0..100 and divides by 100.0
        kscreen-doctor "output.${out_name}.sdrGamut.${intensity}" >/dev/null 2>&1 || true
    fi

    # Update kwinoutputconfig.json directly as sync safeguard
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$out_name" "$intensity" << 'PYEOF'
import sys, os, json
out_name = sys.argv[1]
intensity = int(sys.argv[2])
val = round(intensity / 100.0, 2)
kwin_cfg = os.path.expanduser("~/.config/kwinoutputconfig.json")
if os.path.isfile(kwin_cfg):
    try:
        with open(kwin_cfg, "r") as f:
            data = json.load(f)
        for item in data:
            if item.get("name") == "outputs":
                for out in item.get("data", []):
                    if out.get("connectorName") == out_name or not out_name:
                        out["sdrGamutWideness"] = val
        with open(kwin_cfg, "w") as f:
            json.dump(data, f, indent=4)
    except Exception:
        pass
PYEOF
    fi

    get_display_status
}

open_display_settings() {
    nohup bash -c '
        if command -v kcmshell6 >/dev/null 2>&1; then
            kcmshell6 kcm_kscreen >/dev/null 2>&1 &
            exit 0
        fi
        if command -v systemsettings >/dev/null 2>&1; then
            systemsettings kcm_kscreen >/dev/null 2>&1 &
            exit 0
        fi
    ' >/dev/null 2>&1 &
    echo '{"success": true, "action": "open_display_settings"}'
}

case "$CMD" in
    status|get)
        get_display_status
        ;;
    set)
        set_brightness "$@"
        ;;
    set_abm)
        set_abm "$@"
        ;;
    set_color_profile|set_profile)
        set_color_profile "$@"
        ;;
    set_srgb_intensity|set_intensity)
        set_srgb_intensity "$@"
        ;;
    open_display_settings|open_settings)
        open_display_settings
        ;;
    *)
        echo "Usage: $0 {status|get|set <0-100>|set_abm <0-4>|set_color_profile <sRGB|EDID>|set_srgb_intensity <0-100>|open_display_settings}"
        exit 1
        ;;
esac
