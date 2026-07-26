# Module 3: Persistence

**Time:** 5 min context + 40 min instructor demo + 10 min detection

**Delivery:** Instructor demo. Watch and take notes.
Full step-by-step instructions are in the take-home materials.

**Objective:** Understand how CI-level access obtained in Module 2
becomes durable and spreads across the organization.

**Real-world anchor:** Shai-Hulud (September 2025) was the first
self-replicating worm observed in a major public npm registry. It
dropped a workflow file into target repositories for persistent future
execution and used TruffleHog to discover secrets across the codebase.
Version 2.0 (November 2025) moved its trigger from `postinstall` to
`preinstall`, widening impact to developer machines and CI pipelines.

---

## Context: what the CI token can reach

The `DEPLOY_TOKEN` captured in Module 2 has `contents: write` and
`id-token: write` on `service-app`. From that starting point:

- Enumerate self-hosted runners registered to the org
- Discover service account PATs stored on runner filesystems
- Write to the runner's `.env` and `.path` files — code that runs
  before and after every future job, invisible from GitHub's UI
- Propagate to other repositories the token can reach

---

## What the instructor will demonstrate

### Phase 1: Assess the access
> [INSTRUCTOR DEMO]

Enumerate what the captured token can reach: runners, repo permissions,
and available scopes. Watch how `breadth-first` API access differs from
normal developer API use — this difference is itself a detection signal
(Rule M3-10).

### Phase 2: Establish persistence
> [INSTRUCTOR DEMO]

A mechanism is planted that survives runner restarts. The runner is
restarted live. The payload is still active.

Key detail: `ACTIONS_RUNNER_HOOK_JOB_STARTED` and
`ACTIONS_RUNNER_HOOK_JOB_COMPLETED` are legitimate runner features that
execute a script before and after **every job**, outside any workflow
definition. Nothing in any repository references them. An attacker who
sets one in `~/actions-runner/.env` has persistent code execution with
no artifact visible from GitHub's side.

### Phase 3: Propagate within the sandbox
> [INSTRUCTOR DEMO]

The payload propagates to `dummy-01`, `dummy-02`, `dummy-03`. These are
the only repos the token can reach — containment is enforced by token
scope. A planted workflow file in each repo is self-executing from this
point forward, independent of the runner.

### Phase 4: Cover tracks
> [INSTRUCTOR DEMO]

Workflow run history is deleted via the GitHub API
(`DELETE /repos/{owner}/{repo}/actions/runs/{id}`). The runs disappear
from the GitHub UI.

What the attacker cannot remove:
- The planted workflow files in `dummy-01..03`
- The `~/actions-runner/.env` hook
- The `_diag/Runner_*.log` files on the runner host
- Streamed audit log events already off-host

### Phase 5: The full org picture
> [INSTRUCTOR DEMO — instructor account only]

The org inventory script runs across all repos. This is what an attacker
with this access level can see in a real organization.

---

## Detection Discussion (10 min)

Open `detection/m3-detection.md` for the full technical reference.
Discussion starters:

- **Rule M3-1:** `run_number` is monotonically incrementing and never
  reused. A gap in the sequence is unambiguous evidence of deletion —
  no benign mechanism produces one. This is the highest-fidelity signal
  in Module 3 and costs one API call.

- **Rule M3-3/M3-4:** the runner host's `.env` and `.path` files, and
  the `ACTIONS_RUNNER_HOOK_JOB_*` variables, are the persistence
  mechanisms that survive API-level cleanup. Audit them continuously —
  after provisioning they should never change.

- **Rule M3-6:** a workflow file added to a previously dormant repo by
  a non-developer identity, without a pull request, is close to a
  definitional violation. Dormant repos are the propagation targets
  precisely because nobody hardened them.

- **Rule M3-9:** `DELETE /repos/{owner}/{repo}/actions/runs/{id}` is
  called zero times per year in most organizations. Alert on the first
  occurrence, not on a rate threshold.

The inversion worth remembering: the strongest signal (M3-1, the
`run_number` gap) only appears at the *end*, after the damage. The
earliest phase signals (M3-10, breadth-first enumeration) are noisier
but fire while the attack is still in progress.

---

## Take-home

Everything you need to replicate Module 3 in your own environment is in
the stubs under `payloads/m3-*/`. You will need:

- A GitHub org you control
- A self-hosted runner registered to that org
- 2-3 target repos seeded with dummy content

The `detection/m3-detection.md` reference includes the exact commands
to validate each phase of the attack and each detection signal.