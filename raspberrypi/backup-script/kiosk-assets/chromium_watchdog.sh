#!/bin/bash
# Chromium watchdog: ensures Chromium is running in kiosk mode on DISPLAY=:0
# Runs under user 'kiosk' via systemd. Safe to call repeatedly.

set -euo pipefail

# Wait for X to be ready
for i in $(seq 1 60); do
  if [ -S /tmp/.X11-unix/X0 ] || [ -n "${DISPLAY:-}" ]; then
    break
  fi
  sleep 1
done

# Determine target URL (fallback to file or default)
TARGET_URL="http://192.168.68.186"
if [ -s /etc/mckiosk/target-url ]; then
  TARGET_URL=$(head -n1 /etc/mckiosk/target-url | tr -d '\r')
fi
case "$TARGET_URL" in
  http://*|https://*) ;;
  *) TARGET_URL="http://$TARGET_URL" ;;
esac

# Common Chromium flags for kiosk
FLAGS=(
  --no-first-run
  --noerrdialogs
  --disable-infobars
  --start-fullscreen
  --kiosk
  --incognito
  --disable-translate
  --overscroll-history-navigation=0
)

launch_chromium() {
  if command -v chromium-browser >/dev/null 2>&1; then
    chromium-browser "${FLAGS[@]}" "$TARGET_URL" &
  elif command -v chromium >/dev/null 2>&1; then
    chromium "${FLAGS[@]}" "$TARGET_URL" &
  else
    echo "[watchdog] Chromium not found in PATH" >&2
    return 1
  fi
}

# Main loop: if Chromium exited/crashed, relaunch it
while true; do
  if ! pgrep -x chromium-browser >/dev/null 2>&1 && ! pgrep -x chromium >/dev/null 2>&1; then
    echo "[watchdog] Chromium not running, starting..."
    launch_chromium || true
  fi
  sleep 5
done
