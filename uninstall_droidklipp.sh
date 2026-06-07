#!/bin/bash

USER_NAME=$(whoami)
HOME_DIR="/home/$USER_NAME"

if [ "$USER_NAME" == "root" ]; then
    echo "Please do not run the script as root. Run it as your normal user."
    exit 1
fi

echo "--- DroidKlipp Uninstaller ---"

for svc in adb_monitor.service droidklipp_wifi.service; do
    if systemctl list-unit-files "$svc" &>/dev/null; then
        echo "Stopping $svc..."
        sudo systemctl stop "$svc" 2>/dev/null
        sudo systemctl disable "$svc" 2>/dev/null
    fi
done

for session in klipperscreen klipperscreen_wifi; do
    if tmux has-session -t "$session" 2>/dev/null; then
        echo "Killing tmux session: $session"
        tmux kill-session -t "$session"
    fi
done

for f in \
    "/etc/systemd/system/adb_monitor.service" \
    "/etc/systemd/system/droidklipp_wifi.service" \
    "$HOME_DIR/droidklipp_monitor.py" \
    "$HOME_DIR/adb_monitor.py" \
    "$HOME_DIR/droidklipp_wifi_monitor.py" \
    "$HOME_DIR/start_klipperscreen.sh"
do
    if [ -f "$f" ]; then
        sudo rm "$f"
        echo "Deleted: $f"
    fi
done

sudo systemctl daemon-reload

echo "-------------------------------------------------------"
echo "DroidKlipp removed. KlipperScreen and virtualenv intact."
echo "-------------------------------------------------------"
