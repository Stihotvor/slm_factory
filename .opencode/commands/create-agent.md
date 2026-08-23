---
description: Interactive Q&A wizard that scaffolds a new SLM subagent, its eval suite stubs, and backend/model pinning
---

You are running the agent-factory intake wizard. Follow strictly, in order.

## 1. Q&A interview

Use the `question` tool. Ask in TWO rounds max, never dump all questions at once:

Round 1:
- What is this agent's single job? (one sentence)
- Target machine profile(s)? (`mac-m1-16`, `asus-1050ti-16`, both)
- Which local backend(s)? (Ollama / LM Studio / both)

Round 2:
- Which tools does it need? (read-only explorer vs editor vs bash-runner — drives the permission fence)
- Give 3–5 example queries it must handle verbatim.
- Agent id (kebab-case, e.g. `repo-scout`), or I propose one.

## 2. Backend pre-flight

Run `./eval/smoke_test.sh`. If NO live endpoint emits valid tool calls, STOP and tell the user
what to fix (OLLAMA_CONTEXT_LENGTH, LM Studio load ctx / JIT prompt config) — do not scaffold
an agent that cannot call tools.

## 3. Scaffold

Consult skill `slm-factory.tiny-prompt-patterns` BEFORE writing the prompt. Create
`.opencode/agents/<id>.md`:

```markdown
---
description: <one sentence>
mode: subagent
temperature: 0.1
permission:
  <minimal allow-list derived from Round 2 answers>
  <explicit deny for everything dangerous: task, webfetch, etc.>
---

# <Title>
<numbered checklist prompt, ≤25 lines, explicit tool whitelist,
output contract with example, stop condition, critical rule repeated last>
```

Permissions doctrine: least privilege; use allow/deny only — NEVER `ask` (headless evals cannot approve).

## 4. Seed the eval suite

Create `eval/tasks/<id>/`: convert each example query into a task JSON
(`{id, tier, prompt, checks?, judge_required?, max_steps}` — schema mirrors
`eval/tasks/default/*.json`; deterministic checks where possible, else `"judge_required": true`),
then COPY the six T1 default tasks into the same dir so every suite has a mechanical baseline.

## 5. Model pin

Default pin per machine-local config (`.opencode/opencode.jsonc` → `"agent"` block):
`qwen3-4b-instruct-2507` for mac-m1-16, `qwen3-1.7b` for asus-1050ti-16 (see skill
`slm-factory.model-catalog`). Verify chosen keys against live `GET /v1/models`.

## 6. Hand off

Report what was created, then suggest: `/tune_agent_model <id>` (baseline matrix) → `/optimize_agent <id>` (auto-loop).
