## DROIDKLIPP USES THE INSTALL LOCATION OF KLIPPER SCREEN INSTALLED VIA KIAUH V6. WHEN RUNNING KIAUH IT WILL ASK TO USE VERSION V6 PRESS Y FOR YES. THEN PROCEED TO INSTALL KLIPPERCREEN WITH KIAUH, OTHERWISE YOU WILL NOT HAVE KLIPPERSCREEN WORKING ON YOUR ANDROID.


![Logo](https://github.com/CodeMasterCody3D/DroidKlipp/blob/main/logo.png)

# DroidKlipp: Seamlessly Connect Android to Klipper

**DroidKlipp** transforms your Android device into a powerful interface for KlipperScreen, allowing easy connection via **ADB** and **Xserver XSDL**. Switch between printers effortlessly with this portable and versatile solution!

---

## Overview

### What is DroidKlipp?  
DroidKlipp allows you to integrate your Android device with any Klipper setup, enabling seamless interaction with KlipperScreen. By leveraging ADB's TCP forwarding, you can bridge your device and enjoy a fully functional 3D printing interface on the go.

---

## Features
- **Automatic ADB TCP Forwarding:** Effortlessly bridge your Android device to Klipper.  
- **Seamless KlipperScreen Integration:** Display KlipperScreen on your Android device via Xserver XSDL.  
- **Portable & Flexible:** Perfect for makers seeking a mobile 3D printing interface.  

---

## Getting Started

### Prerequisites

Ensure the following packages are installed on your Klipper machine:  
```sh
sudo apt install adb
sudo apt install tmux
```  

### Android Setup
1. **Install Required App**  
   Download and install [Xserver XSDL](https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/XServer-XSDL-1.20.51.apk/download) on your Android device.  

2. **Enable USB Debugging**  
   - Go to your phone's Developer Options and enable **USB Debugging**. 

3. **Launch Xserver XSDL**  
   - Open Xserver XSDL **before** plugging in your Android device to ensure the Xserver port is created correctly.

---

### Installing KlipperScreen with KIAUH
To use DroidKlipp, you need to install KlipperScreen via KIAUH. 
UPDATE: I forked the KIAUH repo and added DroidKlipp to the install menu.
[kiauhPlusDroidKlipp
](https://github.com/CodeMasterCody3D/kiauhPlusDroidKlipp.git).  

Alternative install would be using my fork of KIAUH.

1. Clone the KIAUH repository:  
   ```sh
   cd ~ && git clone https://github.com/CodeMasterCody3D/kiauhPlusDroidKlipp.git
   ```  

2. Run the KIAUH script:  
   ```sh
   ./kiauhPlusDroidKlipp/kiauh.sh
   ```  

3. Follow the prompts to install KlipperScreen.(Alternative Install: DroidKlipp install added to KIAUH for easy install)

4. Please note that installing the network add-on during the KlipperScreen setup will prevent you from connecting to Wi-Fi afterward.

---

### Installing DroidKlipp

1. Clone the DroidKlipp repository:  
   ```sh
   cd ~ && git clone https://github.com/CodeMasterCody3D/DroidKlipp.git
   ```  

2. Navigate to the DroidKlipp folder:  
   ```sh
   cd DroidKlipp
   ```  

3. Make the script executable:  
   ```sh
   sudo chmod +x droidklipp.sh
   ```  

4. Run the DroidKlipp setup script:  
   ```sh
   ./droidklipp.sh
   ```
    
5. Install Prerequisites:  
  ```sh
  sudo apt install adb
  sudo apt install tmux
  ``` 

6. Reboot your system:  
   ```sh
   sudo reboot
   ```  

---

## Android Configuration

1. **Enable USB Debugging**  
   - Ensure your phone is set to allow debugging.  


2. **Plug & Play**  
   - Plug in your phone and allow any permission prompts that appear.  

---

## Important Notes

### Xserver XSDL Configuration
- Stop Screen Blanking in Xserver-XSDL
Even after enabling the "Stay Awake" option in the Developer/USB Debugging options of your Android device, the Xserver-XSDL may still go to a black screen but keep the backlight of your device on. To keep the screen always active, upon start up of Xserver-XSDL app, select the Change Device Configuration at the top of the splash screen and then select the Command line parameters, one argument per line option. Append the following argument (must be on seperate lines):


  ```sh
  -s
  0
  ```  

### Xserver XSDL Download
Xserver XSDL is no longer available on the Google Play Store. Download it directly from SourceForge:  
[Download Xserver XSDL](https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/XServer-XSDL-1.20.51.apk/download)

---

## Links and Resources

- [KlipperScreen Docs](https://klipperscreen.readthedocs.io/en/latest/Android/)  
- [KIAUH](https://github.com/dw-0/kiauh)  
- [Xserver XSDL APK](https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/XServer-XSDL-1.20.51.apk/download)
- [Android Klipper Screen](https://github.com/naruhaxor/AndroidKlipperScreen)  

---

Now you’re ready to load your DroidKlipps and start printing! 🚀
