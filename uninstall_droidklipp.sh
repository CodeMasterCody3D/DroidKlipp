#!/bin/bash

USER_NAME=$(whoami)
HOME_DIR="/home/$USER_NAME"

if [ "$USER_NAME" == "root" ]; then
    echo "Please do not run the script as root. Run it as your normal user."
    exit 1
fi

echo "--- DroidKlipp Uninstaller ---"

# Stop current and legacy DroidKlipp services.
for svc in adb_monitor.service droidklipp_wifi.service; do
    if systemctl list-unit-files "$svc" &>/dev/null; then
        echo "Stopping $svc..."
        sudo systemctl stop "$svc" 2>/dev/null || true
        sudo systemctl disable "$svc" 2>/dev/null || true
    fi
done

# Kill KlipperScreen sessions started by DroidKlipp.
for session in klipperscreen klipperscreen_wifi; do
    if tmux has-session -t "$session" 2>/dev/null; then
        echo "Killing tmux session: $session"
        tmux kill-session -t "$session" 2>/dev/null || true
    fi
done

# Remove installed DroidKlipp files, legacy monitors, and WiFi fallback cache.
for f in \
    "/etc/systemd/system/adb_monitor.service" \
    "/etc/systemd/system/droidklipp_wifi.service" \
    "/etc/udev/rules.d/99-droidklipp.rules" \
    "/usr/local/bin/droidklipp_udev.sh" \
    "$HOME_DIR/droidklipp_monitor.py" \
    "$HOME_DIR/adb_monitor.py" \
    "$HOME_DIR/droidklipp_wifi_monitor.py" \
    "$HOME_DIR/start_klipperscreen.sh" \
    "$HOME_DIR/.droidklipp_wifi_ip"
do
    if [ -e "$f" ]; then
        sudo rm -f "$f"
        echo "Deleted: $f"
    fi
done

sudo systemctl daemon-reload
sudo udevadm control --reload-rules 2>/dev/null || true

# Remove any stale ADB XSDL forward created by DroidKlipp.
adb forward --remove tcp:6100 2>/dev/null || true

echo "-------------------------------------------------------"
echo "DroidKlipp removed, including WiFi fallback setup."
echo "KlipperScreen and its virtualenv were left intact."
echo "-------------------------------------------------------"
