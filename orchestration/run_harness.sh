#!/usr/bin/env bash
# run_harness.sh — 三连编排：派发 Claude / Codex / Devin 到各自项目目录完成同一任务。
#
# 用法（在 l4d/ 目录执行）:
#   bash _harness-backup/orchestration/run_harness.sh [CLAUDE_CMD] [CODEX_CMD] [DEVIN_CMD]
#
# 说明:
#   - 本脚本驱动三条外部 CLI（Claude Code、Codex、Devin）。DSH 这一路由编排者
#     通过当前 harness 的 subagent 驱动（不在本脚本内）。
#   - 三条 CLI 用同一个 dispatch prompt（除 ${AGENT} 外逐字节一致）。
#   - 并行运行，日志与结果写入 _harness-backup/runs/<timestamp>/。

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"   # l4d/
PROMPT="$ROOT/_harness-backup/orchestration/dispatch_prompt.md"
TS="$(date +%Y%m%d-%H%M%S)"
RUNS="$ROOT/_harness-backup/runs/$TS"
mkdir -p "$RUNS"

log()  { printf '[run_harness] %s\n' "$*"; }

# ---- 1. 生成实例化 prompt（逐字节一致，仅 AGENT 不同） ----
mkdir -p "$RUNS/prompts"
for ag in CLAUDE CODEX DSH DEVIN; do
  sed "s/\${AGENT}/${ag}/g" "$PROMPT" > "$RUNS/prompts/${ag}.md"
done
log "dispatch prompts -> $RUNS/prompts/{CLAUDE,CODEX,DSH,DEVIN}.md"

# ---- 2. Claude 路（后台） ----
run_claude() {
  local dir="$ROOT/claude"
  cd "$dir" || return 1
  log "CLAUDE: launching in $dir"
  claude -p "$(cat "$RUNS/prompts/CLAUDE.md")" \
    --output-format json \
    --dangerously-skip-permissions \
    --no-session-persistence \
    > "$RUNS/CLAUDE.result.json" 2> "$RUNS/CLAUDE.stderr.log"
  echo "$?" > "$RUNS/CLAUDE.exit"
  log "CLAUDE: finished (exit $(cat "$RUNS/CLAUDE.exit"))"
}

# ---- 3. Codex 路（后台） ----
run_codex() {
  local dir="$ROOT/codex"
  cd "$dir" || return 1
  log "CODEX: launching in $dir"
  codex exec --cd "$dir" \
    --json \
    --dangerously-bypass-approvals-and-sandbox \
    --ephemeral \
    "$(cat "$RUNS/prompts/CODEX.md")" \
    > "$RUNS/CODEX.result.jsonl" 2> "$RUNS/CODEX.stderr.log"
  echo "$?" > "$RUNS/CODEX.exit"
  log "CODEX: finished (exit $(cat "$RUNS/CODEX.exit"))"
}

# ---- 4. Devin 路（后台） ----
run_devin() {
  local dir="$ROOT/devin"
  cd "$dir" || return 1
  log "DEVIN: launching in $dir"
  devin -p "$(cat "$RUNS/prompts/DEVIN.md")" \
    --permission-mode dangerous \
    > "$RUNS/DEVIN.result.log" 2> "$RUNS/DEVIN.stderr.log"
  echo "$?" > "$RUNS/DEVIN.exit"
  log "DEVIN: finished (exit $(cat "$RUNS/DEVIN.exit"))"
}

log "run id: $TS"
log "starting CLAUDE + CODEX + DEVIN in parallel..."
run_claude &  CLAUDE_PID=$!
run_codex &  CODEX_PID=$!
run_devin &  DEVIN_PID=$!

log "CLAUDE pid=$CLAUDE_PID  CODEX pid=$CODEX_PID  DEVIN pid=$DEVIN_PID"
log "logs in: $RUNS"

# 等待三条 CLI 结束
wait "$CLAUDE_PID"; wait "$CODEX_PID"; wait "$DEVIN_PID"

log "=== 汇总 ==="
echo "CLAUDE exit: $(cat "$RUNS/CLAUDE.exit" 2>/dev/null || echo '?')"
echo "CODEX exit: $(cat "$RUNS/CODEX.exit" 2>/dev/null || echo '?')"
echo "DEVIN exit: $(cat "$RUNS/DEVIN.exit" 2>/dev/null || echo '?')"
echo "run dir: $RUNS"
echo
echo "下一步: DSH 路由编排者用 subagent 驱动（l4d/dsh），prompt 用 $RUNS/prompts/DSH.md"
