#!/usr/bin/env bash
# verify_template.sh — 每个 Agent 交付物中必须提供的 verify.sh 模板。
# 引用本文件到你的 ${AGENT}_out/verify.sh，按需修改路径。
#
# Usage:
#   verify.sh assets   # 校验模型 / 构建产物 / 代码特征
#   verify.sh run      # 无头启动构建产物验证可加载
set -uo pipefail

AGENT="${AGENT:-CLAUDE}"        # CLAUDE / CODEX / DSH
OUT="${AGENT}_out"
PASS=0; FAIL=0

ok()   { echo "[PASS] $1"; PASS=$((PASS+1)); }
bad()  { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

check() { local desc="$1" cond="$2"; if eval "$cond"; then ok "$desc"; else bad "$desc"; fi; }

case "${1:-assets}" in
  assets)
    # A1: GLB exists & parseable (basic header check: length >= .glb magic 4B)
    check "A1 ${AGENT}_rooftop.glb exists" \
      '[ -f "${OUT}/${AGENT}_rooftop.glb" ]'
    check "A2 GLB has glTF magic" \
      '[ -n "$(head -c4 "${OUT}/${AGENT}_rooftop.glb" 2>/dev/null | strings)" ]'

    # A3: index.html + main.mjs present
    check "A3 index.html present" '[ -f "${OUT}/index.html" ]'

    # A4-A8: code feature greps (adjust tokens to your naming)
    check "A4 pointer-lock / FPS control" \
      'grep -qiE "PointerLockControls|movementSpeed|yaw|pitch" "${OUT}/main.js"'
    check "A5 door E-key interaction" \
      'grep -qiE "keydown|keyE|e\.code === .KeyE.|rotate.*door" "${OUT}/main.js"'
    check "A6 enemy pursuit AI" \
      'grep -qiE "distanceTo|normalize|pursue|chase" "${OUT}/main.js"'
    check "A7 AnimationClips (Idle/Walk)" \
      'grep -qiE "AnimationClip|KeyframeTrack|\.actions\[" "${OUT}/main.js"'
    check "A8 health + Dead state machine" \
      'grep -qiE "health|dead|state" "${OUT}/main.js"'

    check "A9 namespace prefix compliance" \
      'find "${OUT}" -type f | grep -qE "${AGENT}_"'

    # A10
    check "A10 verify.sh executable" '[ -x "${OUT}/verify.sh" ]'
    ;;
  run)
    # 无头启动占位：替换为真正构建/启动命令（如 vite preview / http.server + 探测）
    check "run: entry html readable" '[ -f "${OUT}/index.html" ]'
    ;;
  *)
    echo "usage: verify.sh [assets|run]"
    exit 2;;
esac

echo "---------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
