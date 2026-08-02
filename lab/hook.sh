#!/usr/bin/env bash
#
# hook.sh - job-started hook for CI/CD Weaponization, Module 3, Phase 2.
#
# Wired up through the runner environment file:
#   ACTIONS_RUNNER_HOOK_JOB_STARTED=/home/ubuntu/lab/hook.sh
#
# Demonstration only. It writes a marker so the room can see that something
# ran before the job, and exits clean. It touches nothing else.
#
# TWO RULES THIS FILE EXISTS TO ENFORCE
#
# 1. exit 0, unconditionally.
#    If a job-started hook exits non-zero, the JOB FAILS. Every job on this
#    runner fails from that moment on, with an error that does not mention
#    the hook. That failure mode is silent and expensive to debug on stage.
#
# 2. A marker string that does not collide with anything else in the logs.
#    Searching the runner diagnostic logs for "hook" also matches the
#    webhook URL in the Module 2 payload, which buries the evidence under
#    the injected script. [LAB-HOOK] is unambiguous.

set -uo pipefail   # deliberately NOT -e: no failure here may kill the job

MARKER="[LAB-HOOK]"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "${MARKER} pre-job hook executed at ${STAMP} on $(hostname)"
echo "${MARKER} repo=${GITHUB_REPOSITORY:-n/a} run=${GITHUB_RUN_ID:-n/a} runner=${RUNNER_NAME:-n/a}"

exit 0
