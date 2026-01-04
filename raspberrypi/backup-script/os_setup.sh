#!/bin/bash
# the one-shot installer script. This version can be run directly if deb packages are not desired.
# Usage: sudo ./os_setup.sh

set -e

echo "[*] Enabling automatic security updates..."
sudo apt install -y unattended-upgrades
sudo cp $(dirname "$0")/kiosk-assets/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
sudo cp $(dirname "$0")/kiosk-assets/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

echo "[*] Setting up log rotation for kiosk logs..."
sudo cp $(dirname "$0")/kiosk-assets/kiosk_logrotate /etc/logrotate.d/kiosk

echo "[*] Creating manager user..."
if id "manager" &>/dev/null; then
	echo "User manager already exists, skipping..."
else
	sudo adduser --disabled-password --gecos "" manager
	echo "manager:kiosk" | sudo chpasswd
	sudo usermod -aG sudo manager
fi

echo "[*] Creating kiosk user..."
if id "kiosk" &>/dev/null; then
	echo "User kiosk already exists, skipping..."
else
	sudo adduser --disabled-password --gecos "" kiosk
	sudo usermod -aG video,input,tty kiosk
	echo "kiosk:kiosk" | sudo chpasswd
fi

echo "[*] Ensuring 'gast' remains unprivileged (no sudo)..."
if id "gast" &>/dev/null; then
	if id -nG gast 2>/dev/null | tr ' ' '\n' | grep -qx sudo; then
		sudo deluser gast sudo || true
		echo "[*] Removed 'gast' from sudo group"
	fi
fi

echo "[*] Locking down kiosk user environment..."
if id -nG kiosk 2>/dev/null | tr ' ' '\n' | grep -qx sudo; then
	sudo deluser kiosk sudo || true
fi
sudo usermod -s /bin/bash kiosk
cat <<'EOK' | sudo tee /home/kiosk/.Xmodmap
remove control = Control_L Control_R
remove mod1 = Alt_L Alt_R
remove mod4 = Super_L Super_R
clear control
clear mod1
clear mod4
EOK
sudo chown kiosk:kiosk /home/kiosk/.Xmodmap

echo "[*] Setting up Chromium watchdog..."
# Install watchdog script to match service ExecStart path
if [ -f "$(dirname "$0")/kiosk-assets/chromium_watchdog.sh" ]; then
		sudo cp "$(dirname "$0")/kiosk-assets/chromium_watchdog.sh" /usr/bin/chromium_watchdog.sh
else
		# Fallback: create a minimal watchdog if asset is missing
        sudo tee /usr/bin/chromium_watchdog.sh >/dev/null <<'EOSH'
#!/bin/bash
set -euo pipefail
TARGET_URL="http://192.168.68.186"
if [ -s /etc/mckiosk/target-url ]; then
	TARGET_URL=$(head -n1 /etc/mckiosk/target-url | tr -d '\r')
fi
case "$TARGET_URL" in
	http://*|https://*) ;;
	*) TARGET_URL="http://$TARGET_URL" ;;
esac
FLAGS=(--no-first-run --noerrdialogs --disable-infobars --start-fullscreen --kiosk --incognito --disable-translate --overscroll-history-navigation=0)
while true; do
	if ! pgrep -x chromium-browser >/dev/null 2>&1 && ! pgrep -x chromium >/dev/null 2>&1; then
		if command -v chromium-browser >/dev/null 2>&1; then chromium-browser "${FLAGS[@]}" "$TARGET_URL" & fi
		if command -v chromium >/dev/null 2>&1; then chromium "${FLAGS[@]}" "$TARGET_URL" & fi
	fi
	sleep 5
done
EOSH
fi
sudo chmod +x /usr/bin/chromium_watchdog.sh
sudo cp "$(dirname "$0")/kiosk-assets/chromium-watchdog.service" /etc/systemd/system/chromium-watchdog.service
sudo systemctl enable chromium-watchdog.service

echo "[*] Installing pre-session OS update service..."
sudo cp $(dirname "$0")/kiosk-assets/kiosk-preupdate.sh /usr/local/bin/kiosk-preupdate.sh
sudo chmod +x /usr/local/bin/kiosk-preupdate.sh
sudo cp $(dirname "$0")/kiosk-assets/kiosk-preupdate.service /etc/systemd/system/kiosk-preupdate.service
sudo systemctl enable kiosk-preupdate.service

