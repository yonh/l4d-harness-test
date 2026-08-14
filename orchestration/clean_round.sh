#!/usr/bin/env bash
# clean_round.sh - 批次测试前清理工具(round/N 启动前必跑)
#
# 目的: 多轮公平测试中，上一轮的"旧模型/旧环境"产物可能污染新一轮: 
#   - 各 agent 项目工作区残留的 node_modules/ dist/ 构建缓存
#   - 未跟踪的临时目录(.dshtmp*, _diag, probe, bak 等)
#   - 未提交的半成品(上一轮中断留下的 dirty 文件)
#   - 运行日志目录 runs/(gitignore 的历史轮次)
#   - 共享 Blender 场景中的旧前缀对象(可选，通过 blender-mcp 查询/清理自己前缀)
#
# 用法(在 l4d/ 目录执行):
#   bash _harness-backup/orchestration/clean_round.sh            # dry-run: 只列出将清理项
#   bash _harness-backup/orchestration/clean_round.sh --force     # 实际清理
#   bash _harness-backup/orchestration/clean_round.sh --force --keep-runs   # 保留 runs/ 日志
#
# 安全边界: 
#   - 只清理[工作区未跟踪/忽略文件]与[已被 round/N 分支归档的历史]，绝不触碰当前 master 基线内容
#   - 每步前 `git status` 对比确认: 清理后各仓库必须回到基线(dirty=0)
#   - dry-run 是默认，--force 才执行删除

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"   # l4d/
AGENTS="claude codex dsh devin opencode"
FORCE=0
KEEP_RUNS=0
[ "${1:-}" = "--force" ] && FORCE=1
[ "${2:-}" = "--keep-runs" ] && KEEP_RUNS=1

log() { printf '[clean_round] %s\n' "$*"; }
[ "$FORCE" = 1 ] && ACT="CLEAN" || ACT="DRY-RUN"

# ---- 0. 前置检查: 各仓库 master 应处于基线(无产出 dirty) ----
log "=== 0. master 基线检查 ==="
BASELINE_OK=1
for p in $AGENTS; do
  if [ -d "$ROOT/$p/.git" ]; then
    dirty=$(git -C "$ROOT/$p" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    br=$(git -C "$ROOT/$p" branch --show-current 2>/dev/null)
    br="${br:-?}"
    if [ "$br" != "master" ]; then
      log "  [!]  $p: 当前分支=$br(应切回 master)"
      BASELINE_OK=0
    elif [ "$dirty" != "0" ]; then
      log "  [!]  $p: master 有 $dirty 个 dirty 文件(可能未归档，先归档 round/N)"
      BASELINE_OK=0
    else
      log "  [OK] $p: master 干净"
    fi
  fi
done
if [ "$BASELINE_OK" = 0 ]; then
  log "  !! 存在未归档/非基线状态，建议先归档 round/N 再清理(或确认这些 dirty 是误报)"
fi

# ---- 1. 清理各 agent 工作区的构建缓存与临时产物 ----
log "=== 1. 工作区构建缓存/临时产物($ACT)==="
for p in $AGENTS; do
  [ -d "$ROOT/$p" ] || continue
  outdir="$ROOT/$p"
  # 项目内所有 *_{AGENT}_out/ 下的缓存(glob 动态匹配，避免写死)
  for out in "$outdir"/*_out; do
    [ -d "$out" ] || continue
    for pat in "node_modules" "dist" ".dshtmp*" "*.bak-orphan" "_probe*.html" "_diag*.mjs" "_zones*.mjs" "*.tmp"; do
      # shellcheck disable=SC2086
      for hit in $out/$pat; do
        [ -e "$hit" ] || continue
        if [ "$FORCE" = 1 ]; then
          rm -rf "$hit" && log "  [DEL] $p: 已删 $hit"
        else
          log "  - $p: 将删 $hit"
        fi
      done
    done
  done
done

# ---- 2. 各仓库 git 未跟踪文件(非基线内容)----
log "=== 2. git 未跟踪文件($ACT)==="
for p in $AGENTS; do
  [ -d "$ROOT/$p/.git" ] || continue
  untracked=$(git -C "$ROOT/$p" ls-files --others --exclude-standard | head -5)
  if [ -n "$untracked" ]; then
    log "  $p 未跟踪: $untracked"
    if [ "$FORCE" = 1 ]; then
      git -C "$ROOT/$p" clean -fd -q
      log "  [DEL] $p: git clean 完成"
    fi
  else
    log "  [OK] $p: 无未跟踪"
  fi
done

# ---- 3. runs/ 历史日志(可保留)----
if [ "$KEEP_RUNS" = 0 ]; then
  log "=== 3. runs/ 历史日志($ACT)==="
  if [ -d "$ROOT/_harness-backup/runs" ]; then
    n=$(ls "$ROOT/_harness-backup/runs" | wc -l | tr -d ' ')
    log "  当前 runs/ 有 $n 个轮次目录"
    if [ "$FORCE" = 1 ]; then
      rm -rf "$ROOT/_harness-backup/runs"/* && log "  [DEL] 已清空 runs/"
    fi
  fi
else
  log "=== 3. runs/ 保留(--keep-runs)==="
fi

# ---- 4. 共享 Blender 场景清理(可选提示)----
log "=== 4. 共享 Blender 场景 ==="
log "  [!] Blender 9876 是共享实例: 各 agent 只应清理自己前缀对象."
log "  本轮开始前可让每个 agent 在建模时先清自己前缀(TASK §0.2)，无需外部干预."

# ---- 5. 最终状态校验 ----
log "=== 5. 清理后状态 ==="
for p in $AGENTS; do
  [ -d "$ROOT/$p/.git" ] || continue
  dirty=$(git -C "$ROOT/$p" status --porcelain | wc -l | tr -d ' ')
  log "  $p: dirty=$dirty (master=$(git -C "$ROOT/$p" branch --show-current))"
done

log "完成($ACT).注意: --force 已执行；dry-run 未做任何删除."
