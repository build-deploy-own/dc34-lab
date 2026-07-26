# Prerequisites

Before the workshop starts:

1. Boot the lab OVA in VirtualBox or VMware.
2. Log in: user `lab`, password `lab`.
3. Open a terminal:
   ```bash
   cd ~/lab && bash vm-setup/setup.sh
   ```
4. Verify VSCode opens: `code .`
5. Verify the lab npm registry:
   ```bash
   npm config get registry
   # Expected: http://localhost:4873/
   ```

You do not need a GitHub account for Module 1.
For Module 2 you will need a free GitHub account. Create one at github.com.

The instructor will provide:
- The lab fine-grained PAT (already in your VM)
- The runner registration token at the start of Module 2
