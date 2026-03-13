#!/bin/bash

# Get the username of the current user
USER_NAME=$(whoami)
HOME_DIR="/home/$USER_NAME"

# Ensure that the script runs as the correct user
if [ "$USER_NAME" == "root" ]; then
    echo "Please do not run the script as root. Run it as your normal user."
    exit 1
fi

echo "--- DroidKlipp Core Uninstaller ---"

# Step 1: Stop and disable the systemd service
echo "Stopping and disabling adb_monitor.service..."
sudo systemctl stop adb_monitor.service 2>/dev/null
sudo systemctl disable adb_monitor.service 2>/dev/null

# Step 2: Kill any active KlipperScreen tmux sessions
if tmux has-session -t klipperscreen 2>/dev/null; then
    echo "Closing active KlipperScreen tmux session..."
    tmux kill-session -t klipperscreen
fi

# Step 3: Remove the created files
echo "Removing DroidKlipp core files..."

# Remove the systemd service file
if [ -f "/etc/systemd/system/adb_monitor.service" ]; then
    sudo rm "/etc/systemd/system/adb_monitor.service"
    echo "Deleted: /etc/systemd/system/adb_monitor.service"
fi

# Remove the Python monitor script
if [ -f "$HOME_DIR/adb_monitor.py" ]; then
    rm "$HOME_DIR/adb_monitor.py"
    echo "Deleted: $HOME_DIR/adb_monitor.py"
fi

# Remove the startup shell script
if [ -f "$HOME_DIR/start_klipperscreen.sh" ]; then
    rm "$HOME_DIR/start_klipperscreen.sh"
    echo "Deleted: $HOME_DIR/start_klipperscreen.sh"
fi

# Step 4: Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "-------------------------------------------------------"
echo "DroidKlipp core components have been removed."
echo "Note: This did not remove the KlipperScreen directory"
echo "or the virtual environment to preserve your settings."
echo "-------------------------------------------------------"
