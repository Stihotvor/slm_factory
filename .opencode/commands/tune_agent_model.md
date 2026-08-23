---
description: Benchmark candidate SLMs for an agent across live backends and pin the winner per machine
---

Model selection for agent `$ARGUMENTS`.

## 1. Discover candidates

Consult skill `slm-factory.model-catalog` for the researched shortlist. Then enumerate what is
ACTUALLY installed: `curl -s http://127.0.0.1:1234/v1/models` and
`curl -s http://127.0.0.1:11434/v1/models`. Candidates = catalog ∩ installed, per live backend.
If a shortlisted model is missing, offer to pull it (ollama pull / LM Studio download) — ask the user first.

## 2. Smoke-gate

For each candidate run `./eval/smoke_test.sh --url <backend>/v1`; drop any model that cannot emit
a valid tool call (fixing chat-template config is allowed; silently skipping is not).

## 3. Benchmark matrix

For each surviving candidate × backend:
`./eval/run_suite.sh --agent <id> --suite <suite> --model <provider>/<key> --label "<model>@<backend>"`

Record: success_rate, T1/T2 rates, permission violations, median steps, median wall time.
Cap: if >4 candidates, run the full suite only on the top 2 after a 3-task smoke subset.

## 4. Pin the winner

Pick best success_rate, tiebreak on wall time. Pin it machine-locally in
`.opencode/opencode.jsonc` → `"agent": { "<id>": { "model": "<provider>/<key>" } }`
(this file is gitignored — machine-specific by design). Never edit `~/.config/opencode/` without asking.

## 5. Report

Matrix table + chosen pin + runner-up. Remind: `/optimize_agent <id>` next.
