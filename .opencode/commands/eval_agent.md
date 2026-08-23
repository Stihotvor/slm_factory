---
description: Run the eval suite for an agent, score it, grade judgment tasks, and report — no mutations
---

Score-only evaluation of agent `$ARGUMENTS` (format: `<agent-id> [suite-dir]`, default suite
`eval/tasks/<agent-id>` falling back to `eval/tasks/default`).

## Procedure

1. **Run the suite headless:**
   `./eval/run_suite.sh --agent <id> --suite <dir> --backend auto`
   (add `--model provider/key` to override the pin; use `--backend none` for cloud models).
2. **Grade T3 / `judge_required` tasks yourself**: read `eval/results/<run>/T3-*/output.txt`,
   score 0–100 against the task prompt's grading note, then re-score:
   `python3 ./eval/score.py --out <run-dir> --suite <dir> --label <same-label> --judge T3-01:NN --judge T3-02:NN`
3. **Report**: run `python3 ./eval/report.py --last 5` and present the table.
4. Flag explicitly: permission violations (must be zero), `needs_judge` leftovers, tasks whose
   failure class you can already name (consult skill `slm-factory.failure-taxonomy`) — but do NOT
   mutate anything; this command is measurement only.

Finish with a one-line verdict: pass / needs tuning / broken (and which class dominates).
