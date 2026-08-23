---
name: slm-factory.model-catalog
description: Researched catalog of local SLM candidates for agentic use — per-hardware fit, quants, tool-calling quality, backend model IDs (Ollama tags + LM Studio keys). Consult before /tune_agent_model or when choosing a model for a new subagent.
---

# SLM Model Catalog (researched Aug 2026)

Evidence: BFCL V4 function-calling leaderboard (Apr 2026) + TinyLLM paper (arXiv 2511.22138).
Key finding: models <1B are unusable for agents; 1–4B is the workable band; prompting/skills beat scale below 8B.

## Hardware profiles

| Profile | Ceiling | Sweet spot | Notes |
|---|---|---|---|
| `mac-m1-16` | 8B Q4 (~9–12 t/s) | 4B Q4 (~18–25 t/s) | Metal via Ollama/LM Studio |
| `asus-1050ti-16` | 4B Q4, ctx ≤2–4K (tight) | 1.7B Q4 (~28–33 t/s) | 7B+ impossible; watch VRAM |

## Candidates

| Model | Params | BFCL V4 | Tool calls | Ollama tag | LM Studio key (verify vs `/v1/models`) | Fit |
|---|---|---|---|---|---|---|
| Qwen3-4B-Instruct-2507 ⭐ default | 4B | 35.7 | native | `qwen3:4b-instruct-2507` | `qwen/qwen3-4b-instruct-2507` | both (Asus: tight ctx) |
| Qwen3-1.7B ⭐ Asus default | 1.7B | n/a | native | `qwen3:1.7b` | `qwen/qwen3-1.7b` | both, fastest viable |
| Granite-4.0-Micro | 3B | n/a | native, IF-tuned | `ibm/granite4:micro` | `ibm-granite/granite-4.0-micro` | both; mamba-hybrid = small KV cache |
| Llama-3.2-3B | 3B | n/a | native | `llama3.2:3b` | `meta-llama/llama-3.2-3b-instruct` | mac comfy; Asus ctx-limited |
| Phi-4-mini | 3.8B | n/a | strong | `phi4-mini` | search GGUF | tight on Asus |
| Qwen3-8B | 8B | 42.6 | native | `qwen3:8b` | `qwen/qwen3-8b` | **mac only** — fallback if 4B plateaus |
| Gemma-3-4B | 4B | n/a | ❌ no native FC | — | — | avoid for tool-using agents |

## Observed on this machine (Aug 2026 smoke test)

- `ollama` UP locally with: `qwen3:4b`, `granite4.1:3b`, `codegemma:2b`, `qwen3-vl:4b`.
- **`granite4.1:3b` emitted a valid tool call** → verified agentic candidate (Granite 4.1 > 4.0).
- Default tag `qwen3:4b` did NOT emit a tool call under a short probe — likely the
  thinking-mode default; prefer explicit `qwen3:4b-instruct-2507` (or raise max_tokens /
  disable thinking) before condemning the family.
- `lmstudio` endpoint was down at test time; re-probe when the app is running.

## Backend gotchas (must respect in every eval run)

- **Ollama**: default context ~2048–4096 silently truncates system prompts → serve with
  `OLLAMA_CONTEXT_LENGTH=8192`. Per-request `num_ctx` does not pass through the OpenAI-compat layer.
- **LM Studio**: context length is a LOAD-time setting (GUI/model config), not a request param.
  JIT loading pays full disk-load latency on first call → harness pre-warms before timed runs;
  auto-unload after idle TTL would add minutes across long suites.
- Model keys differ per backend for the same GGUF — always confirm against live
  `GET /v1/models`; never assume the key from this file alone.
- Tool-call emission depends on each downloaded model's chat template ("Use Prompt Config"/Jinja
  toggles in LM Studio) → run `eval/smoke_test.sh` after pulling ANY new model.

## Selection heuristic

Start `Qwen3-4B-Instruct-2507` on mac / `Qwen3-1.7B` on Asus → only escalate to 8B (mac)
or swap to Granite-micro if the failure taxonomy shows template/format issues rather than capability gaps.
