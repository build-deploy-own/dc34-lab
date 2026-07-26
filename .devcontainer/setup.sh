#!/bin/bash
# .devcontainer/setup.sh
# Runs ONCE when the Codespace is first created.
set -e

WORKDIR="/workspaces/dc34-lab"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   DC34 — CI/CD Weaponization Workshop               ║"
echo "║   Setting up lab environment...                     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Verdaccio ────────────────────────────────────────────────
echo "[1/6] Installing Verdaccio..."
sudo npm install -g verdaccio --silent

mkdir -p ~/.config/verdaccio/storage
cp "$WORKDIR/verdaccio/config.yaml" ~/.config/verdaccio/config.yaml

echo "[2/6] Starting Verdaccio..."
verdaccio --config ~/.config/verdaccio/config.yaml &>/tmp/verdaccio.log &
sleep 3

# ── npm registry ─────────────────────────────────────────────
echo "[3/6] Configuring npm to use lab registry..."
cat > ~/.npmrc << 'NPMRC'
registry=http://localhost:4873/
//localhost:4873/:_authToken=lab-token-fake
//registry.npmjs.org/:_authToken=npm_FAKE_TOKEN_LAB_ONLY
NPMRC

# ── GitHub Actions runner ─────────────────────────────────────
echo "[4/6] Downloading GitHub Actions runner agent..."
mkdir -p ~/actions-runner && cd ~/actions-runner
RUNNER_VERSION="2.316.1"
curl -fsSL -o runner.tar.gz \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
tar xzf runner.tar.gz && rm runner.tar.gz
sudo ./bin/installdependencies.sh -y &>/dev/null || true
cp "$WORKDIR/.devcontainer/register-runner.sh" ~/actions-runner/register-runner.sh
chmod +x ~/actions-runner/register-runner.sh
cd ~

# ── Victim developer environment ──────────────────────────────
echo "[5/6] Seeding victim developer environment..."

mkdir -p ~/.config/gh
cat > ~/.config/gh/hosts.yml << GHCONF
github.com:
  oauth_token: ${LAB_PAT:-REPLACE_WITH_LAB_PAT}
  git_protocol: https
  user: lab-dev-victim
GHCONF

mkdir -p ~/.ssh
cat > ~/.ssh/id_ed25519 << 'SSHKEY'
-----BEGIN OPENSSH PRIVATE KEY-----
FAKE_KEY_LAB_ONLY_NOT_A_REAL_KEY_DO_NOT_USE
-----END OPENSSH PRIVATE KEY-----
SSHKEY
chmod 600 ~/.ssh/id_ed25519

mkdir -p ~/project
cp -r "$WORKDIR/payloads/m1/." ~/project/corp-logger-utils/
cat > ~/project/.env << 'ENV'
# LAB ONLY — ALL VALUES ARE FAKE
NODE_ENV=development
PORT=3000
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7FAKE_LAB
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/FAKE_LAB
DATABASE_URL=postgres://admin:FAKE_PASSWORD@db.internal:5432/billing
DEPLOY_TOKEN=ghp_FAKE_DEPLOY_TOKEN_LAB_ONLY_NOT_REAL
SLACK_WEBHOOK=https://hooks.slack.com/services/FAKE/FAKE/FAKE
ENV

mkdir -p ~/.config/claude
cat > ~/.config/claude/config.json << 'AICONF'
{ "api_key": "sk-ant-FAKE_KEY_LAB_ONLY", "model": "claude-opus-4-6" }
AICONF

# ── Publish lab package to Verdaccio ─────────────────────────
echo "[6/6] Publishing corp-logger-utils to lab registry..."
cd ~/project/corp-logger-utils

# Add user to Verdaccio (silent)
(echo -e "lab\nlab\nlab@lab.local" | \
  npm adduser --registry http://localhost:4873 2>/dev/null) || true

npm publish --registry http://localhost:4873 2>/dev/null || true
cd ~

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Lab environment ready                             ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║   npm registry : http://localhost:4873              ║"
echo "║   runner agent : ~/actions-runner/                  ║"
echo "║   victim env   : ~/project/                         ║"
echo "║   lab files    : /workspaces/dc34-lab/              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Open the student guide: student-guides/m1-initial-access.md"
echo ""
