# Mc Kiosk (Raspberry Pi OS Standard 64-bit Ready)

This repository contains two ways to provision a secure, self‑booting kiosk that launches a web app in Chromium kiosk mode on Raspberry Pi or a VM:

- A Debian package you can build and install with apt (recommended for reproducible installs)
- A one‑shot backup script you can run directly on the device

Key goals:
- Fast: boots straight into the app
- Secure: locked-down kiosk user, AppArmor, UFW, unattended upgrades, logrotate
- Reliable: watchdogs, daily reboot, splash screen, autologin-and-startx
- Flexible: supports Raspberry Pi OS Standard 64-bit and Lite; also works on Debian-like VMs

Note on brand usage: names and styling are placeholders for educational purposes. Replace with your own brand and domain.

---

## What the setup does

Whether you use the .deb or the backup script, the device is configured non‑interactively and only reboots at the end (you trigger the reboot). The backup script lives under `backup-script/os_setup.sh`.

Security and hardening
- Enables unattended security updates
- Installs UFW and enables a restrictive firewall (allows SSH)
- Installs AppArmor and applies a Chromium profile
- Sets up log rotation for kiosk logs

Users and login
- Creates two accounts: `kiosk` (no sudo) and `manager` (sudo)
- Autologins `kiosk` on tty1 via a systemd getty override

GUI and session
- Installs minimal GUI components (Xorg, xinit, Openbox, unclutter)
- Creates an Openbox autostart that disables screen blanking and launches Chromium in kiosk mode
- Writes a `.xinitrc` to start `openbox-session`

Reliability
- Installs a Chromium watchdog systemd service
- Optionally installs a hardware watchdog on Raspberry Pi
- Schedules a daily reboot at 04:00

Cosmetics and optional features
- Supports a custom splash screen via `splashscreen.service` when `/boot/splash.png` exists
- Optionally enables a read-only root filesystem (Raspberry Pi only)
- Installs Squid proxy (optional caching)

Raspberry Pi specific
- Guards Raspberry Pi–only calls (e.g., `raspi-config`) so the setup also runs on VMs

---

## Supported OS

- Raspberry Pi OS Standard 64-bit (Bookworm) — recommended
- Raspberry Pi OS Lite 64-bit — also supported; GUI packages are installed by the script
- Debian/Ubuntu VMs — supported for testing; Pi-only features are skipped

---

## Quick start

Two options that produce the same end state after one reboot:

Option A — Build and install the .deb (recommended)
- On the Pi (with internet):
  1. Ensure your WireGuard config is available in one of these locations (should already be done. first found wins):
    - `/etc/wireguard/wg0.conf` (600)
    - `/boot/wg0.conf` (copied to `/etc/wireguard/wg0.conf` on install)
    - `backup-script/secrets/wg0.conf` (tracked; convenient for dev)
  2. Install build tools (one-time):
    - `sudo apt-get update && sudo apt-get install -y build-essential devscripts debhelper fakeroot`
  3. Build the package from the repo root:
    - `debuild -us -uc`
    - The `.deb` will appear one level up, e.g. `../mckiosk-base_*.deb`
  4. Install the package:
    - `sudo apt-get install -y ./../mckiosk-base_*.deb`
  5. Reboot:
    - `sudo reboot`

What happens on first boot after install
- A pre-session updater runs before kiosk login and applies security updates (reboots immediately if required).
- The system autologins the `kiosk` user, starts X/Openbox, shows a "Connecting to network..." overlay, then launches Chromium only after the VPN is reachable.
- WireGuard is enabled and monitored by a keepalive service.
- AppArmor and UFW are enabled. Chromium is constrained by an AppArmor profile.

Break-glass (admin control)
- Default credentials (change ASAP):
  - Password: `kioskescape`
  - Code: `kioskescape`
- SSH in as `manager`, then:
  - Stop kiosk: `sudo kiosk-escape.sh`
  - Restore kiosk: `sudo kiosk-restore.sh`

Verify after boot
- VPN: `systemctl status wg-quick@wg0 || sudo wg show`
- Keepalive: `systemctl status wg-keepalive`
- Updater: `journalctl -u kiosk-preupdate --no-pager`
- Kiosk watchdog: `systemctl status chromium-watchdog`

Option B — Run the backup script
- `cd backup-script` and run `sudo ./os_setup.sh`. It performs the same configuration steps and reboots at the end.

Optional splash: copy `splash.png` to `/boot/` and ensure `splashscreen.service` is enabled (the setup does this automatically if the file exists at install time).

---

## How it launches the kiosk

The script:
- Creates a systemd override for `getty@tty1` to autologin the `kiosk` user
- Uses `~kiosk/.bash_profile` to run `startx` only on tty1
- Uses `~kiosk/.xinitrc` to start `openbox-session`
- Uses Openbox `autostart` to run Chromium with kiosk-safe flags

This approach works on both Standard and Lite images and avoids relying on a desktop display manager.

---

## Customizing Chromium

Chromium flags used (in Openbox autostart):
- `--kiosk --start-fullscreen --no-first-run --noerrdialogs --disable-infobars`
- `--incognito --disable-translate --overscroll-history-navigation=0`

