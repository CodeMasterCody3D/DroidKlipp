#!/bin/bash

USER_NAME=$(whoami)

if [ "$USER_NAME" == "root" ]; then
    echo "Please do not run the script as root. Run it as your normal user."
    exit 1
fi

# Remove legacy separate WiFi service if present.
for svc in droidklipp_wifi.service; do
    if systemctl list-unit-files "$svc" &>/dev/null; then
        echo "Removing legacy $svc..."
        sudo systemctl stop "$svc" 2>/dev/null
        sudo systemctl disable "$svc" 2>/dev/null
    fi
done

# ── Step 1: udev rule — fires SIGUSR1 to monitor on any USB add/remove ───────
echo "Installing udev rule: 99-droidklipp.rules"
cat <<EOF | sudo tee /etc/udev/rules.d/99-droidklipp.rules > /dev/null
# DroidKlipp: signal the monitor immediately on USB connect/disconnect.
SUBSYSTEM=="usb", ACTION=="add",    RUN+="/usr/local/bin/droidklipp_udev.sh"
SUBSYSTEM=="usb", ACTION=="remove", RUN+="/usr/local/bin/droidklipp_udev.sh"
EOF
echo "Installing udev event script: /usr/local/bin/droidklipp_udev.sh"
cat <<EOF | sudo tee /usr/local/bin/droidklipp_udev.sh > /dev/null
#!/bin/bash
# Called by udev on USB add/remove. Wakes the DroidKlipp monitor immediately.
pkill -USR1 -u "$USER_NAME" -f "droidklipp_monitor.py" 2>/dev/null || true
EOF
sudo chmod +x /usr/local/bin/droidklipp_udev.sh
sudo udevadm control --reload-rules

# ── Step 2: Unified monitor ──────────────────────────────────────────────────
echo "Creating droidklipp_monitor.py..."
cat <<'EOF' | sudo -u $USER_NAME tee /home/$USER_NAME/droidklipp_monitor.py > /dev/null
#!/usr/bin/env python3
"""
DroidKlipp unified monitor.
  USB plugged in  → KlipperScreen on DISPLAY=:100  (USB tunnel, adb forward)
  USB unplugged   → KlipperScreen on DISPLAY=ip:0  (WiFi direct to XSDL)

Detection uses udev (instant) + 1s polling fallback.
udev fires SIGUSR1 → self-pipe wakes select() → immediate ADB check.
A 5s post-connect stability window ignores false disconnects from ADB commands.
GDK_BACKEND=x11 is set on all launches so GTK uses X11 even under Wayland.
"""

import datetime
import os
import re
import select
import signal
import socket
import subprocess
import threading
import time

HOME_DIR = os.environ.get("HOME", os.path.expanduser("~"))
IP_CACHE = os.path.join(HOME_DIR, ".droidklipp_wifi_ip")

POLL_INTERVAL      = 1.0   # fallback poll cadence (seconds)
XSDL_USB_PORT      = 6100  # local side of: adb forward tcp:6100 tcp:6000
XSDL_WIFI_PORT     = 6000  # direct WiFi port on the phone
KS_CRASH_COOLDOWN  = 3     # seconds before watchdog restarts a crashed KS
CONNECT_STABILITY  = 5     # ignore disconnects within this many seconds of a connect

# ── Signal wakeup (udev fires SIGUSR1 on USB events) ─────────────────────────
_wake_r, _wake_w = os.pipe()
os.set_blocking(_wake_w, False)
signal.set_wakeup_fd(_wake_w)

def _on_usb_event(signum, frame):
    pass  # set_wakeup_fd already wrote to _wake_w; main loop drains it

signal.signal(signal.SIGUSR1, _on_usb_event)

def log(msg):
    ts = datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]
    print(f"[{ts}] {msg}", flush=True)

# ── ADB ──────────────────────────────────────────────────────────────────────

