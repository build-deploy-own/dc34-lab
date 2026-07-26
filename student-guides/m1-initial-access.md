# Module 1: Initial Access

**Time:** 45 min hands-on + 15 min detection discussion

**Objective:** See how a malicious npm package can run code on a developer
machine during a routine `npm install`, and capture credentials silently.

**Real-world anchor:** In August 2025, a widely-used npm package had its
postinstall script modified to scan developer machines for stored credentials
and configuration files. It was the first known attack to also target AI CLI
tool configurations as a credential source.

---

## Step 1: Inspect the package [YOU DO]

Open the malicious package in VSCode:

```bash
# In Codespaces
code /workspaces/dc34-lab/payloads/m1/

# In the OVA
code ~/lab/payloads/m1/
```

Look at `package.json`. Find the `scripts.postinstall` field.

**Answer these before we proceed:**
- What does `postinstall` do, and when exactly does it run?
- What files on a developer machine would be valuable to an attacker?
- Would you notice this running during `npm install`?

---

## Step 2: Trigger the install [YOU DO]

```bash
cd ~/project
npm install
```

Watch the terminal output carefully. Something is running that you did
not explicitly ask for.

---

## Step 3: Instructor walkthrough

> [INSTRUCTOR DEMO — the instructor walks through what just executed
> and shows the result in the dead-drop repo]

---

## Step 4: Validate what was captured [YOU DO]

```bash
# What does the PAT give access to?
gh auth status
gh repo list pipebreach-internal-labs
```

The PAT that was just "captured" is your entry point into the target
organization. **Keep this terminal open — you will use it in Module 2.**

---

## Detection Discussion (15 min)

Open `detection/m1-detection.md` for the full technical reference.
Discussion starters:

- **Lockfile drift:** did `package-lock.json` change for a package you
  did not intentionally update?
- **Lifecycle script egress:** a postinstall hook making an outbound
  HTTPS call is anomalous for almost every legitimate package
- **Registry mismatch:** the package was served from a non-corporate
  registry — would your tooling have caught that?
- **Process read of credential paths:** a build tool reading
  `~/.config/gh/hosts.yml` or `~/.npmrc` outside of a git or npm
  operation is a near-zero-false-positive signal