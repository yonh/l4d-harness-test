# HANDOFF — 多 Agent 公平测试交接文档

> 本文件由上一会话在停止任务时生成，用于把「求生之路楼顶开局」多 Agent（Claude / Codex / DSH）公平测试工作**无缝交接给新会话**。
> **新会话第一步**：读本文件 → 读 `_harness-backup/README.md` → 读 `_harness-backup/orchestration/dispatch.md`。

---

## 0. 任务一句话

让 **Claude、Codex、DSH** 三个 Agent 在各自独立项目目录里，用**同一份任务书**完成《求生之路楼顶开局》3D Demo（three.js + Blender），产出到各自命名空间，按同一验收表打分对比。

## 1. 目录结构（/Users/yonh/workspaces/arena/l4d/）

```
l4d/
├── HANDOFF.md                      ← 本文件（交接入口）
├── _harness-backup/                ← 回归备份 + 权威基准（git 仓库）
│   ├── README.md                   备份/回归说明、重新分发命令
│   ├── AGENTS.md                   备份仓库的角色说明
│   ├── L4D_ROOFTOP_TASK.md         权威任务书（<AGENT> 占位符版）
│   ├── L4D_ROOFTOP_TASK.original.md
│   ├── blender-mcp.skill/          Blender MCP 技能全量（SKILL.md + references/）
│   ├── blender.version             共享依赖 blender-mcp pinned commit: 3ab8925
│   ├── skeleton/                   three.js+vite 可复现骨架（vite 5.4.2 / three 0.165.0，含 lock）
│   ├── orchestration/
│   │   ├── dispatch_prompt.md      三连统一初始提示词（${AGENT} 占位）
│   │   ├── dispatch.md             编排权威说明
│   │   ├── run_harness.sh          驱动 Claude + Codex CLI 的编排脚本
│   │   ├── smoke_prompt.md         缩小版冒烟提示词
│   │   ├── run_smoke.sh            冒烟版编排脚本
│   │   └── verify_template.sh      verify.sh 模板
│   └── runs/                       历次运行日志与结果（已 gitignore）
├── claude/         git 仓库 | CLAUDE_ 命名空间 | TASK.md/AGENTS.md/skeleton/skill
├── codex/          git 仓库 | CODEX_ 命名空间 | TASK.md/AGENTS.md/skeleton/skill
└── dsh/            git 仓库 | DSH_ 命名空间 | TASK.md/AGENTS.md/skeleton/skill
```

## 2. 当前环境状态（交接时实测）

| 项 | 状态 |
|----|------|
| Blender MCP 服务 | ✅ **运行中**：GUI 模式，`localhost:9876` LISTENING（后台 job，`dsh/blender-mcp/gui_boot.py` 启动）|
| 模型统一 | ✅ 三者均为 flash 档：Claude=`deepseek-v4-flash[1m]`，Codex=`deepseek-v4-flash`，DSH subagent=`deepseek-v4-flash` |
| 4 个 git 仓库 | ✅ 全部 clean（claude/codex/dsh/_harness-backup）|
| 冒烟测试 | ✅ 三路全部通过（3 PASS / 0 FAIL），结果在 `runs/smoke-20260814-064015/SMOKE_RESULT.md` |
| 完整任务 | ⏹ 已停止（上一会话终止了 `run_harness.sh` 后台任务 bash-8，无残留进程）|

## 3. 三个 Agent 的驱动方式

| Agent | 驱动命令（在 l4d 根） | 工作目录 |
|-------|----------------------|----------|
| Claude | `claude -p "<prompt>" --output-format json --dangerously-skip-permissions --no-session-persistence` | `l4d/claude` |
| Codex | `codex exec --cd l4d/codex --json --ephemeral --dangerously-bypass-approvals-and-sandbox "<prompt>"` | `l4d/codex` |
| DSH | 当前 harness 的 `subagent` 工具（工作目录 `l4d/dsh`）| `l4d/dsh` |

