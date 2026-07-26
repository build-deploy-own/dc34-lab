# Module 2: Privilege Escalation

**Time:** 5 min context + 50 min lab + 10 min detection

**Objective:** Escalate from a developer PAT to CI pipeline secrets by
hijacking a mutable GitHub Actions tag and planting a git hook on the runner.

**Real-world anchor:** CVE-2025-30066 (March 2025). The `tj-actions/changed-files`
action was compromised via tag hijacking. A modified version read secrets from
the `Runner.Worker` process memory — visible in plaintext even though GitHub
Actions logs showed `***`. Over 23,000 repositories were affected.

---

## Before you start: register your runner [YOU DO — 3 min]

The instructor will give you a registration token at the start of this module.

```bash
# In Codespaces
bash ~/actions-runner/register-runner.sh <TOKEN_FROM_INSTRUCTOR>

# In the OVA
bash ~/lab/vm-setup/register-runner.sh <TOKEN_FROM_INSTRUCTOR>
```

Verify it appears online:

```bash
gh api orgs/pipebreach-internal-labs/actions/runners \
  --jq '.runners[] | {name, status}'
# Your runner should show status: "online"
```

---

## Step 1: Enumerate the target org [YOU DO]

```bash
# List all repos
gh repo list pipebreach-internal-labs

# Read the vulnerable workflow
gh api repos/pipebreach-internal-labs/service-app/contents/.github/workflows/build.yml \
  --jq '.content' | base64 -d
```

Find and note:
- Which action does the workflow consume, at what ref?
- What `permissions` does the job declare?
- What secret is referenced in the environment?

---

## Step 2: Understand tag mutability [READ]

A Git tag is a pointer to a commit SHA. It is **not** immutable.

```bash
git tag -f v1 <different-sha>
git push --force origin v1
```

A workflow that says `uses: org/action@v1` fetches whatever that tag
points to **at runtime** — not what was there when the workflow was written.
This is the root cause of CVE-2025-30066.

```yaml
# Vulnerable — tag can be moved without touching this file
uses: org/action@v1

# Safe — SHA is immutable, cannot be force-pushed
uses: org/action@a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2
```

Check what `v1` currently points to:

```bash
gh api repos/pipebreach-internal-labs/internal-action/git/refs/tags \
  --jq '.[] | "\(.ref) → \(.object.sha)"'
```

---

## Step 3: Instructor demo on the live ORG

> [INSTRUCTOR DEMO — watch the full attack sequence on
> `pipebreach-internal-labs`. The instructor will demonstrate each step
> and explain what is happening at the runner level.]

Observe:
- The force-push moves `v1` to a different commit
- `service-app`'s workflow is unchanged — it still says `@v1`
- On the next run, the runner pulls the new commit at checkout
- GitHub Actions logs show `DEPLOY_TOKEN: ***`
- The dead-drop repo shows the actual token value

---

## Step 4: Replicate on your own repos [YOU DO — 10 min]

```bash
# 1. Fork the template repos on github.com:
#    pipebreach-internal-labs/my-internal-action → your account
#    pipebreach-internal-labs/my-service-app     → your account

# 2. In your fork of my-service-app, edit build.yml:
#    replace the org name with your own GitHub username

# 3. Add a test secret
gh secret set DEPLOY_TOKEN \
  --body "test-secret-lab-value" \
  --repo <your-username>/my-service-app

# 4. Follow the same steps the instructor just demonstrated,
#    against your own repos
```

**Checkpoint:** your dead-drop should contain `test-secret-lab-value`.

---

## Detection Discussion (10 min)

Open `detection/m2-detection.md` for the full technical reference,
including audit log queries, process tree analysis, and detection rules.
Discussion starters:

- **Rule M2-1:** a force-push to a tag in an action repo with no
  accompanying GitHub Release is the single highest-fidelity signal —
  it fires *before* any code runs
- **Rule M2-2:** the resolved action SHA changing while the consuming
  workflow is unchanged is the attack's exact signature
- **Rule M2-4:** credential file reads during a CI job
  (`~/.config/gh/hosts.yml`, `~/.npmrc`, `.env`) have near-zero
  false-positive rate — a build has no reason to read developer secrets
- **Rule M2-7:** the downloaded action source in
  `_work/_actions/<owner>/<repo>/<ref>/` is on disk even after the
  attacker moves the tag back — check `_diag/` and that directory

The most important takeaway: Rule M2-1 fires before the secret is
exposed. Everything from Step 3 onward is post-execution.