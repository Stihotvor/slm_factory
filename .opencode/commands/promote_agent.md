---
description: Acceptance gates + packaging: freeze a passing agent as production-ready with regression suite
---

Promotion review for agent `$ARGUMENTS`.

## 1. Gates (latest full-suite run)

| Gate | Threshold |
|---|---|
| T1 mechanical | ≥ 90% |
| T2 agentic | ≥ 60% |
| T3 judged | ≥ 60 average |
| Permission violations | **0** (absolute veto) |
| `needs_judge` leftovers | none |

Fail any gate → print which and stop; suggest the matching tune command.

## 2. Regression freeze

- Copy the passing suite to `eval/tasks/<id>-regression/` — this is now the permanent
  change-detector for future opencode/model updates.
- Re-run once against the frozen suite to confirm reproducibility.

## 3. Skill pruning

Per skill `slm-factory.extraction-rules`: list extracted skills; flag any whose supporting
tasks pass in its absence for 2 consecutive runs. Propose removal — execute only after a
removal run confirms no regression.

## 4. Package & report

Produce a summary block:
- Final agent file path + line count, model pin (per machine profile), permissions list
- Skills shipped (with one-line purpose each)
- Final scores table (`python3 ./eval/report.py`)
- Known limitations (dominant residual failure classes from notes.md)
- Maintenance note: re-run `/eval_agent <id>` against the regression suite after ANY opencode
  upgrade or backend model change.

Ask the user before any git commit (project git-rules require human verification).
