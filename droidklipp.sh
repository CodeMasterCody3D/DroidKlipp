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
        devices = [line.split()[0] for line in result.stdout.splitlines() if "\\tdevice" in line]
        return devices
    except Exception as e:
        print(f"Error checking ADB devices: {e}")
        return []

def run_script():
    """Run the start_klipperscreen.sh script."""
    try:
        # Get the HOME directory dynamically
        home_dir = os.environ.get("HOME")
        if home_dir is None:
            home_dir = os.path.expanduser("~")
        
        # Run the script using the HOME environment variable
        subprocess.run([f'{home_dir}/start_klipperscreen.sh'], check=True)
    except Exception as e:
        print(f"Error running start_klipperscreen.sh: {e}")

def main():
    connected_devices = set()

    while True:
        # Check for connected devices
        current_devices = set(check_adb_devices())
        
        # Detect new devices
        new_devices = current_devices - connected_devices
        
        if new_devices:
            print(f"New devices detected: {new_devices}")
            for device in new_devices:
                try:
                    print(f"Device {device} detected, rerunning start_klipperscreen.sh")
                    # Run the script to restart KlipperScreen
                    run_script()
                except Exception as e:
                    print(f"Error setting up device {device}: {e}")
        
        # Update the list of connected devices
        connected_devices = current_devices
        
        # Wait for a while before checking again
        time.sleep(5)

if __name__ == "__main__":
    main()
EOF

# Step 2: Create the shell script (start_klipperscreen.sh)
echo "Creating the shell script: start_klipperscreen.sh"
cat <<EOF | sudo -u $USER_NAME tee /home/$USER_NAME/start_klipperscreen.sh > /dev/null
#!/bin/bash

# Check if adb is installed
if ! command -v adb &> /dev/null; then
    echo "ADB not found, exiting..."
    exit 1
fi

# Check for ADB USB connection (if there's an IP address attached to adb)
adb_devices=\$(adb devices | grep -w "device")
if [[ -z "\$adb_devices" ]]; then
    echo "No ADB USB device detected, exiting..."
    exit 0
fi

# Get the IP address of the connected Android device
device_ip=\$(adb shell ip -o -4 addr show | grep 'rndis0' | awk '{print \$4}' | cut -d'/' -f1)

if [[ -z "\$device_ip" ]]; then
    echo "No IP address found for the device, exiting..."
    exit 0
fi

# Debug: Print the device IP to ensure it was extracted correctly
echo "Device IP: \$device_ip"

# Export the DISPLAY environment variable using the device's IP
export DISPLAY="\${device_ip}:0"

# Close the existing tmux session if it exists
if tmux has-session -t klipperscreen 2>/dev/null; then
    echo "Existing tmux session found. Killing it..."
    tmux kill-session -t klipperscreen
fi

# Start a new tmux session and run KlipperScreen
echo "Starting a new tmux session for KlipperScreen..."
tmux new-session -d -s klipperscreen "source '\$HOME/.KlipperScreen-env/bin/activate' && python3 '\$HOME/KlipperScreen/screen.py'"

echo "KlipperScreen started on \$device_ip."
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
