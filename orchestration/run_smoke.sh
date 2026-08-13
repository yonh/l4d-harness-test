#!/usr/bin/env bash
# run_smoke.sh — 缩小版冒烟编排：驱动 Claude + Codex 各完成最小交付并自测。
# DSH 路由编排者用 harness subagent 驱动（不在此脚本内）。
#
# 用法: bash _harness-backup/orchestration/run_smoke.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"   # l4d/
PROMPT="$ROOT/_harness-backup/orchestration/smoke_prompt.md"
TS="$(date +%Y%m%d-%H%M%S)"
RUNS="$ROOT/_harness-backup/runs/smoke-$TS"
mkdir -p "$RUNS/prompts"

log() { printf '[run_smoke] %s\n' "$*"; }

# 实例化三份 prompt
for ag in CLAUDE CODEX DSH; do
  sed "s/\${AGENT}/${ag}/g" "$PROMPT" > "$RUNS/prompts/${ag}.md"
done
log "prompts -> $RUNS/prompts/"

run_claude() {
  cd "$ROOT/claude" || return 1
  log "CLAUDE launching..."
  claude -p "$(cat "$RUNS/prompts/CLAUDE.md")" \
    --output-format json \
    --dangerously-skip-permissions \
    --no-session-persistence \
    > "$RUNS/CLAUDE.result.json" 2> "$RUNS/CLAUDE.stderr.log"
  echo "$?" > "$RUNS/CLAUDE.exit"
  log "CLAUDE finished (exit $(cat "$RUNS/CLAUDE.exit"))"
}

run_codex() {
  cd "$ROOT/codex" || return 1
  log "CODEX launching..."
  codex exec --cd "$ROOT/codex" \
    --json --ephemeral \
    --dangerously-bypass-approvals-and-sandbox \
    "$(cat "$RUNS/prompts/CODEX.md")" \
    > "$RUNS/CODEX.result.jsonl" 2> "$RUNS/CODEX.stderr.log"
  echo "$?" > "$RUNS/CODEX.exit"
  log "CODEX finished (exit $(cat "$RUNS/CODEX.exit"))"
}

log "run id: smoke-$TS"
run_claude & CPID=$!
run_codex & XPID=$!
wait "$CPID"; wait "$XPID"

log "=== smoke 汇总 ==="
echo "CLAUDE exit: $(cat "$RUNS/CLAUDE.exit" 2>/dev/null || echo '?')"
echo "CODEX exit: $(cat "$RUNS/CODEX.exit" 2>/dev/null || echo '?')"
echo "run dir: $RUNS"
echo "DSH prompt: $RUNS/prompts/DSH.md"
