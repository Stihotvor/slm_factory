---
name: slm-factory.tiny-prompt-patterns
description: Prompt-writing doctrine for 1.7–4B SLM subagents — checklist style, explicit tool rules, output contracts, skill-deferral phrasing. Consult before writing or mutating any subject agent's system prompt.
---

# Tiny-Model Prompting Doctrine

SLMs follow structure, not prose. Every rule below exists because its violation is a common
failure class (see slm-factory.failure-taxonomy).

## Structure rules

1. **≤ ~25 lines.** Long prompts get truncated on Asus-class ctx budgets and diluted everywhere else.
   Depth goes into skills, not the prompt.
2. **Checklist > paragraphs.** One job per line, imperative voice: "Read X. Then do Y."
3. **Number the steps** for multi-step flows — SLMs skip steps in unordered lists.
4. **Repeat the critical rule last** (recency wins): output contract, stop condition, or the #1 ban.
5. **Explicit tool whitelist**: "Use only read/glob/grep." Unnamed tools WILL be tried by a 4B model.
6. **Output contract inline with an example**:
   `Reply with ONLY JSON {"version": "<v>"} — no prose, no markdown fences.`

## Behavioral rules

7. **Ban filler explicitly**: "No preamble, no restating the task, one short paragraph max."
8. **Stop condition**: tell it when to stop ("Reply DONE after writing the file") — otherwise it loops.
9. **Uncertainty routing**: "If information is missing, reply MISSING:<what>" instead of guessing.
   SLMs hallucinate paths/IDs rather than ask.
10. **Skill deferral must be a pointer, not hope**: "Before editing files under src/, consult skill
    `<agent>.<skill>`." Tiny models will NOT discover skills unprompted.

## Anti-patterns

- Few-shot examples of 3+ turns (eats context, models copy format over content) — 1 example max.
- Politeness, role backstory, motivation text ("You are a brilliant helpful...") — zero effect at this scale.
- Nested conditionals ("if A then B unless C except D") — flatten into numbered branches.
- Relying on `ask` permissions mid-run in headless evals — use explicit allow/deny lists.

## Temperature

Set `temperature: 0.1`–`0.3` in agent frontmatter for deterministic eval behavior; higher only
for T3 judgment tasks.
