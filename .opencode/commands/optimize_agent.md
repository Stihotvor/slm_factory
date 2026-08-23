---
description: Master optimization loop — drives tune_* steps until plateau or iteration budget
---

Full auto-optimization of agent `$ARGUMENTS` (optional second arg: max iterations, default 25).

## Loop

Each iteration:
1. Read latest scores + notes. Identify weakest dimension and dominant failure class
   (skill: `slm-factory.failure-taxonomy`).
2. Choose exactly ONE action, in decision order:
   a. Backend/config class → fix env (OLLAMA_CONTEXT_LENGTH / LM Studio load ctx), re-run.
   b. Permission class → narrow the fence in the agent file.
   c. Knowledge-gap ≥2× → run the `/tune_agent_skills` procedure for that pattern only.
   d. Any other class → run the `/tune_agent_prompt` procedure (one mutation).
   e. Two consecutive failed iterations on the same class → invoke `/tune_agent_model` once,
      then continue with the new pin.
3. Verify per the invoked tune step's rules; hill-climb: keep improvements, revert regressions.
4. Append `{iter, action, target_class, delta}` to `eval/results/<run>/notes.md`.

## Stop conditions

- No success_rate improvement for **3 consecutive iterations** (plateau), OR
- Iteration budget reached, OR
- Gates from `/promote_agent` already met early.

## Reporting

Final table via `python3 ./eval/report.py`, plus: mutations kept/reverted, skills extracted,
model swaps, dominant residual failure classes, recommendation (promote / continue / abandon).

Never widen permissions mid-loop; never edit `~/.config/opencode/`; ask before pulling new models.
