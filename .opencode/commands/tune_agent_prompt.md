---
description: One hill-climb prompt iteration for an agent — analyze failures, mutate ONE thing, verify keep/revert
---

Prompt tuning iteration for agent `$ARGUMENTS`.

## 1. Evidence

Read the LATEST `eval/results/*/scores.json` + per-task `output.txt`/`trace.json` and
`notes.md` if present. Classify every failure with skill `slm-factory.failure-taxonomy`.
If no prior run exists, run `/eval_agent <id>` first — never tune blind.

## 2. Mutate exactly one thing

Pick the DOMINANT failure class. Apply its prescribed mutation to `.opencode/agents/<id>.md`
following skill `slm-factory.tiny-prompt-patterns`. Constraints:
- One mutation class per iteration (no drive-by rewrites).
- Prompt stays ≤25 lines; depth goes to skills, not here.
- Never widen permissions as a "fix".

## 3. Verify

Re-run failed subset first (fast signal):
`./eval/run_suite.sh --agent <id> --suite <suite> --label "iter-<n>-<mutation>"`
then a full suite only if the subset improved.

## 4. Hill-climb decision

- Improved → KEEP. Record `{iter, mutation, delta}` in `eval/results/<run>/notes.md`.
- Flat/worse → REVERT the edit (git checkout or inverse edit), record why.
- Two consecutive failures on the same class → stop and recommend model swap (`/tune_agent_model`).

Report: class targeted, exact diff made, before/after rates, keep-or-revert.
