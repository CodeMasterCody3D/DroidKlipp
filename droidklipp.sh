#!/bin/bash

# Get the username of the current user
USER_NAME=$(whoami)

# Ensure that the script runs as the correct user
if [ "$USER_NAME" == "root" ]; then
    echo "Please do not run the script as root. Run it as your normal user."
    exit 1
fi

# Step 1: Create the Python script (adb_monitor.py)
echo "Creating the Python script: adb_monitor.py"
cat <<EOF | sudo -u $USER_NAME tee /home/$USER_NAME/adb_monitor.py > /dev/null
import os
import subprocess
import time

def check_adb_devices():
    """Check for connected ADB devices."""
    try:
        result = subprocess.run(['adb', 'devices'], capture_output=True, text=True)
        # Filter for lines that contain '\tdevice', indicating a connected device
        devices = [line.split()[0] for line in result.stdout.splitlines() if '\tdevice' in line]
        return devices
    except Exception as e:
        print(f"Error checking ADB devices: {e}")
        return []

def run_script():
    """Run the start_klipperscreen.sh script."""
    try:
        home_dir = os.environ.get("HOME", os.path.expanduser("~"))
        subprocess.run([f"{home_dir}/start_klipperscreen.sh"], check=True)
        print("start_klipperscreen.sh executed successfully.")
    except Exception as e:
        print(f"Error running start_klipperscreen.sh: {e}")

def main():
    while True:
        devices = check_adb_devices()
        if devices:
            print(f"ADB devices detected: {devices}")
            run_script()
        else:
            print("No ADB devices detected.")
        time.sleep(5)

if __name__ == "__main__":
    main()

EOF

# Step 2: Create the shell script (start_klipperscreen.sh)
echo "Creating the shell script: start_klipperscreen.sh"
cat <<EOF | sudo -u $USER_NAME tee /home/$USER_NAME/start_klipperscreen.sh > /dev/null
#!/bin/bash

# Forward the ADB port
adb forward tcp:6100 tcp:6000

# Start KlipperScreen in a new tmux session
tmux new-session -d -s klipperscreen "
    export DISPLAY=:100 && \
    source \"$HOME/.KlipperScreen-env/bin/activate\" && \
    python3 \"$HOME/KlipperScreen/screen.py\""

# Print a message indicating success
echo "DroidKlipp has started"
EOF

# Make both scripts executable
sudo chmod +x /home/$USER_NAME/adb_monitor.py
sudo chmod +x /home/$USER_NAME/start_klipperscreen.sh

# Step 3: Create the systemd service file
echo "Creating systemd service file: adb_monitor.service"
SERVICE_FILE="/etc/systemd/system/adb_monitor.service"
cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=ADB Monitor Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/$USER_NAME/adb_monitor.py
WorkingDirectory=/home/$USER_NAME
Restart=always
User=$USER_NAME
Environment=HOME=/home/$USER_NAME

[Install]
WantedBy=multi-user.target
EOF

# Step 4: Reload systemd, enable, and start the service
echo "Reloading systemd daemon, enabling, and starting the service"
sudo systemctl daemon-reload
sudo systemctl enable adb_monitor.service
sudo systemctl start adb_monitor.service

echo "ADB monitor python script, start_klipperscreen.sh, and service created, enabled, and started successfully."
