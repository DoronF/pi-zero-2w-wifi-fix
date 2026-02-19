# Raspberry Pi Zero 2 W WiFi Fix – Headless First-Boot Setup 

This repository provides a simple, reliable workaround for cases where a **fresh Raspberry Pi OS Bookworm install** on a **Raspberry Pi Zero 2 W** fails to connect to WiFi automatically — even when pre-configured via Raspberry Pi Imager.

### The Problem

In Raspberry Pi OS Bookworm (and later), headless WiFi setup via the Imager's advanced options sometimes fails silently on the Pi Zero 2 W (often due to NetworkManager timing, driver initialization, country code issues, or Imager bugs in certain versions). The device boots but never joins the network, leaving you without SSH or remote access.

After searching wround it was clean many are having the same issue. My first successful connection to WiFi invonved setting up the Raspberry Pi zero 2 W as a usb gadget, SSH into it and setup WiFi more or less the way the script does. However, it was extremly finiky and the SSH connection kept dropping.

This fix uses a custom first-boot script triggered via kernel command line to force WiFi configuration using **NetworkManager** (`nmcli`), without the need to setup the usb gadget etc.

Tested successfully on:
- Raspberry Pi Zero 2 W
- Raspberry Pi OS Lite (64-bit)
- Headless setup (no monitor/keyboard)
- Meshed WiFi where both 5GHz and 2.4GHz share the same SSID (reported as a limitation)
- MacOS Monterey

### Solution Overview

1. After imaging the SD card with Raspberry Pi Imager, insert the MicroSD card again.
2. Replace `cmdline.txt` with the version below (adds `systemd.run` to execute a script on first boot).
3. Place the custom `firstrun.sh` script in the root directory of the SD card.
4. Insert the SD card → boot the Pi → it runs the script once, connects to WiFi, cleans up, and reboots.
5. After reboot, SSH should work normally.

### Step-by-Step Instructions

1. **Image the SD Card**
   - Use the latest **Raspberry Pi Imager**.
   - Choose **Raspberry Pi OS (other)** → **Raspberry Pi OS Lite (32-bit)** or **(64-bit)**.
   - (Optional but recommended) pre-set:
     - Username & password
     - Hostname
     - Enable SSH
     - Set locale / keyboard (helps avoid some edge cases)
   - Write to the SD card.

2. **Mount the Boot Partition**
   - Eject & re-insert the SD card (or mount it manually).
   - You should see a drive named **boot** or **bootfs** containing files like `config.txt`, `cmdline.txt`, etc.
   - **Note**: In Bookworm, the real editable files are under `/boot/firmware/` once the Pi boots, but on your computer you'll edit them in the root of the boot partition.

3. **Replace cmdline.txt**
   - Overwrite the file `cmdline.txt` in the boot partition with the one in the repo.
   - It should look like this ```console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait systemd.run=/boot/firmware/firstrun.sh systemd.run_success_action=reboot``` where this is what we add to it **systemd.run=/boot/firmware/firstrun.sh systemd.run_success_action=reboot**. It instructs the system to run our script and if successful, reboot. If the script run successfuly it will remove the addition so that it only runs again if WiFi connection was not established.
  
4. **Create firstrun.sh**
    - In the same boot partition, add the `firstrun.sh` file from this repo.
    - **Important**: Edit the top three variables:
      - SSID="YourNetworkName"
      - PASS="YourWiFiPassword"
      - COUNTRY="CA" (change to your two-letter country code, e.g. US, GB, DE)
5. **Safely Eject the SD Card**
    - Unmount/eject properly.
6. **Boot the Pi**
    - Insert into Pi Zero 2 W and power on.
    - Wait ~1–2 minutes. The script runs only once.
    - Check your router's connected devices list or try ssh pi@raspberrypi.local (or your chosen hostname).


### Troubleshooting

- **No connection after first boot** → Mount SD card again → Check `firstrun_log.txt` for errors (e.g. wrong password, country code issue, NM timeout).
- **Script runs repeatedly** → The cleanup sed commands failed — manually edit /boot/firmware/cmdline.txt to remove the systemd.run=... parts.

### Security Notes

- This script hardcodes your WiFi password in plain text (temporarily on the boot partition).
- Delete or overwrite firstrun.sh after successful setup.
- Change your default password immediately after first login.

### License

MIT – feel free to use, modify, and share.

If this helped you, consider linking back or starring the repo!

Happy hacking! Doron (Toronto)
