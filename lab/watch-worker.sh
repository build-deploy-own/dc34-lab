#!/usr/bin/env bash
#
# watch-worker.sh - wait for a job to land on this runner, then scan its memory.
#
# Usage:  sudo ./watch-worker.sh <SENTINEL>
#
# Start this on the runner BEFORE pushing. The lint and test jobs run first on
# GitHub-hosted runners, so several minutes pass before the build job reaches
# this host. Typing the scan by hand once the window opens means racing a
# 90-second timer on stage; this waits for you.
#
# The delay after the worker appears lets the validator step finish, so the
# scan lands while the holding step is running rather than during setup.

set -uo pipefail

SENTINEL="${1:?usage: sudo ./watch-worker.sh <SENTINEL>}"
SETTLE="${2:-25}"
SCANNER="$(dirname "$0")/sentinel-scan.py"

echo "Waiting for Runner.Worker..."
until WPID=$(pgrep -f Runner.Worker | head -1); [ -n "${WPID}" ]; do
  sleep 1
done

echo "Worker detected: PID ${WPID}. Settling for ${SETTLE}s..."
sleep "${SETTLE}"

clear
echo "Worker PID: ${WPID}"
echo
sudo python3 "${SCANNER}" "${WPID}" "${SENTINEL}"
