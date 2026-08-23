# SLM Factory

An **agent factory** for [opencode](https://opencode.ai): a frontier-model main agent that
designs, evaluates, and iteratively improves **tiny local SLM sub-agents** — co-optimizing their
system prompt, model choice, tool permissions, and knowledge skills against a deterministic
eval suite.

Built for weak hardware: runs the sub-agents fully locally on machines like a
MacBook Air M1 16 GB or an old laptop with GTX 1050 Ti 4 GB + 16 GB RAM
(via Ollama and/or LM Studio).

## The idea in one picture

```
/create-agent          Q&A wizard → scaffolds agent + tailored eval suite
   │
   ▼
/tune_agent_model      benchmark candidate SLMs on live backends → pin winner per machine
   │
   ▼
/eval_agent            score current candidate (12-task suite)
   │
   ▼
/optimize_agent        auto-loop (≤25 iters): weakest metric → ONE mutation
   │                    (prompt / skill / model / permissions) → hill-climb w/ git history
   ├─ same failure ≥2× ─►  /tune_agent_skills  extracts <agent>.<skill> knowledge files
   ▼
/promote_agent         acceptance gates → freeze + permanent regression suite
```

Every `/tune_*` and `/eval_agent` also works standalone. No opencode restarts are needed:
each eval task is a fresh headless `opencode run` process reading current configs.

## What's in this repo

```
.opencode/
  commands/            7 slash commands (the factory UI — copy into any project)
  skills/slm-factory.* 4 knowledge skills for the main agent:
                       model-catalog · tiny-prompt-patterns · failure-taxonomy · extraction-rules
eval/
  run_suite.sh         headless suite runner (sandboxed tmp dirs, JIT pre-warm, trace export)
  score.py             deterministic checks + trace metrics → scores.json (+ results.jsonl history)
  report.py            cross-run comparison / two-run diff
  smoke_test.sh        backend pre-flight: alive? emits valid OpenAI-style tool_calls?
  backends.json        machine profiles → Ollama (:11434/v1) + LM Studio (:1234/v1) endpoints
  tasks/default/       12 generic capability tasks: T1 mechanical ×6, T2 agentic ×4, T3 judged ×2
opencode.template.jsonc  provider block to merge into your project's .opencode/opencode.jsonc
```

## Install (copy-paste how-to)

Prerequisites: `opencode`, [Ollama](https://ollama.com) and/or [LM Studio](https://lmstudio.ai),
plus `jq`, `python3`, `curl`.

1. Copy the factory into your working project:

   ```bash
   cp -r slm_factory/.opencode/*   <your-project>/.opencode/
   cp -r slm_factory/eval          <your-project>/eval
   ```

2. Merge `opencode.template.jsonc` into `<your-project>/.opencode/opencode.jsonc`
   (that file is machine-local — keep it gitignored). Adjust model keys to what you actually
   have downloaded; `curl http://127.0.0.1:<port>/v1/models` is authoritative.
3. Pin models per machine in the same file:

   ```jsonc
   "agent": { "<your-agent-id>": { "model": "ollama/qwen3:1.7b" } }
   ```

4. Backend notes:
   - **Ollama**: start with `OLLAMA_CONTEXT_LENGTH=8192 ollama serve` — the default context
     silently truncates agent system prompts.
   - **LM Studio**: set context length at *load* time; JIT loading means the first call pays
     disk-load latency (the runner pre-warms automatically).
5. Verify backends emit proper tool calls before anything else:

   ```bash
   ./eval/smoke_test.sh
   ```

## Quickstart

```bash
./eval/smoke_test.sh                     # backends alive? tool calls OK?
# then inside opencode:
/create-agent                            # interview → scaffolded agent + tailored suite
/tune_agent_model <agent-id>             # baseline matrix → pinned winner
/optimize_agent <agent-id>               # auto hill-climb loop
/promote_agent <agent-id>                # gates → freeze + regression suite
```

## Scoring gates (promotion)

| Gate | Threshold |
|---|---|
| T1 mechanical tasks | ≥ 90% |
| T2 agentic tasks | ≥ 60% |
| T3 judged tasks | ≥ 60 average |
| Permission violations | **0** (absolute veto) |

## Default model shortlist (Aug 2026)

| Model | Params | Best for | Notes |
|---|---|---|---|
| Qwen3-4B-Instruct-2507 | 4B | mac default | BFCL V4 35.7, native tool calls, 262K ctx |
| Qwen3-1.7B | 1.7B | 1050 Ti default | fastest viable (~28–33 t/s Q4) |
| Granite-4.x-Micro | 3B | both | IF/tool-calling tuned; verified emitting tool calls |
| Qwen3-8B | 8B | mac fallback | BFCL V4 42.6 if 4B plateaus |

Models <1B are not worth pursuing for agents (evidence: BFCL, arXiv 2511.22138).
Full research table lives in `.opencode/skills/slm-factory.model-catalog/SKILL.md`.

## Provenance & workflow

Developed and battle-tested inside the `law_by_ai` project; this repo is the canonical,
version-tracked home of the factory setup. Usage model: keep one working copy embedded in each
project that uses it (`.opencode/` + `eval/`), track improvements here, and re-copy after updates.

## License

MIT — see [LICENSE](LICENSE).
