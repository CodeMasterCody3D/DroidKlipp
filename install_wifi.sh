#!/bin/bash

USER_NAME=$(whoami)
HOME_DIR="/home/$USER_NAME"

echo "--- DroidKlipp WiFi Polling Installer ---"
read -p "Enter the IP address of your Android Device (XSDL): " DEVICE_IP

# 1. Create the Polling Python Script
cat <<EOF > $HOME_DIR/droidklipp_wifi_monitor.py
import subprocess
import time
import os

TARGET_IP = "$DEVICE_IP"

def is_adb_connected():
    try:
        # We check for any device (USB or WiFi) already in the list
        result = subprocess.run(['adb', 'devices'], capture_output=True, text=True)
        devices = [line for line in result.stdout.splitlines()[1:] if '\tdevice' in line]
        return len(devices) > 0
    except Exception:
        return False

def is_tmux_running():
    # Check if the WiFi tmux session is already active
    result = subprocess.run(['tmux', 'has-session', '-t', 'klipperscreen_wifi'], capture_output=True)
    return result.returncode == 0

def main():
    print(f"Monitoring for ADB devices... (Target WiFi: {TARGET_IP})")
    while True:
        if not is_adb_connected():
            if not is_tmux_running():
                print("No ADB device detected. Launching WiFi Remote Display...")
                # The One-Liner
                cmd = (
                    f"tmux new-session -d -s klipperscreen_wifi "
                    f"\"export DISPLAY={TARGET_IP}:0 && "
                    f"source $HOME_DIR/.KlipperScreen-env/bin/activate && "
                    f"python3 $HOME_DIR/KlipperScreen/screen.py\""
                )
                subprocess.run(cmd, shell=True)
        else:
            # If an ADB device is found, we make sure the WiFi tmux is closed
            # to let the core DroidKlipp USB script take over.
            if is_tmux_running():
                print("ADB device detected. Closing WiFi session.")
                subprocess.run(['tmux', 'kill-session', '-t', 'klipperscreen_wifi'])
        
        time.sleep(3)

if __name__ == "__main__":
    main()
EOF

chmod +x $HOME_DIR/droidklipp_wifi_monitor.py

# 2. Create the Systemd Service
SERVICE_FILE="/etc/systemd/system/droidklipp_wifi.service"
sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=DroidKlipp WiFi Polling Monitor
After=network.target

[Service]
ExecStart=/usr/bin/python3 $HOME_DIR/droidklipp_wifi_monitor.py
WorkingDirectory=$HOME_DIR
Restart=always
User=$USER_NAME
Environment=HOME=$HOME_DIR

[Install]
WantedBy=multi-user.target
EOF"

# 3. Start the service
echo "Starting the WiFi Polling service..."
sudo systemctl daemon-reload
sudo systemctl enable droidklipp_wifi.service
sudo systemctl start droidklipp_wifi.service

echo "-------------------------------------------------------"
echo "Success! Polling every 3 seconds."
echo "If you unplug the USB, KlipperScreen will move to $DEVICE_IP"
echo "If you plug the USB back in, the WiFi session will close."
echo "-------------------------------------------------------"
