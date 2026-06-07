# DroidKlipp

DroidKlipp turns an Android device into a KlipperScreen display for a Klipper printer host. It launches KlipperScreen on the Klipper machine and displays it on Android through the DroidKlipp Android APK / XServer XSDL integration.

![Logo](https://github.com/CodeMasterCody3D/DroidKlipp/blob/main/logo.png)

## What DroidKlipp Does

- Starts and monitors KlipperScreen automatically.
- Uses ADB USB forwarding for low-latency USB display mode.
- Starts the DroidKlipp Android X server activity automatically when a USB device is detected.
- Falls back to WiFi X11 display mode when USB disconnects.
- Uses udev events plus polling so USB plug/unplug changes are detected quickly.
- Restarts KlipperScreen if the tmux session crashes.

## Required Android APK

Install the DroidKlipp Android APK on your Android device first:

[Download DroidKlipp.apk](https://github.com/CodeMasterCody3D/DroidKlipp-Android-APK/releases/latest/download/DroidKlipp.apk)

APK source/release repo:

https://github.com/CodeMasterCody3D/DroidKlipp-Android-APK

> DroidKlipp uses the Android package/activity `droidklipp.x.org.server/x.org.server.MainActivity`. Use the DroidKlipp APK above, not the old generic SourceForge XServer XSDL APK.

## KlipperScreen Requirement

DroidKlipp expects KlipperScreen to be installed in these standard paths:

```text
~/KlipperScreen/screen.py
~/.KlipperScreen-env/bin/python
```

Install KlipperScreen before installing DroidKlipp. If KlipperScreen is installed somewhere else, DroidKlipp will not find it without script changes.

## Klipper Host Prerequisites

Install these on the Klipper machine / Raspberry Pi:

```sh
sudo apt update
sudo apt install adb tmux x11-utils
```

## Android Setup

1. Install `DroidKlipp.apk` from the release link above.
2. Enable Developer Options and USB Debugging on Android.
3. Disable the Android lock screen, or set it to `None`, so automatic wake/start works reliably.
4. Open the DroidKlipp APK once before the first connection and accept any Android prompts.
5. For X server screen blanking, open the Android app configuration and add these command-line parameters on separate lines:

   ```text
   -s
   0
   ```

## Install DroidKlipp

```sh
cd ~
git clone https://github.com/CodeMasterCody3D/DroidKlipp.git
cd DroidKlipp
chmod +x install_droidklipp.sh
./install_droidklipp.sh
sudo reboot
```

The main installer creates:

```text
/etc/udev/rules.d/99-droidklipp.rules
/usr/local/bin/droidklipp_udev.sh
~/droidklipp_monitor.py
~/start_klipperscreen.sh
/etc/systemd/system/adb_monitor.service
~/.droidklipp_wifi_ip        # when a WiFi IP is detected or entered
```

It also enables and restarts:

```text
adb_monitor.service
```

## WiFi Fallback

WiFi fallback is configured during `install_droidklipp.sh`.

- If Android is connected over USB during install, the script tries to detect the Android `wlan0` IP automatically.
- If no IP is detected, the script prompts for manual entry.
- If the IP changes later, refresh only the WiFi cache with:

```sh
./install_wifi.sh
```

## Runtime Behavior

USB connected:

```text
ADB forward tcp:6100 -> Android tcp:6000
KlipperScreen DISPLAY=:100
```

USB disconnected and WiFi IP cached:

```text
KlipperScreen DISPLAY=<android-ip>:0
```

Useful status/log commands:

```sh
systemctl status adb_monitor.service
journalctl -u adb_monitor.service -f
```

## Manual Helper

After install, this helper exists for manual ADB wake/forward setup:

```sh
~/start_klipperscreen.sh
```

The monitor service still handles KlipperScreen launch/restart automatically.

## Uninstall

Remove DroidKlipp monitor/service files, WiFi fallback cache, udev rules, and DroidKlipp tmux sessions while keeping KlipperScreen itself intact:

```sh
./uninstall_droidklipp.sh
```

`uninstall_wifi.sh` is kept only as a backward-compatible wrapper and now runs the full uninstaller.

## Troubleshooting

### Android does not wake or launch the X server

- Confirm USB Debugging is enabled.
- Accept the Android USB debugging trust prompt.
- Disable the lock screen.
- Confirm the DroidKlipp APK is installed.
- Check ADB:

  ```sh
  adb devices
  adb shell am start -n droidklipp.x.org.server/x.org.server.MainActivity
  ```

### KlipperScreen does not appear

Check that KlipperScreen is installed here:

```sh
ls ~/KlipperScreen/screen.py
ls ~/.KlipperScreen-env/bin/python
```

Check monitor logs:

```sh
journalctl -u adb_monitor.service -n 100 --no-pager
```

### WiFi fallback does not work

Confirm Android and the Klipper host are on the same network and X11 is reachable:

```sh
cat ~/.droidklipp_wifi_ip
xdpyinfo -display $(cat ~/.droidklipp_wifi_ip):0
```

Then refresh the cached IP if needed:

```sh
./install_wifi.sh
```

## Links

- DroidKlipp Android APK: https://github.com/CodeMasterCody3D/DroidKlipp-Android-APK
- KlipperScreen Android docs: https://klipperscreen.readthedocs.io/en/latest/Android/
- KIAUH: https://github.com/dw-0/kiauh
- Android Klipper Screen reference: https://github.com/naruhaxor/AndroidKlipperScreen

## License

See [`LICENSE`](LICENSE).