def is_usb_connected():
    """Use adb get-state — much faster than adb devices, 1.5s timeout."""
    try:
        r = subprocess.run(
            ['adb', 'get-state'],
            capture_output=True, text=True, timeout=1.5
        )
        return r.returncode == 0 and r.stdout.strip() == 'device'
    except Exception:
        return False

def get_wlan_ip():
    try:
        r = subprocess.run(
            ['adb', 'shell', 'ip', 'addr', 'show', 'wlan0'],
            capture_output=True, text=True, timeout=5
        )
        m = re.search(r'inet (\d+\.\d+\.\d+\.\d+)', r.stdout)
        return m.group(1) if m else None
    except Exception:
        return None

def wake_phone():
    try:
        subprocess.run(
            ['adb', 'shell', 'input', 'keyevent', 'KEYCODE_WAKEUP'],
            capture_output=True, timeout=5
        )
    except Exception:
        pass

def ensure_xsdl():
    try:
        subprocess.run(
            ['adb', 'shell', 'am', 'start', '-n',
             'droidklipp.x.org.server/x.org.server.MainActivity'],
            capture_output=True, timeout=10
        )
    except Exception:
        pass

def setup_adb_forward():
    for _ in range(5):
        r = subprocess.run(
            ['adb', 'forward', 'tcp:6100', 'tcp:6000'], capture_output=True
        )
        if r.returncode == 0:
            return True
        time.sleep(1)
    log("ERROR: adb forward failed.")
    return False

# ── IP cache ─────────────────────────────────────────────────────────────────

def cache_ip(ip):
    try:
        with open(IP_CACHE, 'w') as f:
            f.write(ip)
    except Exception:
        pass

def read_cached_ip():
    try:
        with open(IP_CACHE) as f:
            return f.read().strip() or None
    except Exception:
        return None

def try_update_wifi_ip():
    ip = get_wlan_ip()
    if ip and ip != read_cached_ip():
        cache_ip(ip)
        log(f"WiFi IP updated: {ip}")
    return ip or read_cached_ip()

# ── Socket / X11 readiness ───────────────────────────────────────────────────

def port_open(host, port, timeout=1.0):
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except (socket.error, OSError):
        return False

def xsdl_x11_ready(display, max_wait=15):
    """Poll xdpyinfo until XSDL accepts a full X11 handshake (not just TCP)."""
    log(f"Waiting for XSDL X11 ready on {display}...")
    deadline = time.time() + max_wait
    while time.time() < deadline:
        r = subprocess.run(
            ['xdpyinfo', '-display', display],
            capture_output=True, timeout=3
        )
        if r.returncode == 0:
            log(f"XSDL X11 ready on {display}.")
            return True
        time.sleep(0.5)
    log(f"XSDL X11 not ready after {max_wait}s.")
    return False

def wait_for_port(host, port, max_wait=15, label=""):
    tag = label or f"{host}:{port}"
    log(f"Waiting for {tag}...")
    deadline = time.time() + max_wait
    while time.time() < deadline:
        if port_open(host, port, timeout=1.0):
            log(f"{tag} ready.")
            return True
        time.sleep(0.4)
    log(f"{tag} timed out after {max_wait}s.")
    return False

# ── KlipperScreen sessions ────────────────────────────────────────────────────

def tmux_session_exists(name):
    return subprocess.run(
        ['tmux', 'has-session', '-t', name], capture_output=True
    ).returncode == 0

def kill_tmux(name):
    subprocess.run(['tmux', 'kill-session', '-t', name], capture_output=True)

def kill_all_ks():
    subprocess.run(['pkill', '-f', 'KlipperScreen'], capture_output=True)
    subprocess.run(['pkill', '-f', 'screen.py'], capture_output=True)
    for s in ('klipperscreen', 'klipperscreen_wifi'):
        if tmux_session_exists(s):
            kill_tmux(s)
    time.sleep(0.8)

