#!/bin/bash
# Module 2 — Register your self-hosted runner
# Usage: ./register-runner.sh <TOKEN_FROM_INSTRUCTOR>

ORG_URL="https://github.com/pipebreach-internal-labs"
LABEL="lab"

if [ -z "$1" ]; then
  echo "Usage: ./register-runner.sh <TOKEN>"
  echo "The instructor will give you the token at the start of Module 2."
  exit 1
fi

cd ~/actions-runner

echo "[*] Configuring runner..."
./config.sh \
  --url "$ORG_URL" \
  --token "$1" \
  --labels "$LABEL" \
  --name "lab-runner-$(hostname)" \
  --unattended

echo "[*] Starting runner..."
./run.sh &
echo "[*] Runner PID: $!"
echo "[*] Verify at: $ORG_URL/settings/actions/runners"
