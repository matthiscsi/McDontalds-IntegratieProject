#!/usr/bin/env bash
set -euo pipefail

LOCKFILE=/run/wg-keepalive.lock
exec 9>"$LOCKFILE" || true
flock -n 9 || { echo "[wg-keepalive] Another instance running."; exit 0; }

log() { logger -t wg-keepalive "$*"; echo "[wg-keepalive] $*"; }

# Ensure service exists
if ! systemctl list-unit-files | grep -q '^wg-quick@\.service'; then
  log "wg-quick template unit not found"
fi

while true; do
  if ip link show wg0 >/dev/null 2>&1; then
    # Optional: verify we can reach the VPN DNS, adjust to your environment
    if ping -c1 -W1 10.8.0.1 >/dev/null 2>&1; then
      sleep 10
      continue
    fi
    log "wg0 up but VPN DNS unreachable; restarting wg-quick@wg0"
  else
    log "wg0 interface down; starting wg-quick@wg0"
  fi
  systemctl restart wg-quick@wg0.service || systemctl start wg-quick@wg0.service || true
  sleep 5
done