You can also deploy Chromium JSON policies in `/etc/chromium/policies/managed/` to suppress updates, first-run, and metrics.

---

## Troubleshooting

  - The script uses `usermod -s /bin/bash kiosk` non-interactively. Ensure no plain `chsh` is present.
  - Confirm `~kiosk/.bash_profile` contains the `startx` guard for tty1 and `~kiosk/.xinitrc` exists and is executable.
  - Openbox `autostart` disables DPMS and blanking (`xset s off; -dpms; s noblank`).
  - The script installs Chromium if missing and supports both `chromium-browser` and `chromium` binary names.
  - Consider adding a systemd wait-online dependency if your app requires immediate connectivity.

  ### On-screen keyboard (touchscreen kiosks)

  If you run the kiosk on a touchscreen and need an on-screen keyboard (for chat input or games that use text fields), the package and the backup installer include `onboard` and attempt to enable its auto-show behavior.

  How it works:
  - The installers install `onboard` and related accessibility backends (`at-spi2-core`, `dconf`), and add `onboard` to the Openbox autostart so it runs in the session.
  - We try to enable the per-user "auto-show when editing text" and docking settings using `gsettings` for the `kiosk` user. If `gsettings`/`dconf` is not available on your image, you can enable the settings manually.

  Manual steps (if the keyboard doesn't appear automatically):

  1. Verify `onboard` is installed:

  ```bash
  dpkg -l | grep onboard || sudo apt-get install -y onboard at-spi2-core dconf-gsettings-backend dconf-service
  ```

  2. Enable auto-show and docking for the kiosk user (run as root):

  ```bash
  sudo -u kiosk dbus-run-session gsettings set org.onboard auto-show true
  sudo -u kiosk dbus-run-session gsettings set org.onboard docking-enabled true
  ```

  3. Start `onboard` (it will run in the background):

  ```bash
  sudo -u kiosk dbus-run-session onboard &
  ```

  4. If you prefer a visible toggle button, you can create a small script to call `onboard --show` and `onboard --hide` and place a launcher in Openbox autostart or add it to your web UI.

  Notes:
  - If you use a raw IP over HTTPS (for testing), Chromium will show a certificate warning. We consider that connectivity OK for the kiosk gating logic, but in production you should use a certificate that matches the host.
  - If `onboard` still doesn't auto-show, ensure accessibility services are available (AT-SPI) and that the web app's input fields are regular HTML <input> or <textarea> elements (some custom canvas-based inputs don't trigger an OS-level text edit event).

### If you see a graphical login asking for a password on reboot

This means a display manager (greeter) took over instead of the tty1 autologin. Fix with the following and reboot:

```bash
sudo systemctl mask display-manager.service
sudo systemctl disable --now gdm3 lightdm sddm xdm greetd 2>/dev/null || true
sudo systemctl set-default multi-user.target
sudo systemctl enable getty@tty1.service
```

Verify the kiosk autologin path is intact:

```bash
sudo systemctl cat getty@tty1.service | sed -n '/\[Service\]/,$p'
grep -q 'startx' /home/kiosk/.bash_profile && echo OK: startx guard present || echo MISSING: startx guard
test -x /home/kiosk/.xinitrc && echo OK: .xinitrc executable || echo MISSING: .xinitrc
```

Then reboot:

```bash
sudo reboot
```


## Repository structure
You can supply your VPN config in any of these locations (first found wins):

- `/etc/wireguard/wg0.conf` (preferred, chmod 600)
- `/boot/wg0.conf` (copied to `/etc/wireguard/wg0.conf` on first configure/boot)
- `backup-script/secrets/wg0.conf` (intentionally tracked for now)

An example file is installed at `/usr/share/mckiosk/wg0.conf.example`.

```
.
├── backup-script/
│   ├── os_setup.sh          # One‑shot installer (fallback path)
│   └── kiosk-assets/        # Service files and helpers used by both paths
│       ├── chromium_watchdog.sh
│       ├── chromium-watchdog.service
│       ├── splashscreen.service
│       ├── remount-rootfs-ro.service
│       ├── 20auto-upgrades
│       ├── 50unattended-upgrades
│       └── usr.bin.chromium-browser
├── debian/                  # Packaging for mckiosk-base (.deb)
└── README.md
```

About the .deb packaging
- `debian/rules` installs systemd units with `--no-start` so services are enabled but not started during install.
- `debian/mckiosk-base.postinst` performs user creation, autologin override, X/Openbox session files, enables services, sets a UFW baseline, and installs/enforces the Chromium AppArmor profile (enforcement deferred if the kernel isn’t AppArmor‑enabled yet—cmdline is amended to enable it on next boot).

---

## Roadmap / Nice to have

- Systemd user session instead of `~/.bash_profile` for starting X (cleaner)
- OverlayFS/overlayroot for a fully read-only system with writable overlays
- On-screen keyboard for touch-only setups
- Network health checks and captive portal handling
- Centralized log shipping (e.g., journald remote or Fluent Bit)
