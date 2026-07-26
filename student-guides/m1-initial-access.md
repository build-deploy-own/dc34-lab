# Module 1: Initial Access

**Time:** 45 min hands-on + 15 min detection discussion

**Objective:** See how a malicious dependency can run code on a developer
machine during a routine `npm install`, and how credentials can be captured
from a developer environment.

**Real-world anchor:** A 2025 incident involved a widely-used npm package
whose postinstall script scanned developer machines for stored credentials
and configuration files. It was notable for also targeting AI CLI tool
configurations — a new credential surface that defenders often overlook.

---

## Step 1: Inspect the package [STUDENT DOES]

Open VSCode and explore the `corp-logger-utils` package:
```bash
code ~/lab/payloads/m1/
```

Look at `package.json`. Find the `postinstall` field.

Questions to answer before we proceed:
- What does `postinstall` do and when does it run?
- What files on a developer machine might be valuable to an attacker?
- Would you notice this running during `npm install`?

---

## Step 2: Trigger the install [STUDENT DOES]

```bash
cd ~/project
npm install
```

Watch the terminal output carefully.

---

## Step 3: Instructor walkthrough

> [INSTRUCTOR DEMO — the instructor walks through what just ran and
> shows the output in the dead-drop repo]

---

## Step 4: What did we capture?

Check what the lab PAT gives access to:
```bash
gh auth status
gh repo list pipebreach-internal-labs
```

This PAT is your entry point into the target organization.
**Keep this terminal open — you will use this in Module 2.**

---

## Detection Discussion (15 min)

With only npm logs, the modified `package.json`, and network traffic —
how would you detect this as a defender?

- **Lockfile drift:** `package-lock.json` changed unexpectedly
- **Lifecycle script anomaly:** a postinstall script making outbound network calls
- **Registry mismatch:** package not found in the corporate registry
- **Outbound connection:** unexpected HTTPS call during `npm install`
