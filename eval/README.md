# Agent Factory Eval Harness

Deterministic evaluation infrastructure for SLM sub-agents driven by the `/create-agent`,
`/eval_agent`, `/tune_*`, `/optimize_agent`, `/promote_agent` opencode commands.

## Layout

```
backends.json          machine profiles -> live backend endpoints (Ollama :11434/v1, LM Studio :1234/v1)
smoke_test.sh          Phase-0 probe: server up? emits valid tool_calls? ctx hints
run_suite.sh           runs T*.json tasks headless (sandboxed tmp dirs) via `opencode run --format json`
score.py               deterministic checks + trace metrics -> scores.json (+ appends ../results.jsonl)
report.py              cross-run comparison table / two-run diff
tasks/default/         12 generic capability tasks (T1 mechanical x6, T2 agentic x4, T3 judged x2)
tasks/<agent-id>/      agent-specific suite seeded by /create-agent
results/<label>/       per-run artifacts: raw.jsonl, output.txt, trace.json, scores.json
results/results.jsonl  append-only history across all runs
```

## Quick start

```bash
./eval/smoke_test.sh                          # backends alive? tool calls OK?
./eval/run_suite.sh --agent my-scout          # full suite, auto-detected backend
python3 ./eval/report.py --last 5             # compare iterations
```

## Task JSON schema

```jsonc
{
  "id": "T1-01-name", "tier": "T1|T2|T3",
  "setup": ["shell lines run in a fresh tmp sandbox before the agent starts"],
  "prompt": "what the agent is asked",
  "checks": [ { "type": "file_exists", "path": "out.txt" }, ... ],
  "judge_required": true,          // instead of checks: graded later by main agent
  "max_steps": 8                   // informational; also enforceable via max_steps check
}
```

Check types: `file_exists`, `file_contains`, `file_not_contains`, `output_contains`,
`output_json` (`equals|contains|regex`), `tool_used`, `tool_not_used`, `max_steps`.

## Backend requirements (read once, save hours)

- **Ollama**: start with `OLLAMA_CONTEXT_LENGTH=8192 ollama serve` — the default context
  silently truncates long system prompts.
- **LM Studio**: set context length at model LOAD time; JIT loading means first call pays
  disk-load latency (the runner pre-warms); disable/watch auto-unload for long suites.
- Model keys differ between backends for identical GGUFs — always confirm via `GET /v1/models`.
- After pulling ANY new model: re-run `smoke_test.sh`; tool-call support depends on the
  model's chat template.

## Scoring gates (promotion)

T1 ≥ 90% · T2 ≥ 60% · T3 judge avg ≥ 60 · permission violations = 0 · no `needs_judge` leftovers.
