#!/usr/bin/env bash
# devices.sh - Helper script for Privacy, Location, Camera, Mic, and KDE Connect toggles
set -euo pipefail

CMD="${1:-status}"

get_mic_status() {
    local muted="false"
    if command -v wpctl >/dev/null 2>&1; then
        local out
        out=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true)
        if echo "$out" | grep -qi "MUTED"; then
            muted="true"
        fi
    elif command -v pactl >/dev/null 2>&1; then
        local out
        out=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null || true)
        if echo "$out" | grep -qi "yes"; then
            muted="true"
        fi
    fi
    echo "$muted"
}

toggle_mic() {
    if command -v wpctl >/dev/null 2>&1; then
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle >/dev/null 2>&1 || true
    elif command -v pactl >/dev/null 2>&1; then
        pactl set-source-mute @DEFAULT_SOURCE@ toggle >/dev/null 2>&1 || true
    fi
    local m
    m=$(get_mic_status)
    local apps
    apps=$(get_mic_apps)
    echo "{\"mic_muted\": $m, \"mic_apps\": $apps}"
}

get_mic_apps() {
    if command -v python3 >/dev/null 2>&1; then
        python3 - << 'PYEOF'
import subprocess, json, os, glob

home = os.path.expanduser("~")
def get_desktop_info(desktop_id):
    paths = [
        f"/var/lib/flatpak/exports/share/applications/{desktop_id}.desktop",
        f"{home}/.local/share/flatpak/exports/share/applications/{desktop_id}.desktop",
        f"/usr/share/applications/{desktop_id}.desktop",
        f"/usr/local/share/applications/{desktop_id}.desktop",
        f"{home}/.local/share/applications/{desktop_id}.desktop",
    ]
    for p in paths:
        if os.path.isfile(p):
            try:
                with open(p, "r", encoding="utf-8", errors="ignore") as f:
                    name, icon = "", ""
                    for line in f:
                        if line.startswith("Name=") and not name:
                            name = line.strip().split("=", 1)[1]
                        elif line.startswith("Icon=") and not icon:
                            icon = line.strip().split("=", 1)[1]
                        if name and icon:
                            return name, icon
                    if name: return name, icon
            except Exception:
                pass
    return "", ""

def find_native_desktop(comm):
    matches = glob.glob(f"/usr/share/applications/*{comm}*.desktop")
    for p in matches:
        try:
            with open(p, "r", encoding="utf-8", errors="ignore") as f:
                name, icon = "", ""
                for line in f:
                    if line.startswith("Name=") and not name:
                        name = line.strip().split("=", 1)[1]
                    elif line.startswith("Icon=") and not icon:
                        icon = line.strip().split("=", 1)[1]
                    if name and icon:
                        return name, icon
                if name:
                    return name, icon or "audio-input-microphone-symbolic"
        except Exception:
            pass
    return comm.capitalize(), "audio-input-microphone-symbolic"

def get_apps():
    apps = []
    seen_pids = set()

    # 1. Inspect PulseAudio / PipeWire source outputs
    try:
        clients_out = subprocess.run(["pactl", "list", "clients"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True).stdout
        clients = {}
        cur_client = None
        for line in clients_out.splitlines():
            line = line.strip()
            if line.startswith("Client #"):
                cur_client = line.split("#")[1]
                clients[cur_client] = {}
            elif cur_client and "=" in line:
                k, v = line.split("=", 1)
                clients[cur_client][k.strip()] = v.strip().strip("\"")

        so_out = subprocess.run(["pactl", "list", "source-outputs"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True).stdout
        cur_so = None
        so_list = []
        for line in so_out.splitlines():
            sline = line.strip()
            if sline.startswith("Source Output #"):
                cur_so = {"id": sline.split("#")[1]}
                so_list.append(cur_so)
            elif cur_so and ":" in sline and "=" not in sline:
                k, v = sline.split(":", 1)
                cur_so[k.strip()] = v.strip()
            elif cur_so and "=" in sline:
                k, v = sline.split("=", 1)
                cur_so[k.strip()] = v.strip().strip("\"")

        for so in so_list:
            c_id = so.get("Client")
            c_info = clients.get(c_id, {})
            pid_str = so.get("application.process.id") or c_info.get("application.process.id")
            pid = int(pid_str) if pid_str and pid_str.isdigit() else 0
            if pid and pid in seen_pids:
                continue
            if pid:
                seen_pids.add(pid)

            app_name = so.get("application.name") or c_info.get("application.name") or ""
            icon = so.get("application.icon_name") or c_info.get("application.icon_name") or ""
            binary = c_info.get("application.process.binary", "")
            flatpak_id = ""

            if pid:
                try:
                    with open(f"/proc/{pid}/environ", "rb") as f:
                        env = f.read().decode("utf-8", errors="ignore")
                        for el in env.split("\0"):
                            if el.startswith("FLATPAK_ID="):
                                flatpak_id = el.split("=", 1)[1]
                                break
                except Exception:
                    pass

            if flatpak_id:
                fn, fi = get_desktop_info(flatpak_id)
                if fn: app_name = fn
                if fi: icon = fi
                details = "Flatpak • Recording"
            else:
                if not app_name or app_name == binary:
                    fn, fi = find_native_desktop(binary or app_name)
                    if fn: app_name = fn
                    if fi and not icon: icon = fi
                details = "Active Recording"

            apps.append({
                "pid": pid,
                "name": app_name or binary or "Microphone Application",
                "comm": binary or app_name,
                "icon": icon or "audio-input-microphone-symbolic",
                "flatpak_id": flatpak_id,
                "details": details
            })
    except Exception:
        pass

    # 2. Inspect PipeWire stream nodes
    try:
        pw_res = subprocess.run(["pw-dump"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        if pw_res.returncode == 0:
            pw_objs = json.loads(pw_res.stdout)
            for obj in pw_objs:
                if obj.get("type") == "PipeWire:Interface:Node":
                    props = obj.get("info", {}).get("props", {})
                    if props.get("media.class") == "Stream/Input/Audio":
                        pid = props.get("application.process.id")
                        if pid and pid in seen_pids:
                            continue
                        if pid:
                            seen_pids.add(pid)
                        app_name = props.get("application.name") or props.get("node.name") or "Application"
                        icon = props.get("application.icon-name") or "audio-input-microphone-symbolic"
                        flatpak_id = props.get("pipewire.access.portal.app_id", "")
                        details = "Recording"
                        if flatpak_id:
                            fn, fi = get_desktop_info(flatpak_id)
                            if fn: app_name = fn
                            if fi: icon = fi
                            details = "Flatpak • Recording"
                        apps.append({
                            "pid": pid or 0,
                            "name": app_name,
                            "comm": props.get("node.name", ""),
                            "icon": icon,
                            "flatpak_id": flatpak_id,
                            "details": details
                        })
    except Exception:
        pass

    print(json.dumps(apps))

get_apps()
PYEOF
    else
        echo "[]"
    fi
}

stop_mic_app() {
    local pid="${1:-}"
    if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ ]]; then
        kill -15 "$pid" 2>/dev/null || true
        sleep 0.2
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
    local apps
    apps=$(get_mic_apps)
    echo "{\"mic_apps\": $apps}"
}

get_location_status() {
    local enabled="false"
    if command -v gsettings >/dev/null 2>&1; then
        local val
        val=$(gsettings get org.gnome.system.location enabled 2>/dev/null || echo "false")
        if [[ "$val" == "true" ]]; then
            enabled="true"
        fi
    fi
    echo "$enabled"
}

get_location_apps() {
    local enabled
    enabled=$(get_location_status)
    if [[ "$enabled" != "true" ]]; then
        echo "[]"
        return
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 - << 'PYEOF'
import subprocess, json, os, glob

home = os.path.expanduser("~")
def get_desktop_info(desktop_id):
    paths = [
        f"/var/lib/flatpak/exports/share/applications/{desktop_id}.desktop",
        f"{home}/.local/share/flatpak/exports/share/applications/{desktop_id}.desktop",
        f"/usr/share/applications/{desktop_id}.desktop",
        f"/usr/local/share/applications/{desktop_id}.desktop",
        f"{home}/.local/share/applications/{desktop_id}.desktop",
    ]
    for p in paths:
        if os.path.isfile(p):
            try:
                with open(p, "r", encoding="utf-8", errors="ignore") as f:
                    name, icon = "", ""
                    for line in f:
                        if line.startswith("Name=") and not name:
                            name = line.strip().split("=", 1)[1]
                        elif line.startswith("Icon=") and not icon:
                            icon = line.strip().split("=", 1)[1]
                        if name and icon:
                            return name, icon
                    if name: return name, icon
            except Exception:
                pass
    return "", ""

def get_apps():
    apps = []
    seen_pids = set()

    # GeoClue InUse check
    in_use = False
    try:
        res = subprocess.run(["busctl", "--system", "get-property", "org.freedesktop.GeoClue2", "/org/freedesktop/GeoClue2/Manager", "org.freedesktop.GeoClue2.Manager", "InUse"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        if "true" in res.stdout:
            in_use = True
    except Exception:
        pass

    target_bins = {
        "knighttimed": ("Night Light & Timezone", "weather-clear-night-symbolic", "KDE Location Service"),
        "kweather": ("KDE Weather", "weather-clouds-symbolic", "Weather Location"),
        "plasma-weather": ("Weather Applet", "weather-clouds-symbolic", "Weather Location"),
        "gnome-maps": ("GNOME Maps", "find-location-symbolic", "Active Navigation"),
        "marble": ("Marble Virtual Globe", "find-location-symbolic", "Active Map"),
        "geoclue-demo": ("GeoClue Agent", "find-location-symbolic", "Location Client"),
        "geoclue-demo-agent": ("GeoClue Agent", "find-location-symbolic", "Location Client"),
    }

    for pid_dir in glob.glob("/proc/[0-9]*"):
        try:
            pid = int(os.path.basename(pid_dir))
            with open(f"{pid_dir}/cmdline", "rb") as f:
                raw = f.read()
                if not raw: continue
                first_arg = raw.split(b"\0")[0].decode("utf-8", errors="ignore")
                bin_name = os.path.basename(first_arg).lower()

            flatpak_id = ""
            try:
                with open(f"{pid_dir}/environ", "rb") as f:
                    env = f.read().decode("utf-8", errors="ignore")
                    for el in env.split("\0"):
                        if el.startswith("FLATPAK_ID="):
                            flatpak_id = el.split("=", 1)[1]
                            break
            except Exception:
                pass

            if flatpak_id and ("map" in flatpak_id.lower() or "weather" in flatpak_id.lower() or "loc" in flatpak_id.lower()):
                fn, fi = get_desktop_info(flatpak_id)
                apps.append({
                    "pid": pid,
                    "name": fn or flatpak_id.split(".")[-1].capitalize(),
                    "comm": bin_name,
                    "icon": fi or "find-location-symbolic",
                    "details": "Flatpak • Location Active"
                })
                seen_pids.add(pid)
            elif bin_name in target_bins and pid not in seen_pids:
                name, icon, details = target_bins[bin_name]
                apps.append({
                    "pid": pid,
                    "name": name,
                    "comm": bin_name,
                    "icon": icon,
                    "details": details
                })
                seen_pids.add(pid)
        except Exception:
            pass

    if in_use and not apps:
        apps.append({
            "pid": 0,
            "name": "System Geolocation",
            "comm": "geoclue",
            "icon": "find-location-symbolic",
            "details": "GeoClue2 • In Use"
        })

    print(json.dumps(apps))

get_apps()
PYEOF
    else
        echo "[]"
    fi
}

stop_location_app() {
    local pid="${1:-}"
    if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ && "$pid" -gt 0 ]]; then
        kill -15 "$pid" 2>/dev/null || true
        sleep 0.2
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
    local apps
    apps=$(get_location_apps)
    echo "{\"location_apps\": $apps}"
}

toggle_location() {
    local cur
    cur=$(get_location_status)
    local nxt="true"
    if [[ "$cur" == "true" ]]; then
        nxt="false"
    fi
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.system.location enabled "$nxt" 2>/dev/null || true
    fi
    local apps
    apps=$(get_location_apps)
    echo "{\"location_enabled\": $nxt, \"location_apps\": $apps}"
}

WP_CONF_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
WP_CAMERA_CONF="$WP_CONF_DIR/99-disable-camera.conf"

get_camera_status() {
    local blocked="false"
    if [[ -f "$WP_CAMERA_CONF" ]]; then
        blocked="true"
    elif command -v gsettings >/dev/null 2>&1; then
        local gval
        gval=$(gsettings get org.gnome.desktop.privacy disable-camera 2>/dev/null || echo "false")
        if [[ "$gval" == "true" ]]; then
            blocked="true"
        fi
    fi
    echo "$blocked"
}

set_camera_state() {
    local target="$1" # "block" or "unblock"

    if [[ "$target" == "block" ]]; then
        mkdir -p "$WP_CONF_DIR"
        cat << 'EOF' > "$WP_CAMERA_CONF"
{
  "wireplumber.profiles": {
    "main": {
      "hardware.video-capture": "disabled"
    }
  }
}
EOF
        if command -v systemctl >/dev/null 2>&1; then
            systemctl --user restart wireplumber >/dev/null 2>&1 || true
        fi
        if command -v gsettings >/dev/null 2>&1; then
            gsettings set org.gnome.desktop.privacy disable-camera true >/dev/null 2>&1 || true
        fi
        if command -v flatpak >/dev/null 2>&1; then
            flatpak override --user --nodevice=all --device=dri >/dev/null 2>&1 || true
        fi
    else
        rm -f "$WP_CAMERA_CONF"
        if command -v systemctl >/dev/null 2>&1; then
            systemctl --user restart wireplumber >/dev/null 2>&1 || true
        fi
        if command -v gsettings >/dev/null 2>&1; then
            gsettings set org.gnome.desktop.privacy disable-camera false >/dev/null 2>&1 || true
        fi
        rm -f "$HOME/.local/share/flatpak/overrides/global"
    fi
}

toggle_camera() {
    local current
    current=$(get_camera_status)
    if [[ "$current" == "true" ]]; then
        set_camera_state "unblock"
    else
        set_camera_state "block"
    fi
    local c
    c=$(get_camera_status)
    local apps
    apps=$(get_camera_apps)
    echo "{\"camera_blocked\": $c, \"camera_apps\": $apps}"
}

get_camera_apps() {
    if command -v python3 >/dev/null 2>&1; then
        python3 - << 'PYEOF'
import subprocess, json, os, glob

home = os.path.expanduser("~")
def get_desktop_info(desktop_id):
    paths = [
        f"/var/lib/flatpak/exports/share/applications/{desktop_id}.desktop",
        f"{home}/.local/share/flatpak/exports/share/applications/{desktop_id}.desktop",
        f"/usr/share/applications/{desktop_id}.desktop",
        f"/usr/local/share/applications/{desktop_id}.desktop",
        f"{home}/.local/share/applications/{desktop_id}.desktop",
    ]
    for p in paths:
        if os.path.isfile(p):
            try:
                with open(p, "r", encoding="utf-8", errors="ignore") as f:
                    name, icon = "", ""
                    for line in f:
                        if line.startswith("Name=") and not name:
                            name = line.strip().split("=", 1)[1]
                        elif line.startswith("Icon=") and not icon:
                            icon = line.strip().split("=", 1)[1]
                        if name and icon:
                            return name, icon
                    if name: return name, icon
            except Exception:
                pass
    return "", ""

def find_native_desktop(comm):
    matches = glob.glob(f"/usr/share/applications/*{comm}*.desktop")
    for p in matches:
        try:
            with open(p, "r", encoding="utf-8", errors="ignore") as f:
                name, icon = "", ""
                for line in f:
                    if line.startswith("Name=") and not name:
                        name = line.strip().split("=", 1)[1]
                    elif line.startswith("Icon=") and not icon:
                        icon = line.strip().split("=", 1)[1]
                    if name and icon:
                        return name, icon
                if name:
                    return name, icon or "camera-web-symbolic"
        except Exception:
            pass
    return comm.capitalize(), "camera-web-symbolic"

def get_apps():
    apps = []
    seen_pids = set()

    video_devs = glob.glob("/dev/video*")
    pids = []
    if video_devs:
        try:
            res = subprocess.run(["fuser"] + video_devs, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            for part in (res.stdout + " " + res.stderr).split():
                if part.isdigit():
                    pids.append(int(part))
        except Exception:
            pass

    for pid in pids:
        if pid in seen_pids:
            continue
        seen_pids.add(pid)

        comm = ""
        try:
            with open(f"/proc/{pid}/comm", "r") as f:
                comm = f.read().strip()
        except Exception:
            continue

        if comm in ["pipewire", "wireplumber"]:
            continue

        flatpak_id = ""
        try:
            with open(f"/proc/{pid}/environ", "rb") as f:
                env = f.read().decode("utf-8", errors="ignore")
                for line in env.split("\0"):
                    if line.startswith("FLATPAK_ID="):
                        flatpak_id = line.split("=", 1)[1]
                        break
        except Exception:
            pass

        app_name = ""
        app_icon = ""
        if flatpak_id:
            app_name, app_icon = get_desktop_info(flatpak_id)
            if not app_name:
                app_name = flatpak_id.split(".")[-1].capitalize()
            if not app_icon:
                app_icon = flatpak_id
            details = "Flatpak • In Use"
        else:
            app_name, app_icon = find_native_desktop(comm)
            details = "Active"

        apps.append({
            "pid": pid,
            "name": app_name,
            "comm": comm,
            "icon": app_icon or "camera-web-symbolic",
            "flatpak_id": flatpak_id,
            "details": details
        })

    try:
        res = subprocess.run(["pw-dump"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode == 0:
            pw_objects = json.loads(res.stdout)
            video_source_ids = set()
            for obj in pw_objects:
                props = obj.get("info", {}).get("props", {})
                if props.get("media.class") == "Video/Source":
                    video_source_ids.add(obj.get("id"))

            linked_node_ids = set()
            for obj in pw_objects:
                if obj.get("type") == "PipeWire:Interface:Link":
                    props = obj.get("info", {}).get("props", {})
                    out_node = props.get("link.output.node")
                    in_node = props.get("link.input.node")
                    if out_node in video_source_ids and in_node is not None:
                        linked_node_ids.add(in_node)

            for obj in pw_objects:
                if obj.get("type") == "PipeWire:Interface:Node":
                    oid = obj.get("id")
                    props = obj.get("info", {}).get("props", {})
                    mclass = props.get("media.class", "")
                    if oid in linked_node_ids or mclass == "Stream/Input/Video":
                        pid = props.get("application.process.id")
                        if pid and pid in seen_pids:
                            continue
                        if pid:
                            seen_pids.add(pid)
                        app_name = props.get("application.name") or props.get("node.name") or "Application"
                        icon = props.get("application.icon-name") or "camera-web-symbolic"
                        flatpak_id = props.get("pipewire.access.portal.app_id", "")
                        details = "PipeWire Stream • Active"
                        if flatpak_id:
                            fn, fi = get_desktop_info(flatpak_id)
                            if fn: app_name = fn
                            if fi: icon = fi
                            details = "Flatpak • Active"
                        apps.append({
                            "pid": pid or 0,
                            "name": app_name,
                            "comm": props.get("node.name", ""),
                            "icon": icon,
                            "flatpak_id": flatpak_id,
                            "details": details
                        })
    except Exception:
        pass

    print(json.dumps(apps))

get_apps()
PYEOF
    else
        echo "[]"
    fi
}

stop_camera_app() {
    local pid="${1:-}"
    if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ ]]; then
        kill -15 "$pid" 2>/dev/null || true
        sleep 0.2
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
    local apps
    apps=$(get_camera_apps)
    echo "{\"camera_apps\": $apps}"
}

get_kdeconnect_status() {
    local dev_name=""
    local dev_id=""
    local reachable="false"
    local paired="false"
    local dev_type="phone"
    local battery=-1
    local qcmd=""
    if command -v qdbus6 >/dev/null 2>&1; then
        qcmd="qdbus6"
    elif command -v qdbus >/dev/null 2>&1; then
        qcmd="qdbus"
    fi

    if [[ -n "$qcmd" ]]; then
        local devs
        devs=$($qcmd org.kde.kdeconnect /modules/kdeconnect org.kde.kdeconnect.daemon.devices 2>/dev/null || true)
        for id in $devs; do
            [[ -z "$id" ]] && continue
            local is_p
            is_p=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id" org.kde.kdeconnect.device.isPaired 2>/dev/null || echo "false")
            local is_r
            is_r=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id" org.kde.kdeconnect.device.isReachable 2>/dev/null || echo "false")
            if [[ "$is_p" == "true" && "$is_r" == "true" ]] || [[ -z "$dev_id" ]]; then
                dev_id="$id"
                dev_name=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id" org.kde.kdeconnect.device.name 2>/dev/null || echo "Device")
                paired="$is_p"
                reachable="$is_r"
                dev_type=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id" org.kde.kdeconnect.device.type 2>/dev/null || echo "phone")
                local bat
                bat=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id/battery" org.kde.kdeconnect.device.battery.charge 2>/dev/null || echo "-1")
                if [[ "$bat" =~ ^[0-9]+$ ]]; then
                    battery=$bat
                fi
                if [[ "$is_p" == "true" && "$is_r" == "true" ]]; then
                    break
                fi
            fi
        done
    fi

    if [[ -z "$dev_name" ]] && command -v kdeconnect-cli >/dev/null 2>&1; then
        local line
        line=$(kdeconnect-cli -l 2>/dev/null | grep -E '^\s*-\s*' | head -n 1 || true)
        if [[ -n "$line" ]]; then
            dev_name=$(echo "$line" | sed -E 's/^\s*-\s*([^:]+):.*/\1/' || true)
            dev_id=$(echo "$line" | grep -o -E '[0-9a-f]{16,}' || true)
            if echo "$line" | grep -qi "reachable"; then
                reachable="true"
            fi
        fi
    fi

    local is_conn="false"
    if [[ "$paired" == "true" && "$reachable" == "true" ]]; then
        is_conn="true"
    fi

    cat <<EOF
{
  "connected": $is_conn,
  "device_name": "$dev_name",
  "device_id": "$dev_id",
  "reachable": $reachable,
  "paired": $paired,
  "type": "$dev_type",
  "battery": $battery
}
EOF
}

get_kdeconnect_devices() {
    local qcmd=""
    if command -v qdbus6 >/dev/null 2>&1; then
        qcmd="qdbus6"
    elif command -v qdbus >/dev/null 2>&1; then
        qcmd="qdbus"
    fi

    local dev_ids=()
    if [[ -n "$qcmd" ]]; then
        local raw_devs
        raw_devs=$($qcmd org.kde.kdeconnect /modules/kdeconnect org.kde.kdeconnect.daemon.devices 2>/dev/null || true)
        while IFS= read -r id; do
            [[ -z "$id" ]] && continue
            dev_ids+=("$id")
        done <<< "$raw_devs"
    fi

    if [[ ${#dev_ids[@]} -eq 0 ]] && command -v kdeconnect-cli >/dev/null 2>&1; then
        local cli_ids
        cli_ids=$(kdeconnect-cli --id-only --list-devices 2>/dev/null || true)
        while IFS= read -r id; do
            [[ -z "$id" ]] && continue
            dev_ids+=("$id")
        done <<< "$cli_ids"
    fi

    local items=()
    for id in "${dev_ids[@]}"; do
        [[ -z "$id" ]] && continue
        local name="Unknown Device"
        local is_paired="false"
        local is_reachable="false"
        local dev_type="phone"
        local battery=-1
        local is_charging="false"

        if [[ -n "$qcmd" ]]; then
            name=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id" org.kde.kdeconnect.device.name 2>/dev/null || echo "Device")
            is_paired=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id" org.kde.kdeconnect.device.isPaired 2>/dev/null || echo "false")
            is_reachable=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id" org.kde.kdeconnect.device.isReachable 2>/dev/null || echo "false")
            dev_type=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id" org.kde.kdeconnect.device.type 2>/dev/null || echo "phone")
            
            local bat_charge
            bat_charge=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id/battery" org.kde.kdeconnect.device.battery.charge 2>/dev/null || echo "-1")
            if [[ "$bat_charge" =~ ^[0-9]+$ ]]; then
                battery=$bat_charge
                local chg
                chg=$($qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id/battery" org.kde.kdeconnect.device.battery.isCharging 2>/dev/null || echo "false")
                if [[ "$chg" == "true" ]]; then
                    is_charging="true"
                fi
            fi
        fi

        items+=("{\"id\":\"$id\",\"name\":\"$name\",\"paired\":$is_paired,\"reachable\":$is_reachable,\"type\":\"$dev_type\",\"battery\":$battery,\"charging\":$is_charging}")
    done

    local joined
    joined=$(IFS=,; echo "${items[*]}")
    echo "[$joined]"
}

open_kdeconnect() {
    for app in kdeconnect-app kdeconnect-settings; do
        if command -v "$app" >/dev/null 2>&1; then
            "$app" >/dev/null 2>&1 &
            echo '{"success": true}'
            return 0
        fi
    done
    if command -v kcmshell6 >/dev/null 2>&1; then
        kcmshell6 kcm_kdeconnect >/dev/null 2>&1 &
        echo '{"success": true}'
        return 0
    fi
    echo '{"success": false}'
}

ring_kdeconnect() {
    local id="${2:-}"
    if [[ -n "$id" ]] && command -v kdeconnect-cli >/dev/null 2>&1; then
        kdeconnect-cli -d "$id" --ring >/dev/null 2>&1 &
        echo '{"success": true, "action": "ring"}'
    else
        echo '{"success": false}'
    fi
}

ping_kdeconnect() {
    local id="${2:-}"
    if [[ -n "$id" ]] && command -v kdeconnect-cli >/dev/null 2>&1; then
        kdeconnect-cli -d "$id" --ping >/dev/null 2>&1 &
        echo '{"success": true, "action": "ping"}'
    else
        echo '{"success": false}'
    fi
}

share_kdeconnect() {
    local id="${2:-}"
    local file=""
    if command -v kdialog >/dev/null 2>&1; then
        file=$(kdialog --getopenfilename "$HOME" "All Files (*)" 2>/dev/null || true)
    elif command -v zenity >/dev/null 2>&1; then
        file=$(zenity --file-selection 2>/dev/null || true)
    fi

    if [[ -n "$file" && -n "$id" ]] && command -v kdeconnect-cli >/dev/null 2>&1; then
        kdeconnect-cli -d "$id" --share "$file" >/dev/null 2>&1 &
        echo '{"success": true, "action": "share", "file": "'"$file"'"}'
    else
        echo '{"success": false}'
    fi
}

sms_kdeconnect() {
    if command -v kdeconnect-sms >/dev/null 2>&1; then
        kdeconnect-sms >/dev/null 2>&1 &
        echo '{"success": true, "action": "sms"}'
    else
        echo '{"success": false}'
    fi
}

browse_kdeconnect() {
    local id="${2:-}"
    local qcmd="qdbus"
    if command -v qdbus6 >/dev/null 2>&1; then
        qcmd="qdbus6"
    fi
    if [[ -n "$id" ]]; then
        if [[ -n "$qcmd" ]]; then
            $qcmd org.kde.kdeconnect "/modules/kdeconnect/devices/$id/sftp" org.kde.kdeconnect.device.sftp.mountAndBrowse >/dev/null 2>&1 || true
        fi
        if command -v kdeconnect-cli >/dev/null 2>&1; then
            kdeconnect-cli -d "$id" --mount >/dev/null 2>&1 || true
        fi
        echo '{"success": true, "action": "browse"}'
    else
        echo '{"success": false}'
    fi
}

pair_kdeconnect() {
    local id="${2:-}"
    if [[ -n "$id" ]] && command -v kdeconnect-cli >/dev/null 2>&1; then
        kdeconnect-cli -d "$id" --pair >/dev/null 2>&1 || true
        echo '{"success": true, "action": "pair"}'
    else
        echo '{"success": false}'
    fi
}

unpair_kdeconnect() {
    local id="${2:-}"
    if [[ -n "$id" ]] && command -v kdeconnect-cli >/dev/null 2>&1; then
        kdeconnect-cli -d "$id" --unpair >/dev/null 2>&1 || true
        echo '{"success": true, "action": "unpair"}'
    else
        echo '{"success": false}'
    fi
}

refresh_kdeconnect() {
    if command -v kdeconnect-cli >/dev/null 2>&1; then
        kdeconnect-cli --refresh >/dev/null 2>&1 || true
    fi
    get_kdeconnect_devices
}

get_user_info() {
    local uid_val
    uid_val=$(id -u)
    local real_name=""
    local user_name="${USER:-$(whoami)}"
    local icon_file=""

    if command -v qdbus6 >/dev/null 2>&1; then
        real_name=$(qdbus6 --system org.freedesktop.Accounts "/org/freedesktop/Accounts/User${uid_val}" org.freedesktop.Accounts.User.RealName 2>/dev/null || true)
        icon_file=$(qdbus6 --system org.freedesktop.Accounts "/org/freedesktop/Accounts/User${uid_val}" org.freedesktop.Accounts.User.IconFile 2>/dev/null || true)
        local u
        u=$(qdbus6 --system org.freedesktop.Accounts "/org/freedesktop/Accounts/User${uid_val}" org.freedesktop.Accounts.User.UserName 2>/dev/null || true)
        [[ -n "$u" ]] && user_name="$u"
    elif command -v qdbus >/dev/null 2>&1; then
        real_name=$(qdbus --system org.freedesktop.Accounts "/org/freedesktop/Accounts/User${uid_val}" org.freedesktop.Accounts.User.RealName 2>/dev/null || true)
        icon_file=$(qdbus --system org.freedesktop.Accounts "/org/freedesktop/Accounts/User${uid_val}" org.freedesktop.Accounts.User.IconFile 2>/dev/null || true)
        local u
        u=$(qdbus --system org.freedesktop.Accounts "/org/freedesktop/Accounts/User${uid_val}" org.freedesktop.Accounts.User.UserName 2>/dev/null || true)
        [[ -n "$u" ]] && user_name="$u"
    fi

    if [[ -z "$real_name" ]]; then
        real_name=$(getent passwd "$user_name" 2>/dev/null | cut -d: -f5 | cut -d, -f1 || echo "$user_name")
    fi
    [[ -z "$real_name" ]] && real_name="$user_name"

    if [[ -n "$icon_file" && ! -f "$icon_file" ]]; then
        icon_file=""
    fi
    if [[ -z "$icon_file" ]]; then
        for f in "$HOME/.face" "$HOME/.face.icon" "$HOME/.avatar" "/var/lib/AccountsService/icons/$user_name"; do
            if [[ -f "$f" ]]; then
                icon_file="$f"
                break
            fi
        done
    fi

    local role="Standard"
    local acct_type=""
    if command -v qdbus6 >/dev/null 2>&1; then
        acct_type=$(qdbus6 --system org.freedesktop.Accounts "/org/freedesktop/Accounts/User${uid_val}" org.freedesktop.Accounts.User.AccountType 2>/dev/null || true)
    elif command -v qdbus >/dev/null 2>&1; then
        acct_type=$(qdbus --system org.freedesktop.Accounts "/org/freedesktop/Accounts/User${uid_val}" org.freedesktop.Accounts.User.AccountType 2>/dev/null || true)
    fi

    if [[ "$acct_type" == "1" ]]; then
        role="Administrator"
    elif [[ -z "$acct_type" || "$acct_type" == "0" ]]; then
        if groups 2>/dev/null | grep -E '\b(wheel|sudo|admin)\b' >/dev/null; then
            role="Administrator"
        fi
    fi

    real_name=$(echo "$real_name" | sed 's/"/\\"/g')
    user_name=$(echo "$user_name" | sed 's/"/\\"/g')
    icon_file=$(echo "$icon_file" | sed 's/"/\\"/g')
    role=$(echo "$role" | sed 's/"/\\"/g')

    echo "{\"user_real_name\": \"$real_name\", \"user_name\": \"$user_name\", \"user_avatar\": \"$icon_file\", \"user_role\": \"$role\"}"
}

open_user_management() {
    if command -v kcmshell6 >/dev/null 2>&1; then
        kcmshell6 kcm_users >/dev/null 2>&1 &
    elif command -v systemsettings >/dev/null 2>&1; then
        systemsettings kcm_users >/dev/null 2>&1 &
    elif command -v gnome-control-center >/dev/null 2>&1; then
        gnome-control-center user-accounts >/dev/null 2>&1 &
    fi
}

get_dnd_status() {
    local muted="false"
    if command -v kreadconfig6 >/dev/null 2>&1; then
        muted=$(kreadconfig6 --file plasmanotifyrc --group DoNotDisturb --key NotificationSoundsMuted 2>/dev/null || echo "false")
    fi
    echo "{\"dnd_enabled\": $muted}"
}

toggle_dnd() {
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.invokeShortcut "toggle do not disturb" >/dev/null 2>&1 || true
    fi
    get_dnd_status
}

get_airplane_status() {
    local air="false"
    if command -v rfkill >/dev/null 2>&1; then
        local wlan_b bt_b
        wlan_b=$(rfkill list wifi 2>/dev/null | grep -i "Soft blocked: yes" || true)
        bt_b=$(rfkill list bluetooth 2>/dev/null | grep -i "Soft blocked: yes" || true)
        if [[ -n "$wlan_b" && -n "$bt_b" ]]; then
            air="true"
        fi
    elif command -v nmcli >/dev/null 2>&1; then
        local w_rad
        w_rad=$(nmcli radio all 2>/dev/null || true)
        if echo "$w_rad" | grep -q "disabled"; then
            air="true"
        fi
    fi
    echo "$air"
}

toggle_airplane() {
    local cur
    cur=$(get_airplane_status)
    if [[ "$cur" == "true" ]]; then
        if command -v rfkill >/dev/null 2>&1; then
            rfkill unblock all 2>/dev/null || true
        fi
        if command -v nmcli >/dev/null 2>&1; then
            nmcli radio all on 2>/dev/null || true
        fi
        if command -v bluetoothctl >/dev/null 2>&1; then
            bluetoothctl power on >/dev/null 2>&1 || true
        fi
        echo '{"airplane_mode": false}'
    else
        if command -v rfkill >/dev/null 2>&1; then
            rfkill block all 2>/dev/null || true
        fi
        if command -v nmcli >/dev/null 2>&1; then
            nmcli radio all off 2>/dev/null || true
        fi
        echo '{"airplane_mode": true}'
    fi
}

get_all_status() {
    local mic_muted
    mic_muted=$(get_mic_status)
    local mic_apps
    mic_apps=$(get_mic_apps)
    local loc_enabled
    loc_enabled=$(get_location_status)
    local loc_apps
    loc_apps=$(get_location_apps)
    local cam_blocked
    cam_blocked=$(get_camera_status)
    local cam_apps
    cam_apps=$(get_camera_apps)
    local kde_status
    kde_status=$(get_kdeconnect_status)
    local uinfo
    uinfo=$(get_user_info)
    local dnd_info
    dnd_info=$(get_dnd_status)
    local air_info
    air_info=$(get_airplane_status)

    local has_spec="false"
    local has_flame="false"
    command -v spectacle >/dev/null 2>&1 && has_spec="true"
    command -v flameshot >/dev/null 2>&1 && has_flame="true"

    cat <<EOF
{
  "mic_muted": $mic_muted,
  "mic_apps": $mic_apps,
  "location_enabled": $loc_enabled,
  "location_apps": $loc_apps,
  "camera_blocked": $cam_blocked,
  "camera_apps": $cam_apps,
  "kdeconnect": $kde_status,
  "user": $uinfo,
  "dnd": $dnd_info,
  "airplane_mode": $air_info,
  "has_spectacle": $has_spec,
  "has_flameshot": $has_flame
}
EOF
}

trigger_screenshot() {
    local tool="${1:-auto}"
    (
        sleep 0.25
        if [ "$tool" = "flameshot" ] && command -v flameshot >/dev/null 2>&1; then
            flameshot gui >/dev/null 2>&1 &
        elif [ "$tool" = "spectacle" ] && command -v spectacle >/dev/null 2>&1; then
            spectacle >/dev/null 2>&1 &
        elif command -v spectacle >/dev/null 2>&1; then
            spectacle >/dev/null 2>&1 &
        elif command -v flameshot >/dev/null 2>&1; then
            flameshot gui >/dev/null 2>&1 &
        fi
    ) &
}

case "$CMD" in
    status)
        get_all_status
        ;;
    airplane_status)
        echo "{\"airplane_mode\": $(get_airplane_status)}"
        ;;
    toggle_airplane)
        toggle_airplane
        ;;
    camera_status)
        echo "{\"camera_blocked\": $(get_camera_status)}"
        ;;
    camera_apps)
        echo "{\"camera_apps\": $(get_camera_apps)}"
        ;;
    stop_camera_app)
        stop_camera_app "${2:-}"
        ;;
    toggle_camera)
        toggle_camera
        ;;
    dnd_status)
        get_dnd_status
        ;;
    toggle_dnd)
        toggle_dnd
        ;;
    user_info)
        get_user_info
        ;;
    open_user_management)
        open_user_management
        ;;
    mic_status)
        echo "{\"mic_muted\": $(get_mic_status)}"
        ;;
    mic_apps)
        echo "{\"mic_apps\": $(get_mic_apps)}"
        ;;
    stop_mic_app)
        stop_mic_app "${2:-}"
        ;;
    toggle_mic)
        toggle_mic
        ;;
    location_status)
        echo "{\"location_enabled\": $(get_location_status)}"
        ;;
    location_apps)
        echo "{\"location_apps\": $(get_location_apps)}"
        ;;
    stop_location_app)
        stop_location_app "${2:-}"
        ;;
    toggle_location)
        toggle_location
        ;;
    kdeconnect_status)
        get_kdeconnect_status
        ;;
    kdeconnect_devices|kdeconnect_list)
        get_kdeconnect_devices
        ;;
    kdeconnect_open)
        open_kdeconnect
        ;;
    kdeconnect_ring)
        ring_kdeconnect "$@"
        ;;
    kdeconnect_ping)
        ping_kdeconnect "$@"
        ;;
    kdeconnect_share)
        share_kdeconnect "$@"
        ;;
    kdeconnect_sms)
        sms_kdeconnect
        ;;
    kdeconnect_browse)
        browse_kdeconnect "$@"
        ;;
    kdeconnect_pair)
        pair_kdeconnect "$@"
        ;;
    kdeconnect_unpair)
        unpair_kdeconnect "$@"
        ;;
    kdeconnect_refresh)
        refresh_kdeconnect
        ;;
    screenshot)
        trigger_screenshot "${2:-auto}"
        ;;
    check_screenshot_tools)
        has_spec="false"
        has_flame="false"
        command -v spectacle >/dev/null 2>&1 && has_spec="true"
        command -v flameshot >/dev/null 2>&1 && has_flame="true"
        echo "{\"has_spectacle\": $has_spec, \"has_flameshot\": $has_flame}"
        ;;
    *)
        echo "Usage: $0 {status|camera_status|toggle_camera|dnd_status|toggle_dnd|user_info|open_user_management|mic_status|toggle_mic|location_status|toggle_location|kdeconnect_status|kdeconnect_devices|kdeconnect_open|kdeconnect_ring|kdeconnect_ping|kdeconnect_share|kdeconnect_sms|kdeconnect_browse|kdeconnect_pair|kdeconnect_unpair|kdeconnect_refresh}"
        exit 1
        ;;
esac

