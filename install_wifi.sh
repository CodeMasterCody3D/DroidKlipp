#!/bin/bash

USER_NAME=$(whoami)
HOME_DIR="/home/$USER_NAME"

if [ "$USER_NAME" == "root" ]; then
    echo "Please do not run the script as root. Run it as your normal user."
    exit 1
fi

echo "--- DroidKlipp WiFi Setup ---"

IP_CACHE="$HOME_DIR/.droidklipp_wifi_ip"

# Detect WiFi IP from a connected USB device.
DETECTED_IP=$(adb shell ip addr show wlan0 2>/dev/null | grep -oP 'inet \K[0-9.]+' | head -n1)
if [ -n "$DETECTED_IP" ]; then
    echo "$DETECTED_IP" > "$IP_CACHE"
    echo "Detected Android WiFi IP: $DETECTED_IP (cached)"
else
    echo "No USB device detected."
    read -p "Enter the Android device IP manually (or press Enter to skip): " MANUAL_IP
    if [ -n "$MANUAL_IP" ]; then
        echo "$MANUAL_IP" > "$IP_CACHE"
        echo "Cached IP: $MANUAL_IP"
    fi
fi

# Restart the monitor so it picks up the new IP immediately.
if systemctl is-active --quiet adb_monitor.service; then
    echo "Restarting adb_monitor.service..."
    sudo systemctl restart adb_monitor.service
    echo "Monitor restarted with new IP."
else
    echo "Note: adb_monitor.service is not running. Run droidklipp.sh first."
fi

CACHED=$(cat "$IP_CACHE" 2>/dev/null || echo "(none)")
echo "-------------------------------------------------------"
echo "WiFi setup complete."
echo "  Cached IP : $CACHED"
echo "  KlipperScreen always uses DISPLAY=$CACHED:0"
echo "  USB changes no longer cause a KlipperScreen restart."
echo "-------------------------------------------------------"
