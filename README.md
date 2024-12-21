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

# USB Debugging
Even after enabling the "Stay Awake" option in the Developer/USB Debugging options of your Android device, the Xserver-XSDL may still go to a black screen but keep the backlight of your device on. To keep the screen always active, upon start up of Xserver-XSDL app, select the Change Device Configuration at the top of the splash screen and then select the Command line parameters, one argument per line option. Append the following argument (must be on seperate lines):

```sh
-s
0
```
This will disable the screen-saver in Xserver and keep KlipperScreen always active.


# XseverXSDL
XserverXSDL is not on the playstore anymore.
here is the official sourceforge link:
```sh
https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/XServer-XSDL-1.20.51.apk/download
```


# Links

DOCS:[KlipperScreen Docs About ADB USB and XserverXSDL](https://klipperscreen.readthedocs.io/en/latest/Android/) 


Link for:[KIAUH](https://github.com/dw-0/kiauh) 

