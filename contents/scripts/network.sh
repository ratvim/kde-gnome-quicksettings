#!/usr/bin/env bash
# network.sh - Robust NetworkManager helper for Wi-Fi, Hotspot, and Scanning in KDE GNOME Quick Settings
set -euo pipefail

CMD="${1:-status}"

# Execute python-based network management for atomic, reliable operations
python3 - "$CMD" "${2:-}" "${3:-}" << 'PYEOF'
import sys, subprocess, json, socket, time, os

cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
arg2 = sys.argv[2] if len(sys.argv) > 2 else ""
arg3 = sys.argv[3] if len(sys.argv) > 3 else ""

def run_cmd(args):
    try:
        return subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True).stdout
    except Exception:
        return ""

def get_wlan_device():
    out = run_cmd(["nmcli", "-t", "-f", "DEVICE,TYPE", "dev"])
    for line in out.splitlines():
        parts = line.split(":")
        if len(parts) >= 2 and parts[1] == "wifi":
            return parts[0]
    return "wlan0"

def get_active_wireless():
    active_hotspot = None
    active_client = None
    out = run_cmd(["nmcli", "-t", "-f", "UUID,NAME,TYPE,DEVICE", "c", "show", "--active"])
    for line in out.splitlines():
        parts = line.split(":")
        if len(parts) >= 3 and parts[2] in ("802-11-wireless", "wifi"):
            uuid = parts[0]
            name = parts[1]
            dev = parts[3] if len(parts) >= 4 else ""
            mode = run_cmd(["nmcli", "-g", "802-11-wireless.mode", "c", "show", uuid]).strip()
            if mode == "ap" or name.lower() == "hotspot":
                active_hotspot = {"uuid": uuid, "name": name, "device": dev}
            else:
                active_client = {"uuid": uuid, "name": name, "device": dev}
    # Enforce strict mutual exclusivity: if actively connected to Wi-Fi client, Hotspot is OFF
    if active_client:
        active_hotspot = None
    return active_hotspot, active_client

def get_plasma_nm_config_path():
    config_dir = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    return os.path.join(config_dir, "plasma-nm")

