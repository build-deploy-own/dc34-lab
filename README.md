# lab/

Instructor tooling for Modules 2 and 3 of *CI/CD Weaponization: Build it, Deploy it, Own it* (DEF CON 34).

Everything here runs on the instructor's disposable runner VM. None of it is needed for the student replication, which runs entirely on GitHub-hosted runners.

| File | Used in | What it does |
|---|---|---|
| `sentinel-scan.py` | Module 2, Step 6 | Searches a live process's memory for one known value |
| `watch-worker.sh` | Module 2, Step 6 | Waits for the job to land, then runs the scan |
| `hook.sh` | Module 3, Phase 2 | Job-started hook that writes a marker and exits clean |
| `audit-workflow.yml` | Module 3, Phase 3 | The inert workflow planted into target repositories |

## Install on the runner VM

```bash
mkdir -p ~/lab
# copy the four files into ~/lab
chmod +x ~/lab/hook.sh ~/lab/watch-worker.sh

# verify the scanner parses before you rely on it
python3 -c "import ast;ast.parse(open('$HOME/lab/sentinel-scan.py').read())" && echo "syntax OK"
```

Do not create these files by pasting a long heredoc into a terminal. Long blocks truncate silently and the truncation only surfaces at runtime.

## Validate the scanner before the session

```bash
SENTINEL="<your-sentinel>" python3 -c "
import os,time
print(os.getpid(),flush=True)
time.sleep(300)" &
TESTPID=$!
sleep 1
sudo python3 ~/lab/sentinel-scan.py $TESTPID "<your-sentinel>"
kill $TESTPID
```

Against a Python process it must report ASCII matches. If that works, the scanner is fine and any later problem belongs to the runner.

## Validate the hook before the session

```bash
~/lab/hook.sh
echo "exit code: $?"     # must be 0
```

A hook that exits non-zero fails every job on the runner from that point on, with an error that does not mention the hook.

## Three things that will bite you

**The scanner returns zero in ASCII against `Runner.Worker`.** That is correct and it is the point. The runner agent is a .NET process and holds managed strings in UTF-16LE. The zero proves the value is not in the process environment block, which closes the most predictable objection from the room.

**Searching the logs for `hook` also matches `webhook`.** The Module 2 payload contains a webhook URL, so a case-insensitive search buries the hook evidence under the injected script. Search for `Pre Job Hook`, `hook.sh` or `[LAB-HOOK]` instead.

**The runner reads its environment file at agent start.** Planting the hook requires a restart to take effect at all. Run two restart cycles: the first activates it, the second demonstrates that it survives. Presenting the first restart as proof of persistence is a claim an informed attendee will catch.

## Safety

All of this runs on a throwaway VM with snapshots, against private repositories, with sentinel values rather than real credentials. The single real credential in the workshop is a fine-grained token scoped to three throwaway repositories with a one-day expiry, and it is revoked at the end of the session.
