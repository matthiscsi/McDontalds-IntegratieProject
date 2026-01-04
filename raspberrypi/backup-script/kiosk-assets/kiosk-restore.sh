#!/usr/bin/env bash
# Restore kiosk Chromium session after escape
# Usage: sudo kiosk-restore.sh
set -euo pipefail

# Optionally unmask getty if it was masked
# systemctl unmask getty@tty1.service || true

systemctl start chromium-watchdog.service || true
# Relaunch startx for kiosk if on tty1 and not running
if ! pgrep -u kiosk -x startx >/dev/null; then
  sudo -u kiosk bash -lc 'if [ -z "$DISPLAY" ]; then startx >/home/kiosk/.xsession-errors 2>&1 & fi'
fi

echo "[kiosk-restore] Kiosk restarted."
