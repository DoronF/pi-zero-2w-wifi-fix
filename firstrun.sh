#!/bin/bash

LOG_FILE="/boot/firmware/firstrun_log.txt"
exec > "$LOG_FILE" 2>&1

SSID="YourNetworkName"
PASS="YourWiFiPassword"
COUNTRY="CA" # your two-letter ISO code (e.g., US, GB, DE)

echo "=== Log Started: $(date) ==="

# Wait for hardware
sleep 15

# Force service state
systemctl unmask NetworkManager
systemctl enable NetworkManager
systemctl start NetworkManager

# Wait for nmcli to be ready
while ! nmcli general status >/dev/null 2>&1; do
    echo "Waiting for NetworkManager..."
    sleep 2
done

# Hardware prep
raspi-config nonint do_wifi_country "$COUNTRY"
rfkill unblock wifi
nmcli radio wifi on

# Profile setup
nmcli con delete "$SSID" >/dev/null 2>&1
nmcli con add type wifi con-name "$SSID" ifname wlan0 ssid "$SSID"
nmcli con mod "$SSID" wifi-sec.key-mgmt wpa-psk
nmcli con mod "$SSID" wifi-sec.psk "$PASS"
nmcli con mod "$SSID" connection.autoconnect yes

echo "Activating connection..."
nmcli --wait 45 con up id "$SSID"

# Brief pause for DHCP assignment
sleep 5

echo "=== Final Network Status ==="
nmcli device status
ip addr show wlan0

# Check connectivity and capture the result
ping -c 1 8.8.8.8 >/dev/null 2>&1
CONNECTIVITY=$?

if [ $CONNECTIVITY -eq 0 ]; then
    echo "Internet connectivity: SUCCESS"
    echo "WiFi Success! Cleaning up boot arguments..."
    
    # Remove the triggers from cmdline.txt
    sed -i 's/systemd.run=[^ ]*//g' /boot/firmware/cmdline.txt
    sed -i 's/systemd.run_success_action=[^ ]*//g' /boot/firmware/cmdline.txt
    sed -i 's/[[:space:]]*$//' /boot/firmware/cmdline.txt
    
    echo "=== Log Finished: $(date) ==="
    echo "Rebooting into clean state..."
    reboot
else
    echo "Internet connectivity: FAILED"
    echo "WiFi Failed. Keeping boot arguments for retry."
    echo "=== Log Finished: $(date) ==="
fi

exit 0