#!/usr/bin/env bash
# Run OS updates before kiosk session starts. Intended to be ordered before getty@tty1
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

log() { echo "[kiosk-preupdate] $*" | systemd-cat -t kiosk-preupdate || echo "[kiosk-preupdate] $*"; }

# Wait for network (best-effort), up to ~10 minutes total
attempts=0
until curl -I --silent --max-time 5 https://deb.debian.org >/dev/null 2>&1 || ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; do
  attempts=$((attempts+1))
  if [ "$attempts" -ge 300 ]; then
    log "Network not ready after prolonged wait; proceeding without update"
    break
  fi
  sleep 2
done

log "Updating apt indexes..."
if ! apt-get update -y; then
  log "apt-get update failed; retrying once..."
  sleep 5
  apt-get update -y || log "apt-get update failed again; continuing"
fi

log "Applying upgrades (non-interactive)..."
# Safer than dist-upgrade; avoids removals. Security/hotfixes will be applied.
apt-get -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef upgrade || true

# If a reboot is required, trigger it now to ensure patched state
if [ -f /var/run/reboot-required ]; then
  log "Reboot required after updates; rebooting now before kiosk starts"
  systemctl reboot
  exit 0
fi

log "Pre-update complete; continuing boot"
exit 0
