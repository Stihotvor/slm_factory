---
name: slm-factory.failure-taxonomy
description: Classification of SLM subagent failures mapped to the correct mutation (prompt vs skill vs model vs permissions vs backend config). Consult when analyzing eval traces before any tune_* action.
---

# Failure Taxonomy → Mutation Map

Read the traces (`eval/results/<run>/T*/output.txt`, `trace.json`), classify EVERY failure,
then apply the mutation the class prescribes. Never mutate blindly.

| # | Class | Signature in trace | First-choice mutation |
|---|---|---|---|
| 1 | `TOOL_PARSE_FAIL` | tool call with malformed/missing args; server 4xx on tool schema | Prompt: add explicit argument example. If persistent across prompts → **model swap** (chat template can't do FC) |
| 2 | `WRONG_TOOL` | used bash where read suffices; wrote instead of edit | Prompt: tighten tool whitelist line |
| 3 | `HALLUCINATED_PATH` | invents file names, skips reading, "answers" from imagination | Prompt: rule 9 ("reply MISSING:<what>") + force read-before-answer step |
| 4 | `FORMAT_VIOLATION` | prose around JSON, markdown fences around data | Prompt: repeat output contract at END of prompt with example |
| 5 | `STEP_SKIP` | multi-step task, middle step never happened | Prompt: number steps; add per-step DONE markers |
| 6 | `LOOP_REPEAT` | same tool call ≥3× identical args | Prompt: stop condition. Persistent → **model swap** |
| 7 | `CTX_OVERFLOW` | early instructions ignored, later followed (truncation symptom) | **Backend config**: raise OLLAMA_CONTEXT_LENGTH / LM Studio load ctx — NOT a prompt fix |
| 8 | `PERMISSION_ABUSE` | attempts denied tools, or destructive ops outside task scope | Permissions: narrow allow-list. If it fights the fence → model swap |
| 9 | `REFUSAL_OVERCAUTION` | "I cannot modify files" for an allowed op | Prompt: explicit permission statement ("You ARE allowed to edit files in cwd") |
| 10 | `KNOWLEDGE_GAP` | right procedure, wrong domain facts/conventions, ≥2 occurrences | **Skill extraction** (slm-factory.extraction-rules) |

## Decision order

1. Backend/config classes first (7) — free fixes, no agent edits.
2. Permission classes (8) — security before capability.
3. Prompt mutations (1–6, 9) — one variable per iteration.
4. Model swap — only after ≥2 failed prompt iterations on the same class.
5. Skill extraction (10) — highest-value, most durable fix; do it last so the pattern is confirmed.

## Bookkeeping

Log every failure as `{task_id, class, evidence_line}` in the iteration notes
(`eval/results/<run>/notes.md`) so `/optimize_agent` can pick the dominant class next round.
