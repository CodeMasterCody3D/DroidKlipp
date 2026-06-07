#!/bin/bash

USER_NAME=$(whoami)
HOME_DIR="/home/$USER_NAME"

echo "--- DroidKlipp WiFi Setup Uninstaller ---"

# Kill the WiFi KlipperScreen session (monitor will auto-restart if still running)
if tmux has-session -t klipperscreen_wifi 2>/dev/null; then
    echo "Closing WiFi KlipperScreen session..."
    tmux kill-session -t klipperscreen_wifi
fi

# Remove cached IP
if [ -f "$HOME_DIR/.droidklipp_wifi_ip" ]; then
    rm "$HOME_DIR/.droidklipp_wifi_ip"
    echo "Deleted: $HOME_DIR/.droidklipp_wifi_ip"
fi

# Remove legacy standalone WiFi monitor if it exists
if [ -f "$HOME_DIR/droidklipp_wifi_monitor.py" ]; then
    rm "$HOME_DIR/droidklipp_wifi_monitor.py"
    echo "Deleted: $HOME_DIR/droidklipp_wifi_monitor.py"
fi

# Remove legacy standalone WiFi service if it exists
if systemctl list-unit-files droidklipp_wifi.service &>/dev/null; then
    echo "Removing legacy droidklipp_wifi.service..."
    sudo systemctl stop droidklipp_wifi.service 2>/dev/null
    sudo systemctl disable droidklipp_wifi.service 2>/dev/null
    sudo rm -f "/etc/systemd/system/droidklipp_wifi.service"
    sudo systemctl daemon-reload
fi

echo "-------------------------------------------------------"
echo "WiFi setup removed. adb_monitor.service still running."
echo "-------------------------------------------------------"