**公平性铁律**：三个 Agent 收到同一份 prompt（仅 `${AGENT}` 占位不同，值为 CLAUDE/CODEX/DSH）。`dispatch_prompt.md`（完整版）与 `smoke_prompt.md`（冒烟版）是唯一 prompt 来源。

## 4. 如何继续（下一步行动）

### 4.1 重新启动完整三连（方案 A：全由我编排）
```bash
cd /Users/yonh/workspaces/arena/l4d
bash _harness-backup/orchestration/run_harness.sh   # 后台并行驱动 Claude + Codex
# 同时：用 subagent 工具派发 DSH 路，prompt 用最新 runs/<ts>/prompts/DSH.md
```
- `run_harness.sh` 会生成 runs 目录并实例化三份 prompt（`{CLAUDE,CODEX,DSH}.md`）。
- DSH 路必须由新会话的 `subagent` 工具派发（harness 内部机制，CLI 无法替代）。

### 4.2 收集结果与打分
```bash
# 三路产出 verify
for p in claude codex dsh; do echo "== $p =="; bash $p/*_out/verify.sh; done
# 结果在 _harness-backup/runs/<ts>/
```
- 客观分：TASK §6.1（A1–A10，共 20 分）
- 主观分：TASK §6.2（M1–M4，共 12 分，人工浏览器复核）
- 排名：客观分优先，主观分 tie-break

### 4.3 回归 / 重新分发基准（改动任务书后）
```bash
cd /Users/yonh/workspaces/arena/l4d/_harness-backup
# 修改 L4D_ROOFTOP_TASK.md 后：
for p in claude codex dsh; do
  sed "s/<AGENT>/$(echo $p | tr a-z A-Z)/g" L4D_ROOFTOP_TASK.md > ../$p/TASK.md
  cp -R blender-mcp.skill ../$p/.claude/skills/blender-mcp
done
```

## 5. 关键坑（踩过，务必记住）

1. **Blender MCP addon v1.2 禁止 `--background`**（addon.py L112-116），必须 GUI 模式（`gui_boot.py`），否则 socket 起不来。
2. **Codex 模型决定工具执行力**：`gpt-5.6-*`（`tool_mode="code_mode_only"`）只产文本不落地文件；`deepseek-v4-flash` 正常。已在 `~/.codex/config.toml` 改好。
3. **Codex 有两条非致命 MCP 噪音**：`goalflow`(18765) / `godot-ai`(8000) HTTP MCP 未启动会刷 ERROR，不影响结果。
4. **`.gitignore` 陷阱**：`blender-mcp/` 会误伤 `.claude/skills/blender-mcp/`，必须用锚定 `/blender-mcp/`。claude 项目 `.claude/settings.local.json` 含凭据，已 gitignore，勿 `git add -f`。
5. **uvx 需要写 `~/.cache/uv`**（Codex 的 blender MCP 服务端），沙箱拦截时需放行。
6. **Blender 场景并发污染**：三路共用同一 9876 实例，TASK §0.2 规定每个 agent 只动自己的 `${AGENT}_` 前缀对象。

## 6. 验证历史（git）

| 仓库 | 最近 HEAD | 说明 |
|------|-----------|------|
| `_harness-backup` | `d67e1ac` | 编排 + 冒烟脚本 |
| `claude` | `d667252` | 冒烟产出 |
| `codex` | `ab7da7f` | 冒烟产出（模型修复后）|
| `dsh` | `7dcf0a9` | 冒烟产出 |

## 7. 未完成事项清单

- [ ] **完整任务三连未跑完**（bash-8 已停止；Claude/Codex 部分运行被终止，产物未落地）
- [ ] 三路结果统一打分与排名报告
- [ ] （可选）人工浏览器复核主观项 M1–M4
- [ ] （可选）把每次 runs/ 结果归档为可追溯记录

---

*交接生成时间：2026-08-14 06:5x（由上一 DSH 会话生成）*
