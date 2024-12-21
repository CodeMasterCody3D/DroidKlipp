![Logo](https://github.com/CodeMasterCody3D/DroidKlipp/blob/main/droidklipplogo.png)


# DroidKlipp
# "A tool for using Android devices with KlipperScreen via USB tethering and ADB."   Use xserver XSDL on android to connect with DroidKlipp  
# DroidKlipp
# A unique solution for integrating Android devices into 3D printing workflows. DroidKlipp leverages ADB to create a network bridge via USB tethering on Android, enabling seamless access to KlipperScreen through Xserver XSDL.

# You need to use KIAUH to install klipperScreen for this to work.

Download
```sh
cd ~ && git clone https://github.com/dw-0/kiauh.git
```
Run script
```sh
./kiauh/kiauh.sh
```
Install klipper screen following the prompts


# Features:

USB tethering-based network bridge for efficient communication
Full compatibility with Xserver XSDL to display KlipperScreen on Android
Optimized for makers seeking portable and powerful 3D printing interfaces
Collaborate and contribute to this innovative project that transforms Android devices into versatile 3D printing tools.


# Prerequisites:

```sh
sudo apt install adb
```

```sh
sudo apt install tmux
```


# Install DroidKlipp:

```sh
cd ~ && git clone https://github.com/CodeMasterCody3D/DroidKlipp.git
```

```sh
./droidklipp.sh
```

```sh
sudo reboot
```

# Android side:

enable usb debugging
choose defualt usb configuration as "USB Tethering" 
plug usb intoo phone, allow computer when promted.

# Finished:

Now your on your way to loading DroidKlipps between printers!!


# NOTE:
make sure to open xsdl on android before you plug usb up because it will create an xserver on the networks availble. if your usb is plugged in with usb tethering enabled and then open Xserver XSDL it will create the xserver for your usb tether IP address.