def read_plasma_nm_hotspot():
    cfg_file = get_plasma_nm_config_path()
    name = ""
    password = ""
    if os.path.exists(cfg_file):
        try:
            with open(cfg_file, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("HotspotName="):
                        name = line.split("=", 1)[1].strip()
                    elif line.startswith("HotspotPassword="):
                        password = line.split("=", 1)[1].strip()
        except Exception:
            pass
    return name, password

def write_plasma_nm_hotspot(name, password):
    cfg_file = get_plasma_nm_config_path()
    try:
        os.makedirs(os.path.dirname(cfg_file), exist_ok=True)
    except Exception:
        pass
    lines = []
    if os.path.exists(cfg_file):
        try:
            with open(cfg_file, "r", encoding="utf-8") as f:
                lines = f.readlines()
        except Exception:
            lines = []

    new_lines = []
    in_general = False
    found_general = False
    name_written = False
    pass_written = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            if in_general:
                if not name_written and name:
                    new_lines.append(f"HotspotName={name}\n")
                    name_written = True
                if not pass_written and password:
                    new_lines.append(f"HotspotPassword={password}\n")
                    pass_written = True
            in_general = (stripped.lower() == "[general]")
            if in_general:
                found_general = True
            new_lines.append(line)
            continue

        if in_general:
            if stripped.startswith("HotspotName="):
                new_lines.append(f"HotspotName={name}\n")
                name_written = True
                continue
            elif stripped.startswith("HotspotPassword="):
                new_lines.append(f"HotspotPassword={password}\n")
                pass_written = True
                continue
        new_lines.append(line)

    if in_general:
        if not name_written and name:
            new_lines.append(f"HotspotName={name}\n")
            name_written = True
        if not pass_written and password:
            new_lines.append(f"HotspotPassword={password}\n")
            pass_written = True

    if not found_general:
        if new_lines and not new_lines[-1].endswith("\n"):
            new_lines.append("\n")
        new_lines.append("[General]\n")
        if name:
            new_lines.append(f"HotspotName={name}\n")
        if password:
            new_lines.append(f"HotspotPassword={password}\n")

    try:
        with open(cfg_file, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
        return True
    except Exception:
        return False

def get_hotspot_info(active_hotspot=None):
    plasma_ssid, plasma_pass = read_plasma_nm_hotspot()

    nm_ssid = ""
    nm_pass = ""
    target_hs = active_hotspot["uuid"] if active_hotspot else "Hotspot"
    try:
        s_out = run_cmd(["nmcli", "-s", "-g", "802-11-wireless.ssid,802-11-wireless-security.psk", "c", "show", target_hs]).splitlines()
        if len(s_out) >= 1: nm_ssid = s_out[0].strip()
        if len(s_out) >= 2: nm_pass = s_out[1].strip()
    except Exception:
        pass

    # Authoritative resolution:
    # 1. If KDE Global Settings (~/.config/plasma-nm) has credentials, they are authoritative
    if plasma_ssid or plasma_pass:
        authoritative_ssid = plasma_ssid or nm_ssid
        authoritative_pass = plasma_pass or nm_pass
        # Keep NetworkManager profile synchronized with plasma-nm
        if (nm_ssid and nm_ssid != authoritative_ssid) or (nm_pass and nm_pass != authoritative_pass):
            run_cmd(["nmcli", "connection", "modify", target_hs,
                     "802-11-wireless.ssid", authoritative_ssid,
                     "802-11-wireless-security.psk", authoritative_pass])
    elif nm_ssid or nm_pass:
        # 2. If plasma-nm was empty but NM profile exists, populate plasma-nm
        authoritative_ssid = nm_ssid
        authoritative_pass = nm_pass
        write_plasma_nm_hotspot(authoritative_ssid, authoritative_pass)
    else:
        # 3. Default fallback
        try:
            h = socket.gethostname()
        except Exception:
            h = "Linux"
        authoritative_ssid = f"{h}-Hotspot"
        authoritative_pass = "hotspot12345"

    return {
        "hotspot_enabled": active_hotspot is not None,
        "ssid": authoritative_ssid,
        "password": authoritative_pass,
        "con_name": active_hotspot["name"] if active_hotspot else "Hotspot"
    }

def get_best_saved_client_wifi():
    out = run_cmd(["nmcli", "-t", "-f", "UUID,NAME,TYPE,TIMESTAMP,AUTOCONNECT", "c", "show"])
    candidates = []
    for line in out.splitlines():
        parts = line.split(":")
        if len(parts) >= 3 and parts[2] == "802-11-wireless":
            uuid, name = parts[0], parts[1]
            ts = int(parts[3]) if len(parts) > 3 and parts[3].isdigit() else 0
            auto = parts[4] if len(parts) > 4 else "yes"
            mode = run_cmd(["nmcli", "-g", "802-11-wireless.mode", "c", "show", uuid]).strip()
            if mode == "infrastructure":
                candidates.append((ts, uuid, name))
    candidates.sort(reverse=True, key=lambda x: x[0])
    return candidates[0] if candidates else None

def get_status():
    active_hotspot, active_client = get_active_wireless()
    radio_out = run_cmd(["nmcli", "radio", "wifi"]).strip()
    radio_on = (radio_out == "enabled")

    if active_hotspot:
        # Hotspot is actively broadcasting -> Client Wi-Fi is disabled
        hs_info = get_hotspot_info(active_hotspot)
        hs_info["hotspot_enabled"] = True
        return {
            "wifi_enabled": False,
            "connected": False,
            "ssid": "",
            "signal": 0,
            "hotspot": hs_info
        }

    hs_info = get_hotspot_info(None)
    hs_info["hotspot_enabled"] = False

    connected = (active_client is not None)
    ssid = ""
    signal = 0
    if connected:
        s_name = run_cmd(["nmcli", "-g", "802-11-wireless.ssid", "c", "show", active_client["uuid"]]).strip()
        ssid = s_name or active_client["name"]
        # 1. Read instantaneous zero-overhead cached link quality from kernel
        try:
            with open("/proc/net/wireless", "r") as f:
                for wline in f:
                    if ":" in wline:
                        wparts = wline.split()
                        qual_str = wparts[2].replace(".", "")
                        qual = int(qual_str)
                        signal = min(100, int((qual / 70.0) * 100))
                        break
        except Exception:
            pass
        # 2. Fallback to nmcli with --rescan no to guarantee NO 802.11 radio scan is triggered
        if signal == 0:
            sig_out = run_cmd(["nmcli", "-t", "--rescan", "no", "-f", "IN-USE,SIGNAL", "dev", "wifi", "list"])
            for s_line in sig_out.splitlines():
                if s_line.startswith("*"):
                    try:
                        signal = int(s_line.split(":")[1])
                    except Exception:
                        signal = 80
                    break
        if signal == 0:
            signal = 80

    return {
        "wifi_enabled": radio_on,
        "connected": connected,
        "ssid": ssid,
        "signal": signal,
        "hotspot": hs_info
    }

def toggle_wifi(target="toggle"):
    active_hotspot, active_client = get_active_wireless()
    radio_out = run_cmd(["nmcli", "radio", "wifi"]).strip()
    radio_on = (radio_out == "enabled")
    current_wifi_on = radio_on and (active_hotspot is None)

    if target == "toggle":
        target = "off" if current_wifi_on else "on"

    if target == "on":
        # Turning Wi-Fi on must turn off Hotspot on single-adapter system
        if active_hotspot:
            run_cmd(["nmcli", "connection", "down", active_hotspot["uuid"]])
            time.sleep(0.3)
        run_cmd(["nmcli", "connection", "down", "Hotspot"])
        # Guarantee Hotspot is never autoconnected
        run_cmd(["nmcli", "connection", "modify", "Hotspot", "connection.autoconnect", "no", "connection.autoconnect-priority", "-999"])
        run_cmd(["nmcli", "radio", "wifi", "on"])
        time.sleep(0.2)
        best = get_best_saved_client_wifi()
        if best:
            run_cmd(["nmcli", "connection", "up", "uuid", best[1]])
        else:
            wlan = get_wlan_device()
            run_cmd(["nmcli", "dev", "connect", wlan])
    else:
        # Turning Wi-Fi off turns off both client and AP
        if active_hotspot:
            run_cmd(["nmcli", "connection", "down", active_hotspot["uuid"]])
            time.sleep(0.2)
        run_cmd(["nmcli", "radio", "wifi", "off"])

    time.sleep(0.6)
    return get_status()

def toggle_hotspot(target="toggle"):
    active_hotspot, active_client = get_active_wireless()
    current_hs_on = (active_hotspot is not None)
    if target == "toggle":
        target = "off" if current_hs_on else "on"

    if target == "on":
        # Turning Hotspot on must turn off client Wi-Fi
        if active_client:
            run_cmd(["nmcli", "connection", "down", active_client["uuid"]])
            time.sleep(0.2)
        run_cmd(["nmcli", "radio", "wifi", "on"])
        time.sleep(0.2)

        # Retrieve authoritative credentials from plasma-nm
        hs_info = get_hotspot_info()
        ssid = hs_info["ssid"]
        password = hs_info["password"]

        # Ensure Hotspot profile exists with autoconnect explicitly disabled
        conns = run_cmd(["nmcli", "-t", "-f", "NAME,UUID", "c", "show"])
        has_hs_profile = False
        for line in conns.splitlines():
            if line.startswith("Hotspot:"):
                has_hs_profile = True
                break
        wlan = get_wlan_device()
        if not has_hs_profile:
            run_cmd(["nmcli", "connection", "add", "type", "wifi", "ifname", wlan or "*",
                     "con-name", "Hotspot", "autoconnect", "no", "ssid", ssid,
                     "802-11-wireless.mode", "ap",
                     "802-11-wireless-security.key-mgmt", "wpa-psk",
                     "802-11-wireless-security.psk", password,
                     "ipv4.method", "shared"])
        else:
            run_cmd(["nmcli", "connection", "modify", "Hotspot",
                     "802-11-wireless.ssid", ssid,
                     "802-11-wireless-security.psk", password,
                     "connection.autoconnect", "no",
                     "connection.autoconnect-priority", "-999"])
        # Always enforce autoconnect = no and low priority before bringing up
        run_cmd(["nmcli", "connection", "modify", "Hotspot", "connection.autoconnect", "no", "connection.autoconnect-priority", "-999"])
        run_cmd(["nmcli", "connection", "up", "Hotspot"])
    else:
        # Turning Hotspot off must restore client Wi-Fi connection
        if active_hotspot:
            run_cmd(["nmcli", "connection", "down", active_hotspot["uuid"]])
            time.sleep(0.3)
        run_cmd(["nmcli", "connection", "down", "Hotspot"])
        run_cmd(["nmcli", "connection", "modify", "Hotspot", "connection.autoconnect", "no", "connection.autoconnect-priority", "-999"])
        run_cmd(["nmcli", "radio", "wifi", "on"])
        time.sleep(0.2)
        best = get_best_saved_client_wifi()
        if best:
            run_cmd(["nmcli", "connection", "up", "uuid", best[1]])
        else:
            wlan = get_wlan_device()
            run_cmd(["nmcli", "dev", "connect", wlan])

    time.sleep(0.6)
    return get_status()

def set_hotspot_credentials(new_ssid, new_password):
    if not new_ssid or not new_ssid.strip():
        return {"success": False, "error": "SSID cannot be empty"}
    new_ssid = new_ssid.strip()

    if not new_password or len(new_password) < 8:
        return {"success": False, "error": "Password must be at least 8 characters"}

    # 1. Update KDE Plasma Global Settings (~/.config/plasma-nm)
    write_plasma_nm_hotspot(new_ssid, new_password)

    # 2. Update NetworkManager profile
    conns = run_cmd(["nmcli", "-t", "-f", "NAME,UUID", "c", "show"])
    has_hs_profile = False
    for line in conns.splitlines():
        if line.startswith("Hotspot:"):
            has_hs_profile = True
            break

    wlan = get_wlan_device()
    if not has_hs_profile:
        run_cmd(["nmcli", "connection", "add", "type", "wifi", "ifname", wlan or "*",
                 "con-name", "Hotspot", "autoconnect", "no", "ssid", new_ssid,
                 "802-11-wireless.mode", "ap",
                 "802-11-wireless-security.key-mgmt", "wpa-psk",
                 "802-11-wireless-security.psk", new_password,
                 "ipv4.method", "shared"])
    else:
        run_cmd(["nmcli", "connection", "modify", "Hotspot",
                 "802-11-wireless.ssid", new_ssid,
                 "802-11-wireless-security.psk", new_password,
                 "connection.autoconnect", "no",
                 "connection.autoconnect-priority", "-999"])

    # 3. If Hotspot is currently active, re-apply/reactivate so the new SSID/password take effect immediately
    active_hotspot, _ = get_active_wireless()
    if active_hotspot:
        run_cmd(["nmcli", "connection", "up", "Hotspot"])

    time.sleep(0.3)
    return get_status()

def list_wifi(rescan=False):
    active_hotspot, active_client = get_active_wireless()
    # While hotspot is actively running on single adapter, Wi-Fi scanning is not available
    if active_hotspot:
        return []

    rescan_args = ["--rescan", "yes"] if rescan else ["--rescan", "auto"]
    lines = run_cmd(["nmcli", "-t"] + rescan_args + ["-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"])
    if not lines.strip():
        lines = run_cmd(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"])

    hs_info = get_hotspot_info()
    hs_ssid = hs_info["ssid"].lower()

    active_client_ssid = ""
    if active_client:
        active_client_ssid = run_cmd(["nmcli", "-g", "802-11-wireless.ssid", "c", "show", active_client["uuid"]]).strip() or active_client["name"]

    seen = {}
    for line in lines.splitlines():
        parts = line.split(":")
        if len(parts) >= 4:
            in_use = (parts[0] == "*")
            ssid = parts[1].strip()
            if not ssid:
                continue
            # NEVER show own hotspot in the list of Wi-Fi networks to connect to
            if ssid.lower() == hs_ssid or "hotspot" in ssid.lower():
                continue
            try:
                sig = int(parts[2])
            except Exception:
                sig = 50
            sec = parts[3].strip() or "None"

            # True active check
            is_really_active = in_use or (active_client_ssid != "" and ssid == active_client_ssid)

            if ssid not in seen or is_really_active or sig > seen[ssid]["signal"]:
                seen[ssid] = {
                    "ssid": ssid,
                    "signal": sig,
                    "security": sec,
                    "active": is_really_active
                }

    # Guarantee active connected Wi-Fi always appears in the list
    if active_client_ssid and active_client_ssid not in seen:
        seen[active_client_ssid] = {
            "ssid": active_client_ssid,
            "signal": 80,
            "security": "WPA2",
            "active": True
        }

    res = list(seen.values())
    res.sort(key=lambda x: (not x["active"], -x["signal"]))
    return res

def connect_wifi(target_ssid, password=None):
    if not target_ssid:
        return {"success": False, "error": "No SSID provided"}
    active_hotspot, active_client = get_active_wireless()
    # If hotspot is active, turn it down before connecting to Wi-Fi
    if active_hotspot:
        run_cmd(["nmcli", "connection", "down", active_hotspot["uuid"]])
        time.sleep(0.3)
    run_cmd(["nmcli", "radio", "wifi", "on"])
    time.sleep(0.2)
    if password:
        run_cmd(["nmcli", "dev", "wifi", "connect", target_ssid, "password", password])
    else:
        run_cmd(["nmcli", "dev", "wifi", "connect", target_ssid])
    time.sleep(0.6)
    return get_status()

def open_hotspot_settings():
    if os.path.exists("/usr/bin/kcmshell6"):
        subprocess.Popen(["kcmshell6", "kcm_mobile_hotspot"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    elif os.path.exists("/usr/bin/systemsettings"):
        subprocess.Popen(["systemsettings", "kcm_mobile_hotspot"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    elif os.path.exists("/usr/bin/plasma-open-settings"):
        subprocess.Popen(["plasma-open-settings", "kcm_mobile_hotspot"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return {"success": True}

# Router
if cmd == "status":
    print(json.dumps(get_status()))
elif cmd == "toggle":
    print(json.dumps(toggle_wifi(arg2 or "toggle")))
elif cmd == "list_wifi":
    do_rescan = (arg2 == "rescan" or arg2 == "true")
    print(json.dumps(list_wifi(do_rescan)))
elif cmd == "connect":
    print(json.dumps(connect_wifi(arg2, arg3 if arg3 else None)))
elif cmd == "hotspot_status":
    print(json.dumps(get_hotspot_info(get_active_wireless()[0])))
elif cmd == "toggle_hotspot":
    print(json.dumps(toggle_hotspot(arg2 or "toggle")))
elif cmd == "set_hotspot_credentials":
    print(json.dumps(set_hotspot_credentials(arg2, arg3)))
elif cmd == "open_hotspot_settings":
    print(json.dumps(open_hotspot_settings()))
else:
    print(json.dumps({"error": f"Unknown command: {cmd}"}))
PYEOF
