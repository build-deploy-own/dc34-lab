# Module 3: Persistence

**Time:** 5 min context + 40 min instructor demo + 10 min detection

**Delivery:** Instructor demo + take-home. Watch and take notes.
The take-home guide lets you replicate this in your own environment.

**Objective:** Understand how access gained in Module 2 can be extended
across an organization and made durable over time.

**Real-world anchor:** A late-2025 incident involved the first observed
self-replicating package in a major public registry. It established
persistent execution by dropping a workflow file into target repositories,
then used a secrets-scanning tool to locate credentials across the codebase.

---

## What the instructor will demonstrate

### Phase 1: Assess the access
> [INSTRUCTOR DEMO]

Starting from the token obtained in Module 2 — what does it have access to?
Enumerate runners, repository permissions, and available scopes.

### Phase 2: Establish persistence
> [INSTRUCTOR DEMO]

Plant a mechanism that survives a runner restart. Restart the runner.
Confirm the mechanism is still active.

### Phase 3: Propagate within the sandbox
> [INSTRUCTOR DEMO]

Using a token scoped only to `dummy-01`, `dummy-02`, `dummy-03` —
propagate to each of those repos. Containment is enforced by token scope,
not by the code itself. Observe what gets planted and where.

### Phase 4: Cover tracks
> [INSTRUCTOR DEMO]

Remove evidence of activity from the workflow run history.
Show the resulting gap in the audit timeline.

### Phase 5: The full org picture
> [INSTRUCTOR DEMO — instructor account only]

Run the org inventory script across all repos. Show what an attacker
with this level of access can see across the full organization.

---

## Detection Discussion (10 min)

- **Audit log gaps:** deleted runs leave missing timestamps in run history
- **Runner process tree:** unexpected long-running child processes
- **Repository diffs:** unexpected file additions in repos that were not
  being actively developed
- **API call patterns:** high volume of sequential API calls in a short window
- **Cross-repo access:** a token associated with one repo accessing several others

---

## Take-home

After the workshop, use the stubs in `payloads/m3-*/` as a starting point.
You will need a GitHub org you control, a registered self-hosted runner,
and repos to use as targets. The instructor briefing materials have the
detailed step-by-step for each phase.
