# Module 2: Privilege Escalation

**Time:** 5 min context + 50 min lab + 10 min detection

**Objective:** Understand how a mutable GitHub Actions tag can be used to
alter the behavior of a privileged CI workflow, and how secrets can be
exposed through the runner environment.

**Real-world anchor:** CVE-2025-30066 (March 2025) — a compromised GitHub
Action used by over 23,000 repositories. The attack leveraged mutable tags
to replace a benign action with a modified version that read secrets from
the runner process environment.

---

## Before you start: register your runner [STUDENT DOES — 3 min]

The instructor will give you a registration token at the start of this module.

```bash
bash ~/lab/vm-setup/register-runner.sh <TOKEN_FROM_INSTRUCTOR>
```

Verify it appears online:
```bash
gh api orgs/pipebreach-internal-labs/actions/runners
```

---

## Step 1: Enumerate the target org [STUDENT DOES]

```bash
# List repos
gh repo list pipebreach-internal-labs

# Read the CI workflow
gh api repos/pipebreach-internal-labs/service-app/contents/.github/workflows/build.yml \
  --jq '.content' | base64 -d
```

Find and note:
- Which action does the workflow consume, and at what ref?
- What permissions does the workflow declare?
- What secret is referenced?

---

## Step 2: Git tag mutability — key concept [STUDENT READS]

A Git tag is a pointer to a commit SHA. It is **not** immutable by default.

```bash
# Anyone with write access can do this:
git tag -f v1 <different-sha>
git push --force origin v1
```

A workflow that says `uses: org/action@v1` fetches whatever commit that
tag points to **at runtime** — not what was there when the workflow was written.

This is the root cause of CVE-2025-30066.

The fix — always pin to a full SHA:
```yaml
# Vulnerable
uses: org/action@v1

# Safe
uses: org/action@a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2
```

---

## Step 3: Instructor demo on the live ORG

> [INSTRUCTOR DEMO — watch the full attack sequence on
> `pipebreach-internal-labs`. The instructor will walk through
> each step and explain what is happening and why.]

Observe:
- How the tag is moved to point to a different commit
- What the modified action step does on the runner
- What the GitHub Actions logs show vs. what actually ran
- The runner process environment at the time of execution

---

## Step 4: Replicate on your own repos [STUDENT DOES — 10 min]

```bash
# 1. Go to github.com and fork:
#    pipebreach-internal-labs/my-internal-action  -> your account
#    pipebreach-internal-labs/my-service-app      -> your account

# 2. In your fork of my-service-app, edit the workflow:
#    change the org name to your own GitHub username

# 3. Add a test secret to your my-service-app:
gh secret set DEPLOY_TOKEN \
  --body "test-secret-lab-value" \
  --repo <your-username>/my-service-app

# 4. Clone your my-internal-action and follow the steps
#    the instructor just demonstrated
```

Checkpoint: confirm the result appears in your own dead-drop repo.

---

## Detection Discussion (10 min)

- **Audit log:** `git.push` event with `forced: true` on a tag ref
- **Workflow run:** unexpected process spawned during the run
- **Runner filesystem:** unexpected files present after a run completes
- **Repository activity:** unexpected write to a repo that should be read-only