echo "[*] Installing WireGuard keepalive watchdog..."
sudo cp $(dirname "$0")/kiosk-assets/wg-keepalive.sh /usr/local/bin/wg-keepalive.sh
sudo chmod +x /usr/local/bin/wg-keepalive.sh
sudo cp $(dirname "$0")/kiosk-assets/wg-keepalive.service /etc/systemd/system/wg-keepalive.service
sudo systemctl enable wg-keepalive.service

echo "[*] Installing kiosk break-glass tools..."
sudo cp $(dirname "$0")/kiosk-assets/kiosk-escape.sh /usr/local/bin/kiosk-escape.sh
sudo cp $(dirname "$0")/kiosk-assets/kiosk-restore.sh /usr/local/bin/kiosk-restore.sh
sudo chmod +x /usr/local/bin/kiosk-escape.sh /usr/local/bin/kiosk-restore.sh
if [ ! -f /etc/kiosk-escape.conf ]; then
	# Default plain-text password: kioskescape (change in production)
	sudo bash -c "cat > /etc/kiosk-escape.conf <<'EOF'
# kiosk-escape config (plain-text)
# Default values set by installer; change in production
PASSWORD='kioskescape'
EOF"
	sudo chmod 600 /etc/kiosk-escape.conf
fi

echo "[*] Setting up hardware watchdog (Raspberry Pi only)..."
if grep -q "Raspberry Pi" /proc/cpuinfo; then
	sudo apt install -y watchdog
	sudo cp $(dirname "$0")/kiosk-assets/watchdog.service /etc/systemd/system/watchdog.service
	sudo systemctl enable watchdog.service
fi

echo "[*] Setting up custom splash screen (if splash.png exists in /boot)..."
sudo apt install -y fbi
sudo cp $(dirname "$0")/kiosk-assets/splashscreen.service /etc/systemd/system/splashscreen.service
if command -v raspi-config >/dev/null 2>&1; then
	sudo raspi-config nonint do_boot_splash 0 || true  
fi
if [ -f /boot/splash.png ]; then
	sudo systemctl enable splashscreen.service
fi

echo "[*] Setting up read-only root filesystem (optional, Raspberry Pi only)..."
if grep -q "Raspberry Pi" /proc/cpuinfo; then
	sudo cp $(dirname "$0")/kiosk-assets/remount-rootfs-ro.service /etc/systemd/system/remount-rootfs-ro.service
	sudo systemctl enable remount-rootfs-ro.service
fi

echo "[*] Setting up local content caching (optional)..."
sudo apt install -y squid
sudo systemctl enable squid

echo "[*] Setting up scheduled reboot for reliability..."
sudo bash -c 'echo "0 4 * * * root /sbin/reboot" > /etc/cron.d/kiosk-reboot'

echo "[*] Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo "[*] Ensuring required GUI packages for kiosk are installed..."
for pkg in xserver-xorg x11-xserver-utils xinit openbox unclutter ufw curl; do
	if ! dpkg -l | grep -q "^ii  $pkg"; then
		sudo apt install --no-install-recommends -y $pkg
	fi
done

# Cleanup any legacy on-screen keyboard helper scripts
sudo rm -f /usr/local/bin/kiosk-toggle-keyboard.sh /usr/local/bin/kiosk-keyboard-launcher.sh 2>$null || true

# Desktop entry for tint2 launcher
# Managed policy: force-install Simple Virtual Keyboard extension
sudo mkdir -p /etc/chromium/policies/managed /etc/chromium-browser/policies/managed
sudo tee /etc/chromium/policies/managed/mckiosk.json >/dev/null <<'EOPOL'
{
	"ExtensionInstallForcelist": [
		"cmeanlmbffknccbnkahlnkeaompejbch;https://clients2.google.com/service/update2/crx"
	],
	"ExtensionSettings": {
		"*": { "installation_mode": "allowed" },
		"cmeanlmbffknccbnkahlnkeaompejbch": {
			"installation_mode": "force_installed",
			"update_url": "https://clients2.google.com/service/update2/crx",
			"toolbar_pin": "force_pinned",
			"allow_in_incognito": true
		},
		"ecjkcanpimnagobhegghdeeiagffoidk": { "installation_mode": "blocked" },
		"cjabmkimbcmhhepelfhjhbhonnapiipj": { "installation_mode": "blocked" }
	}
}
EOPOL
sudo cp /etc/chromium/policies/managed/mckiosk.json /etc/chromium-browser/policies/managed/mckiosk.json 2>$null || true

