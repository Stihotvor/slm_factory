---
description: Extract recurring agent knowledge into <agent>.<skill> files, wire pointers, A/B verify
---

Skill extraction pass for agent `$ARGUMENTS`.

## 1. Mine failures

Scan ALL `eval/results/*/` runs for this agent. Group by failure class 10 (`KNOWLEDGE_GAP`,
per skill `slm-factory.failure-taxonomy`): right procedure, wrong facts/conventions/habits,
appearing **≥2 times**. Classes 1–9 are NOT skill material — route them to `/tune_agent_prompt`
or backend config.

## 2. Extract

For each confirmed pattern follow skill `slm-factory.extraction-rules` exactly:
- `.opencode/skills/<agent-id>.<skill-name>/SKILL.md`, ≤80 lines, procedure + facts + tables.
- Dedup: check existing `.opencode/skills/<agent-id>.*` first; extend rather than duplicate.

## 3. Wire

Add ONE pointer line to the agent prompt at the relevant step:
"Before <action>, consult skill `<agent-id>.<skill-name>`."

## 4. A/B verify (mandatory)

Re-run ONLY the tasks that exhibited the gap with the skill wired in; then spot-check
2 previously-passing tasks for regression. Keep only if both hold — otherwise delete the
skill file AND the pointer line, and log the rejection in notes.md.

Report: skills created/rejected, evidence counts, A/B deltas.