def ks_usb_running():
    return tmux_session_exists('klipperscreen')

def ks_wifi_running():
    return tmux_session_exists('klipperscreen_wifi')

_VENV_PY  = f"{HOME_DIR}/.KlipperScreen-env/bin/python"
_SCREEN   = f"{HOME_DIR}/KlipperScreen/screen.py"

def launch_ks_usb():
    if ks_usb_running():
        return
    log("Launching KlipperScreen → DISPLAY=:100 (USB)")
    cmd = f'tmux new-session -d -s klipperscreen "GDK_BACKEND=x11 DISPLAY=:100 {_VENV_PY} {_SCREEN}"'
    subprocess.run(cmd, shell=True)

def launch_ks_wifi(ip):
    if ks_wifi_running():
        return
    log(f"Launching KlipperScreen → DISPLAY={ip}:0 (WiFi)")
    cmd = f'tmux new-session -d -s klipperscreen_wifi "GDK_BACKEND=x11 DISPLAY={ip}:0 {_VENV_PY} {_SCREEN}"'
    subprocess.run(cmd, shell=True)

# ── Mode switches ─────────────────────────────────────────────────────────────

def switch_to_usb():
    log("Switching to USB mode...")
    kill_all_ks()
    wake_phone()
    ensure_xsdl()
    if not setup_adb_forward():
        return False
    if wait_for_port('localhost', XSDL_USB_PORT, max_wait=15, label="XSDL via USB"):
        launch_ks_usb()
        return True
    log("XSDL did not respond on USB — watchdog will retry.")
    return False

def switch_to_wifi(ip):
    log(f"Switching to WiFi mode ({ip})...")
    if xsdl_x11_ready(f"{ip}:0", max_wait=15):
        launch_ks_wifi(ip)
    else:
        log("XSDL X11 not ready — watchdog will retry.")
        return
    def _cleanup_usb():
        time.sleep(2)
        kill_tmux('klipperscreen')
    threading.Thread(target=_cleanup_usb, daemon=True).start()

# ── Main loop ────────────────────────────────────────────────────────────────

def main():
    last_usb            = False
    last_connected_time = 0.0
    last_ks_launch      = 0.0
    ip_tick             = 0

    log("DroidKlipp monitor started.")
    log(f"  USB → DISPLAY=:100  |  no USB → DISPLAY=<ip>:0")
    log(f"  udev instant wakeup + {POLL_INTERVAL}s fallback poll")

    while True:
        r, _, _ = select.select([_wake_r], [], [], POLL_INTERVAL)
        if r:
            os.read(_wake_r, 64)
            log("USB event (udev) → checking ADB...")
            time.sleep(0.3)

        t0 = time.monotonic()
        usb = is_usb_connected()
        elapsed = time.monotonic() - t0
        if elapsed > 0.5:
            log(f"  adb get-state took {elapsed:.2f}s")
        ip = read_cached_ip()

        if usb and not last_usb:
            last_connected_time = time.time()
            log("USB connected.")
            ip = try_update_wifi_ip() or ip
            switch_to_usb()
            last_ks_launch = time.time()

        elif not usb and last_usb:
            age = time.time() - last_connected_time
            if age < CONNECT_STABILITY:
                log(f"USB blip ignored ({age:.1f}s after connect, within {CONNECT_STABILITY}s window).")
                usb = True
            else:
                log("USB disconnected.")
                if ip:
                    switch_to_wifi(ip)
                else:
                    log("No cached WiFi IP — run install_wifi.sh or rerun install_droidklipp.sh to set one.")
                last_ks_launch = time.time()

        elif usb:
            ip_tick += 1
            if ip_tick >= 30:
                ip = try_update_wifi_ip() or ip
                ip_tick = 0

        now = time.time()
        if (now - last_ks_launch) >= KS_CRASH_COOLDOWN:
            if usb and not ks_usb_running() and port_open('localhost', XSDL_USB_PORT):
                log("KlipperScreen (USB) crashed — restarting.")
                launch_ks_usb()
                last_ks_launch = now
            elif not usb and ip and not ks_wifi_running() and port_open(ip, XSDL_WIFI_PORT):
                log("KlipperScreen (WiFi) crashed — restarting.")
                launch_ks_wifi(ip)
                last_ks_launch = now

        last_usb = usb