echo "[*] Installing WireGuard and preparing VPN configuration..."
if ! dpkg -l | grep -q "^ii  wireguard-tools"; then
	sudo apt install -y wireguard-tools resolvconf
fi
sudo mkdir -p /etc/wireguard

# Prefer an externally provided config. Options:
# 1) /etc/wireguard/wg0.conf already present
# 2) /boot/wg0.conf provided at imaging time
# 3) backup-script/secrets/wg0.conf (never commit real secrets)
WG_CONF_SOURCE=""
if [ -f /etc/wireguard/wg0.conf ]; then
	WG_CONF_SOURCE=/etc/wireguard/wg0.conf
elif [ -f /boot/wg0.conf ]; then
	WG_CONF_SOURCE=/boot/wg0.conf
elif [ -f "$(dirname "$0")/secrets/wg0.conf" ]; then
	WG_CONF_SOURCE="$(dirname "$0")/secrets/wg0.conf"
fi

if [ -n "$WG_CONF_SOURCE" ] && [ "$WG_CONF_SOURCE" != "/etc/wireguard/wg0.conf" ]; then
	echo "[*] Copying WireGuard config from $WG_CONF_SOURCE to /etc/wireguard/wg0.conf"
	sudo cp "$WG_CONF_SOURCE" /etc/wireguard/wg0.conf
fi

if [ -f /etc/wireguard/wg0.conf ]; then
	sudo chmod 600 /etc/wireguard/wg0.conf
	# Order wg-quick after network targets but avoid hard requirements that block boot
	sudo mkdir -p /etc/systemd/system/wg-quick@wg0.service.d
	cat <<'EOUNIT' | sudo tee /etc/systemd/system/wg-quick@wg0.service.d/override.conf >/dev/null
[Unit]
After=network.target network-online.target
EOUNIT
	sudo systemctl daemon-reload
	sudo systemctl enable wg-quick@wg0.service
	sudo systemctl start wg-quick@wg0.service || true
	echo "[*] WireGuard configured. Service will start on next boot."
else
	echo "[!] No /etc/wireguard/wg0.conf found."
	echo "    - Place your config at /etc/wireguard/wg0.conf (mode 600),"
	echo "      or at /boot/wg0.conf before first boot, or in backup-script/secrets/wg0.conf."
	echo "    - An example is available at $(dirname "$0")/kiosk-assets/wg0.conf.example."
fi

echo "[*] Checking for Chromium browser..."
if ! command -v chromium-browser >/dev/null && ! command -v chromium >/dev/null; then
	sudo apt install -y chromium-browser
else
	echo "[*] Chromium is already installed, skipping..."
fi

echo "[*] Setting kiosk user to autologin on tty1..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
AGETTY_PATH=$(command -v agetty || echo /sbin/agetty)
cat <<EOL | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-${AGETTY_PATH} --autologin kiosk --noclear %I linux
EOL
sudo systemctl daemon-reload
sudo systemctl enable getty@tty1.service

echo "[*] Preventing long boot waits on network-online..."
# Disable or mask wait-online services that can hang boot when no link is present
for waitsvc in NetworkManager-wait-online.service systemd-networkd-wait-online.service dhcpcd-wait-online.service; do
	if systemctl list-unit-files | grep -q "^${waitsvc}"; then
		sudo systemctl disable "${waitsvc}" 2>/dev/null || true
		sudo systemctl mask "${waitsvc}" 2>/dev/null || true
		sudo systemctl stop "${waitsvc}" 2>/dev/null || true
	fi
done

