# Prerequisites

## Primary: GitHub Codespaces (recommended)

You do not need to install anything. All you need is a GitHub account.

1. Open the lab repo: `github.com/build-deploy-own/dc34-lab`
2. Click **Code → Codespaces → Create codespace on main**
3. Wait 3-4 minutes for the environment to build

When it finishes you will see a VSCode window in your browser. Open the
terminal (`Ctrl+`` ` or **Terminal → New Terminal**) and verify:

```bash
npm config get registry
# Expected: http://localhost:4873/

gh auth status
# Expected: logged in as lab-dev-victim

ls ~/actions-runner/
# Expected: runner agent files (config.sh, run.sh, etc.)
```

If all three pass, you are ready. Skip the OVA section below.

---

## Backup: OVA (if Codespaces is not available)

Use this only if you cannot access Codespaces or if the wifi is down.

**Requirements:** VirtualBox 7.x or VMware Fusion (Mac) / VMware Workstation
(Windows/Linux). The instructor has USB drives with the OVA.

1. **Import:** File → Import Appliance → select `DC34-Lab-VM.ova`
2. **Boot** the VM. It autologins as user `lab`.
3. Open a terminal and verify the same three commands above.

> **Apple Silicon (M1/M2/M3 Mac):** use VMware Fusion, not VirtualBox.
> VirtualBox support on Apple Silicon is experimental.

---

## What is already set up for you

Both Codespaces and the OVA come with everything pre-installed:

| What | Where |
|---|---|
| Lab npm registry (Verdaccio) | `http://localhost:4873` |
| Malicious package | pre-published to that registry |
| GitHub Actions runner agent | `~/actions-runner/` (not registered yet) |
| Mock corporate project | `~/project/` |
| Pre-seeded victim credentials | `~/.config/gh/`, `~/project/.env`, `~/.npmrc` |

---

## What you will need

- **Module 1:** nothing extra. Everything runs locally.
- **Module 2:** a free GitHub account. If you do not have one, create it now
  at `github.com`. The instructor will give you a runner registration token
  at the start of Module 2.
- **Module 3:** watch only. No account or setup required.