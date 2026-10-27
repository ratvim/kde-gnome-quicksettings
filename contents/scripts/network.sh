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

def get_hotspot_info(active_hotspot=None):
    hs_ssid = ""
    hs_pass = ""
    target_hs = active_hotspot["uuid"] if active_hotspot else "Hotspot"
    try:
        s_out = run_cmd(["nmcli", "-s", "-g", "802-11-wireless.ssid,802-11-wireless-security.psk", "c", "show", target_hs]).splitlines()
        if len(s_out) >= 1: hs_ssid = s_out[0].strip()
        if len(s_out) >= 2: hs_pass = s_out[1].strip()
    except Exception:
        pass
    if not hs_ssid:
        try:
            h = socket.gethostname()
        except Exception:
            h = "Linux"
        hs_ssid = f"{h}-Hotspot"
    return {
        "hotspot_enabled": active_hotspot is not None,
        "ssid": hs_ssid,
        "password": hs_pass,
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
        # Ensure Hotspot profile exists with autoconnect explicitly disabled
        conns = run_cmd(["nmcli", "-t", "-f", "NAME,UUID", "c", "show"])
        has_hs_profile = False
        for line in conns.splitlines():
            if line.startswith("Hotspot:"):
                has_hs_profile = True
                break
        if not has_hs_profile:
            wlan = get_wlan_device()
            try:
                h = socket.gethostname()
            except Exception:
                h = "Linux"
            ssid = f"{h}-Hotspot"
            run_cmd(["nmcli", "connection", "add", "type", "wifi", "ifname", wlan or "*",
                     "con-name", "Hotspot", "autoconnect", "no", "ssid", ssid,
                     "802-11-wireless.mode", "ap",
                     "802-11-wireless-security.key-mgmt", "wpa-psk",
                     "802-11-wireless-security.psk", "hotspot12345",
                     "ipv4.method", "shared"])
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
elif cmd == "open_hotspot_settings":
    print(json.dumps(open_hotspot_settings()))
else:
    print(json.dumps({"error": f"Unknown command: {cmd}"}))
PYEOF