echo "[*] Disabling and masking any display manager to prevent greeters..."
# Stop/disable common DMs and mask the generic alias so nothing can take over tty1
for dm in gdm3 lightdm sddm xdm greetd; do
	if systemctl is-enabled "$dm" 2>/dev/null; then
		sudo systemctl disable "$dm" || true
	fi
	sudo systemctl stop "$dm" 2>/dev/null || true
done
sudo systemctl mask display-manager.service 2>/dev/null || true
sudo systemctl stop display-manager.service 2>/dev/null || true
# Ensure default boot target is console (multi-user) rather than graphical
if systemctl get-default | grep -q '^graphical.target$'; then
	sudo systemctl set-default multi-user.target || true
fi

echo "[*] Creating Openbox autostart for kiosk user..."
sudo mkdir -p /etc/mckiosk
if [ ! -s /etc/mckiosk/target-url ]; then
	echo "http://192.168.68.186" | sudo tee /etc/mckiosk/target-url >/dev/null
fi
sudo -u kiosk mkdir -p /home/kiosk/.config/openbox
cat <<'EOF' | sudo tee /home/kiosk/.config/openbox/autostart >/dev/null
# Disable screen blanking and power management
xset s off
xset -dpms
xset s noblank

# Hide cursor after 0.5s
unclutter -idle 0.5 &

# Rely on Chromium extension for on-screen keyboard; do not start any external keyboard

# Show connecting overlay (non-blocking); auto-closed later
if command -v xmessage >/dev/null; then
	xmessage -center -buttons none -nearmouse "Connecting to network..." &
	XM_PID=$!
fi

# Determine target URL (can be a bare IP or hostname). Default to local IP if not set.
TARGET_URL="http://192.168.68.186"
if [ -s /etc/mckiosk/target-url ]; then
		TARGET_URL=$(head -n1 /etc/mckiosk/target-url | tr -d '\r')
fi
case "$TARGET_URL" in
	http://*|https://*) ;;
	*) TARGET_URL="http://$TARGET_URL" ;;
esac

# If a WG config exists, wait for wg0 and basic connectivity with no timeout
if [ -f /etc/wireguard/wg0.conf ]; then
	# Wait for wg0 device to appear
	until ip link show wg0 >/dev/null 2>&1; do
		sleep 1
	done
	# Then wait until VPN DNS responds
	until ping -c1 -W1 10.8.0.1 >/dev/null 2>&1; do
		sleep 2
	done
	# Ensure the app is actually reachable over the tunnel to avoid refused page
	if command -v curl >/dev/null 2>&1; then
		while true; do
			if curl -4 --interface wg0 -sS --max-time 3 -o /dev/null "$TARGET_URL"; then
				break
			fi
			rc=$?
			# Treat cert error (60) as connectivity OK when using raw IP + HTTPS
			if [ "$rc" = "60" ]; then break; fi
			sleep 2
		done
	fi
fi

# Close overlay if shown
if [ -n "${XM_PID:-}" ] && kill -0 "$XM_PID" 2>/dev/null; then
	kill "$XM_PID" 2>/dev/null || true
fi

# Launch Chromium in full-screen kiosk mode (no incognito to ensure extension works)
if command -v chromium-browser >/dev/null; then
	chromium-browser --no-first-run --noerrdialogs --disable-infobars --start-fullscreen --kiosk --disable-translate --overscroll-history-navigation=0 "$TARGET_URL" &
elif command -v chromium >/dev/null; then
	chromium --no-first-run --noerrdialogs --disable-infobars --start-fullscreen --kiosk --disable-translate --overscroll-history-navigation=0 "$TARGET_URL" &
fi
# No external keyboard launcher restart
EOF
sudo chown -R kiosk:kiosk /home/kiosk/.config

if [ ! -f /home/kiosk/.xinitrc ]; then
	sudo -u kiosk bash -c 'cat > /home/kiosk/.xinitrc <<"EOF"
#!/bin/sh
exec openbox-session
EOF
chmod +x /home/kiosk/.xinitrc'
fi

echo "[*] Enabling autostart of X on tty1..."
sudo -u kiosk bash -c 'echo -e "\nif [ -z \$DISPLAY ] && [ \$(tty) == /dev/tty1 ]; then startx >> /home/kiosk/.xsession-errors 2>&1; fi" >> /home/kiosk/.bash_profile'

