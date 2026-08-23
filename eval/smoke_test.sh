#!/usr/bin/env bash
# Phase-0 smoke test: probe local inference backends for opencode compatibility.
#
# Checks per live endpoint:
#   1. GET  /v1/models          -> server up, list downloaded models
#   2. POST /v1/chat/completions with a tool definition -> does it emit proper tool_calls?
#   3. Context sanity hints (ollama native /api/show; LM Studio prints loaded ctx in stats)
#
# Usage: ./eval/smoke_test.sh [--profile mac-m1-16|asus-1050ti-16] [--url BASEURL]
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES="$HERE/backends.json"

PROFILE=""
OVERRIDE_URL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --url)     OVERRIDE_URL="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

probe_endpoint() {
  local name="$1" base="$2"
  echo "── $name @ $base ──────────────────────────────────────────"

  # 1. model list
  if ! curl -sf --max-time 5 "$base/models" -o /tmp/op_smoke_models.json 2>/dev/null; then
    echo "   ✗ DOWN (no response from /models)"; echo; return
  fi
  echo "   ✓ UP — models:"
  jq -r '.data[]?.id // empty' /tmp/op_smoke_models.json 2>/dev/null | sed 's/^/       • /' | head -20

  # 2. tool-calling probe (skip obvious embedding/reranking models — they can't do FC)
  local body resp tc
  body=$(jq -n '{model:"__PICKED_BY_SERVER_OR_FIRST__",messages:[{role:"user",content:"List the file report.txt using the provided tool."}],tools:[{type:"function",function:{name:"read_file",description:"Read a file",parameters:{type:"object",properties:{path:{type:"string"}},required:["path"]}}}],tool_choice:"auto",max_tokens:200}')
  local m ok=0
  while IFS= read -r m; do
    [[ -z "$m" ]] && continue
    local b2="${body/__PICKED_BY_SERVER_OR_FIRST__/$m}"
    resp=$(curl -s --max-time 60 "$base/chat/completions" -H 'Content-Type: application/json' -d "$b2" 2>/dev/null) || continue
    tc=$(printf '%s' "$resp" | jq -r '.choices[0].message.tool_calls[0].function.name // empty' 2>/dev/null)
    if [[ "$tc" == "read_file" ]]; then
      echo "   ✓ TOOL CALLS OK  (model '$m' emitted read_file)"
      ok=1; break
    else
      echo "   △ model '$m' did not emit a tool call ($(printf '%s' "$resp" | jq -r '.choices[0].message.content // "no content"' 2>/dev/null | head -c 80))"
    fi
  done < <(jq -r '[.data[]?.id // empty
                   | select(test("embed|minilm|bge|gte|e5[-_]|rerank";"i") | not)][:3][]' /tmp/op_smoke_models.json 2>/dev/null)
  [[ "$ok" == "0" ]] && echo "   ✗ NO MODEL ON THIS ENDPOINT EMITTED A VALID TOOL CALL — fix chat template/JIT prompt config before evals"

  # 3. backend-specific context hints
  if [[ "$name" == ollama ]]; then
    echo "   ℹ Ollama default ctx is small (~2048/4096). Serve with: OLLAMA_CONTEXT_LENGTH=8192 ollama serve"
  else
    echo "   ℹ LM Studio: context length is set at LOAD time (GUI/model load settings); JIT auto-unload may add latency between tasks."
  fi
  echo
}

if [[ -n "$OVERRIDE_URL" ]]; then
  probe_endpoint "custom" "$OVERRIDE_URL"
elif [[ -n "$PROFILE" ]]; then
  while IFS= read -r ep; do
    b=$(jq -r '.baseURL' <<<"$ep"); n=$(jq -r '.backend' <<<"$ep")
    probe_endpoint "$n" "$b"
  done < <(jq -c ".profiles[\"$PROFILE\"].endpoints[]" "$PROFILES")
else
  # probe all unique endpoints across profiles
  while IFS= read -r ep; do
    [[ -z "$ep" ]] && continue
    b=$(jq -r '.baseURL' <<<"$ep"); n=$(jq -r '.backend' <<<"$ep")
    probe_endpoint "$n" "$b"
  done < <(jq -c '[.profiles[].endpoints[]] | unique_by(.backend)' "$PROFILES" | jq -c '.[]')
fi

echo "Done. Any endpoint without ✓ TOOL CALLS OK must be fixed before running the suite."
