#!/bin/bash

# Get current environment info
USER_NAME=$(whoami)
HOME_DIR="/home/$USER_NAME"

echo "--- DroidKlipp WiFi Add-in Uninstaller ---"

# 1. Stop and Disable the systemd service
echo "Stopping and disabling droidklipp_wifi.service..."
sudo systemctl stop droidklipp_wifi.service 2>/dev/null
sudo systemctl disable droidklipp_wifi.service 2>/dev/null

# 2. Kill any active WiFi tmux sessions
if tmux has-session -t klipperscreen_wifi 2>/dev/null; then
    echo "Closing active WiFi KlipperScreen session..."
    tmux kill-session -t klipperscreen_wifi
fi

# 3. Remove the files
echo "Removing scripts and configuration files..."

# Remove the Python monitor script
if [ -f "$HOME_DIR/droidklipp_wifi_monitor.py" ]; then
    rm "$HOME_DIR/droidklipp_wifi_monitor.py"
    echo "Deleted: $HOME_DIR/droidklipp_wifi_monitor.py"
fi

# Remove the Systemd service file
if [ -f "/etc/systemd/system/droidklipp_wifi.service" ]; then
    sudo rm "/etc/systemd/system/droidklipp_wifi.service"
    echo "Deleted: /etc/systemd/system/droidklipp_wifi.service"
fi

# 4. Reload system daemons
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "-------------------------------------------------------"
echo "Uninstallation Complete."
echo "The WiFi Polling Add-in has been removed."
echo "Your core DroidKlipp USB installation is still intact."
echo "-------------------------------------------------------"