echo "[*] Setting up firewall..."
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw --force enable

echo "[*] Installing and enabling AppArmor..."
if ! dpkg -l | grep -q "^ii  apparmor"; then
	sudo apt install --no-install-recommends -y apparmor apparmor-utils
fi
sudo systemctl enable apparmor
sudo systemctl start apparmor

if [ ! -e /sys/module/apparmor/parameters/enabled ] || ! cat /sys/module/apparmor/parameters/enabled 2>/dev/null | grep -qi "^Y\|enforce" ; then
	echo "[*] AppArmor kernel support appears inactive; attempting to enable via cmdline..."
	CMDLINE_FILE=""
	if [ -f /boot/cmdline.txt ]; then
		CMDLINE_FILE=/boot/cmdline.txt
	elif [ -f /boot/firmware/cmdline.txt ]; then
		CMDLINE_FILE=/boot/firmware/cmdline.txt
	fi
	if [ -n "$CMDLINE_FILE" ]; then
		if ! grep -q "\bapparmor=1\b" "$CMDLINE_FILE"; then
			sudo sed -i '1 s/$/ apparmor=1 security=apparmor/' "$CMDLINE_FILE"
			echo "[*] Enabled AppArmor in $CMDLINE_FILE (will take effect after reboot)."
		fi
	else
		echo "[!] Could not find cmdline.txt to enable AppArmor automatically."
	fi
fi

echo "[*] Installing Chromium AppArmor profile file..."
sudo cp $(dirname "$0")/kiosk-assets/usr.bin.chromium-browser /etc/apparmor.d/usr.bin.chromium-browser
if systemctl is-active --quiet apparmor && [ -e /sys/module/apparmor/parameters/enabled ] && cat /sys/module/apparmor/parameters/enabled 2>/dev/null | grep -qi "^Y\|enforce" ; then
	echo "[*] AppArmor active; loading and enforcing Chromium profile..."
	sudo apparmor_parser -r /etc/apparmor.d/usr.bin.chromium-browser || true
	sudo aa-enforce /etc/apparmor.d/usr.bin.chromium-browser || true
else
	echo "[!] AppArmor not active yet; profile file installed and will be enforced after reboot."
fi

echo "[*] Enabling SSH..."
sudo systemctl enable ssh
sudo systemctl start ssh

echo "[*] Provisioning Wi-Fi autoconnect (KdG-iDev)..."
# Unblock Wi‑Fi and prefer NetworkManager if present
if command -v rfkill >/dev/null 2>&1; then
	sudo rfkill unblock wifi || true
fi
if command -v nmcli >/dev/null 2>&1; then
	sudo nmcli radio wifi on || true
	if nmcli -g NAME connection show 2>/dev/null | grep -Fxq "KdG-iDev"; then
		sudo nmcli connection modify "KdG-iDev" connection.autoconnect yes || true
	else
		sudo nmcli dev wifi connect "KdG-iDev" password "WPU5XTSeTgmVmPKv" name "KdG-iDev" || true
		sudo nmcli connection modify "KdG-iDev" connection.autoconnect yes || true
	fi
else
	# Try to install and start NetworkManager, then connect
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update || true
		sudo DEBIAN_FRONTEND=noninteractive apt-get install -y network-manager || true
	fi
	if systemctl list-unit-files | grep -q '^NetworkManager\.service'; then
		sudo systemctl enable NetworkManager || true
		sudo systemctl start NetworkManager || true
	fi
	if command -v nmcli >/dev/null 2>&1; then
		sudo nmcli radio wifi on || true
		sudo nmcli dev wifi connect "KdG-iDev" password "WPU5XTSeTgmVmPKv" name "KdG-iDev" || true
		sudo nmcli connection modify "KdG-iDev" connection.autoconnect yes || true
	fi
fi

echo "[*] Enabling WireGuard keepalive service..."
sudo systemctl start wg-keepalive.service || true
sudo systemctl enable wg-quick@wg0
if [ $? -eq 0 ]; then
	echo "[*] Kiosk mode activated successfully. Rebooting machine..."
	sudo reboot
else
	echo "[ERROR] Kiosk mode failed to activate. Not rebooting."
fi

