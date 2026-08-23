---
name: slm-factory.extraction-rules
description: When and how to distill recurring subagent knowledge into skill files named <agent_name>.<skill_name>, with A/B verification and pruning policy. Consult during /tune_agent_skills.
---

# Skill Extraction Rules

## Trigger

Extract a new skill ONLY when the same knowledge gap appears **≥2 times** across tasks or
iterations (per slm-factory.failure-taxonomy class 10). One-off gaps get one prompt line, not a file.

## Naming & location

- Directory: `.opencode/skills/<agent_name>.<skill_name>/SKILL.md`
- `agent_name` = subject agent id; `skill_name` = kebab-case flow/convention name.
  Examples: `repo-scout.python-conventions`, `doc-writer.mkdocs-material`.
- Frontmatter: `name:` must equal the directory name; `description:` one sentence starting with a verb.

## Content rules

- SKILL.md = procedure + facts the SLM cannot derive: conventions, paths, command sequences,
  decision tables. NOT restatements of the prompt.
- ≤80 lines; tables over prose; concrete examples over abstract rules.
- If content exceeds ~80 lines → split into two skills by concern.

## Wiring into the agent

Add ONE pointer line to the agent's system prompt at the relevant step:
`Before <action>, consult skill <agent_name>.<skill_name>.`
Never paste skill content into the prompt — that defeats the purpose.

## A/B verification (mandatory)

1. Re-run ONLY the failing subset with the skill wired in.
2. Keep the skill if those tasks pass AND previously-passing spot-checked tasks still pass.
3. Otherwise delete the skill and log why — a skill that doesn't pay rent is context pollution.

## Pruning

At `/promote_agent` time: any extracted skill whose tasks all pass in its absence for 2 consecutive
full runs → candidate for removal. Verify by removal run before deleting.