if __name__ == "__main__":
    main()
EOF
# ── Step 3: start_klipperscreen.sh (manual helper) ───────────────────────────
echo "Creating start_klipperscreen.sh..."
cat <<'EOF' | sudo -u $USER_NAME tee /home/$USER_NAME/start_klipperscreen.sh > /dev/null
#!/bin/bash
# Manual helper: wake phone + set up USB forward.
# The monitor handles KlipperScreen automatically.

MAX_RETRIES=5
echo "Waiting for ADB device..."
for i in $(seq 1 $MAX_RETRIES); do
    if adb devices | grep -q $'\tdevice'; then
        echo "ADB device ready."
        break
    fi
    echo "  Attempt $i/$MAX_RETRIES..."
    sleep 2
    [ "$i" -eq "$MAX_RETRIES" ] && { echo "No ADB device. Aborting."; exit 1; }
done

adb forward tcp:6100 tcp:6000
adb shell input keyevent KEYCODE_WAKEUP
sleep 1
adb shell am start -n droidklipp.x.org.server/x.org.server.MainActivity
echo "Phone ready. Monitor will launch KlipperScreen automatically."
EOF
sudo chmod +x /home/$USER_NAME/droidklipp_monitor.py
sudo chmod +x /home/$USER_NAME/start_klipperscreen.sh

# ── Step 4: Systemd service ──────────────────────────────────────────────────
echo "Creating adb_monitor.service..."
cat <<EOF | sudo tee /etc/systemd/system/adb_monitor.service > /dev/null
[Unit]
Description=DroidKlipp Unified Monitor (USB + WiFi)
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/$USER_NAME/droidklipp_monitor.py
WorkingDirectory=/home/$USER_NAME
Restart=always
RestartSec=3
User=$USER_NAME
Environment=HOME=/home/$USER_NAME

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable adb_monitor.service

# ── Step 5: WiFi fallback setup ───────────────────────────────────────────────
echo "Configuring DroidKlipp WiFi fallback..."
HOME_DIR="/home/$USER_NAME"
IP_CACHE="$HOME_DIR/.droidklipp_wifi_ip"

# Detect WiFi IP from a connected USB device. If unavailable, allow manual entry.
DETECTED_IP=$(adb shell ip addr show wlan0 2>/dev/null | grep -oP 'inet \K[0-9.]+' | head -n1)
if [ -n "$DETECTED_IP" ]; then
    echo "$DETECTED_IP" > "$IP_CACHE"
    echo "Detected Android WiFi IP: $DETECTED_IP (cached)"
else
    echo "No Android WiFi IP detected over USB."
    read -p "Enter the Android device IP manually (or press Enter to skip): " MANUAL_IP
    if [ -n "$MANUAL_IP" ]; then
        echo "$MANUAL_IP" > "$IP_CACHE"
        echo "Cached IP: $MANUAL_IP"
    else
        echo "No WiFi IP cached. USB mode will still work; run install_wifi.sh later to add WiFi fallback."
    fi
fi

sudo systemctl restart adb_monitor.service

echo "-------------------------------------------------------"
echo "DroidKlipp installed."
echo "  udev rule  : /etc/udev/rules.d/99-droidklipp.rules"
echo "  udev script: /usr/local/bin/droidklipp_udev.sh"
CACHED=$(cat "$IP_CACHE" 2>/dev/null || echo "(none)")
echo "  WiFi IP    : $CACHED"
echo "  USB events now detected instantly (no polling delay)"
echo "-------------------------------------------------------"
