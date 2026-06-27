#!/bin/bash

USER_NAME=$(whoami)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$USER_NAME" == "root" ]; then
    echo "Please do not run the script as root. Run it as your normal user."
    exit 1
fi

APK_URL="https://github.com/CodeMasterCody3D/DroidKlipp-Android-APK/releases/latest/download/DroidKlipp.apk"

# Install DroidKlipp host prerequisites. x11-utils provides xdpyinfo.
echo "Installing DroidKlipp prerequisites: adb tmux x11-utils"
if ! sudo apt update || ! sudo apt install -y adb tmux x11-utils; then
    echo "Failed to install DroidKlipp prerequisites. Aborting."
    exit 1
fi

missing_commands=()
for cmd in adb tmux xdpyinfo systemctl udevadm python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing_commands+=("$cmd")
    fi
done

if [ "${#missing_commands[@]}" -gt 0 ]; then
    echo "Missing required commands: ${missing_commands[*]}"
    echo "Install prerequisites first:"
    echo "  sudo apt update && sudo apt install adb tmux x11-utils"
    exit 1
fi

if [ ! -x "/home/$USER_NAME/.KlipperScreen-env/bin/python" ] || [ ! -f "/home/$USER_NAME/KlipperScreen/screen.py" ]; then
    echo "WARNING: KlipperScreen was not found in the expected KIAUH v6 paths:"
    echo "  /home/$USER_NAME/.KlipperScreen-env/bin/python"
    echo "  /home/$USER_NAME/KlipperScreen/screen.py"
    echo "Install KlipperScreen with KIAUH v6 before using DroidKlipp."
fi

cat <<EOF
-------------------------------------------------------
DroidKlipp Android APK required:
  $APK_URL
Install it on Android before expecting the display to launch.
-------------------------------------------------------
EOF

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
echo "Deploying droidklipp_monitor.py from $SCRIPT_DIR ..."
install -m 755 "$SCRIPT_DIR/droidklipp_monitor.py" "/home/$USER_NAME/droidklipp_monitor.py"
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
echo "  Android APK: $APK_URL"
echo "  udev rule  : /etc/udev/rules.d/99-droidklipp.rules"
echo "  udev script: /usr/local/bin/droidklipp_udev.sh"
CACHED=$(cat "$IP_CACHE" 2>/dev/null || echo "(none)")
echo "  WiFi IP    : $CACHED"
echo "  USB events now detected instantly (no polling delay)"
echo "-------------------------------------------------------"
