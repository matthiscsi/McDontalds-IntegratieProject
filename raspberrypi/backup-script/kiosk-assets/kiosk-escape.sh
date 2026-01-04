#!/usr/bin/env bash
# Secure "break-glass" to exit kiosk Chromium session
# Usage: sudo kiosk-escape.sh
set -euo pipefail

# Configure secret here (or move to /etc/kiosk-escape.conf with chmod 600)
# Set PASSWORD to a plain-text admin password. No tokens, no hashing.
PASSWORD="kiosk"
CONF_FILE="/etc/kiosk-escape.conf"

if [ -f "$CONF_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CONF_FILE"
fi

if [ -z "${PASSWORD}" ]; then
  echo "[kiosk-escape] Not configured. Set PASSWORD in $CONF_FILE"
  exit 1
fi

read -rsp "Admin password: " PW; echo

if [ "$PW" != "$PASSWORD" ]; then
  echo "[kiosk-escape] Authentication failed"
  exit 2
fi

echo "[kiosk-escape] Auth OK. Stopping kiosk session and Chromium watchdog..."
systemctl stop chromium-watchdog.service || true
# Try to kill any Chromium owned by kiosk
pkill -u kiosk -x chromium-browser 2>/dev/null || true
pkill -u kiosk -x chromium 2>/dev/null || true
# Stop X by killing startx/xinit for kiosk on tty1
pkill -u kiosk -x startx 2>/dev/null || true
pkill -u kiosk -x xinit 2>/dev/null || true

# Optionally clear autologin temporarily by masking getty
# systemctl mask getty@tty1.service || true

echo "[kiosk-escape] Kiosk stopped. You now have console control."
