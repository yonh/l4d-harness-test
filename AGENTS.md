# AGENTS.md — _harness-backup（回归备份 / 权威基准仓库）

> 本仓库是「求生之路楼顶开局」多 Agent 公平测试的**回归备份与权威公共基准**（source of truth），不是某个 agent 的工作目录。它用于：记录任务书、分享 blender-mcp 技能、固定共享依赖版本、保存编排与验收脚本，并在需要回归时重新分发到三个测试项目。

## 进入本仓库的 agent 该做什么
- **只读基准**：从这里读取权威的 `L4D_ROOFTOP_TASK.md`、`blender-mcp.skill/`、`blender.version`、`skeleton/`、`orchestration/`。
- **不把这里当工作目录**：不要在这里完成游戏 Demo。游戏产出应落在 `l4d/claude`、`l4d/codex`、`l4d/dsh` 各自的命名空间。
- **不要修改任务书而不提交**：任何对任务书/基准的改动都必须先提交本仓库，再重新分发（见 `README.md` 的重新同步命令），保证三项目输入逐字节一致。

## 目录约定
| 路径 | 说明 |
|------|------|
| `L4D_ROOFTOP_TASK.md` | 权威任务书，保留了 `<AGENT>` 占位符；分发给三项目时实例化为 CLAUDE/CODEX/DSH |
| `L4D_ROOFTOP_TASK.original.md` | 未经 fair-test 改造的原始任务书备份 |
| `blender-mcp.skill/` | blender-mcp 技能全量（SKILL.md + references/），三项目共享同一份 |
| `blender.version` | 共享依赖 blender-mcp 固定 commit（`3ab8925`），**不复制重仓库** |
| `orchestration/` | dispatch.md（三连派发说明）+ verify_template.sh（验收模板） |
| `skeleton/` | three.js + vite 可复现骨架（vite 5.4.2 / three 0.165.0，已 lock） |

## 重要约束
- **blender-mcp 是共享依赖（嵌套仓库，自带 origin）**：这里不保存其完整代码，只记录版本。需要时引用 `3ab8925`，不要改动它的代码。
- **公平性**：三份任务书必须由本仓库 `<AGENT>` 占位符实例化，除 agent 标记外逐字节一致。验证方法见 `README.md`。
- **不要提交**：`node_modules/`、`dist/`、`.DS_Store`、任何 token/凭据。

## 回归流程（快速自检）
1. 本仓库清爽提交每个基准版本。
2. 用 `README.md` 的 rsync/cp 命令把公共资源分发进 `l4d/claude`、`l4d/codex`、`l4d/dsh`。
3. 校验三个项目内 `normalize`（去掉 CLAUDE/CODEX/DSH 后）逐字节一致。

---

## 环境状态（2026-08-14 实测，多轮回归中）

| 项 | 状态 |
|----|------|
| Blender MCP 服务 | GUI 模式，`localhost:9876` LISTENING（addon v1.2，禁止 `--background`）|
| 模型统一 | 三者均 flash 档：Claude=`deepseek-v4-flash[1m]`，Codex=`deepseek-v4-flash`，DSH subagent=`deepseek-v4-flash` |
| 4 个 git 仓库 | claude/codex/dsh 的 `master` 常驻冒烟基线；`round/N` 分支保存每轮产出；本仓库 master 保存基准+轮次记录 |
| 多轮记录 | `ROUNDS.md` = 轮次表/打分对比 source of truth |

## 三路驱动方式

| Agent | 驱动命令（在 l4d 根） | 工作目录 |
|-------|----------------------|----------|
| Claude | `claude -p "<prompt>" --output-format json --dangerously-skip-permissions --no-session-persistence` | `l4d/claude` |
| Codex | `codex exec --cd l4d/codex --json --ephemeral --dangerously-bypass-approvals-and-sandbox "<prompt>"` | `l4d/codex` |
| DSH | 当前 harness 的 `subagent` 工具（工作目录 `l4d/dsh`）| `l4d/dsh` |

**公平性铁律**：三个 Agent 收到同一份 prompt（仅 `${AGENT}` 占位不同，值为 CLAUDE/CODEX/DSH）。`orchestration/dispatch_prompt.md`（完整版）与 `orchestration/smoke_prompt.md`（冒烟版）是唯一 prompt 来源。

## 每轮完整流程（多轮回归）

1. 前置：三仓库 `master` 必须是冒烟基线（claude `d667252` / codex `ab7da7f` / dsh `7dcf0a9`），工作树干净。
2. 派发：`cd /Users/yonh/workspaces/arena/l4d && bash _harness-backup/orchestration/run_harness.sh`（后台，驱动 Claude + Codex）；
   同时用 harness `subagent` 派发 DSH 路（prompt 用最新 `runs/<ts>/prompts/DSH.md`）。
3. 打分：`for p in claude codex dsh; do bash $p/*_out/verify.sh; done` + 编排者独立核验（GLB 解析/对象类别/语法/代码特征/命名空间）。
   客观分 TASK §6.1（A1–A10，20 分）；主观分 §6.2（M1–M4，12 分，人工浏览器复核）；排名客观分优先、主观分 tie-break。
4. 归档：三仓库各建分支 `round/<N>` 指向本轮产出 HEAD → `master` reset --hard 回滚到冒烟基线。
5. 记录：更新 `ROUNDS.md`（轮次表+打分），提交本仓库。

## 关键坑（踩过，务必记住）

1. **Blender MCP addon v1.2 禁止 `--background`**（addon.py L112-116），必须 GUI 模式，否则 socket 起不来。
2. **Codex 模型决定工具执行力**：`gpt-5.6-*`（`tool_mode="code_mode_only"`）只产文本不落地文件；`deepseek-v4-flash` 正常。已在 `~/.codex/config.toml` 改好。
3. **Codex 有两条非致命 MCP 噪音**：`goalflow`(18765) / `godot-ai`(8000) HTTP MCP 未启动会刷 ERROR，不影响结果。
4. **`.gitignore` 陷阱**：`blender-mcp/` 会误伤 `.claude/skills/blender-mcp/`，必须用锚定 `/blender-mcp/`。claude 项目 `.claude/settings.local.json` 含凭据，已 gitignore，勿 `git add -f`。
5. **uvx 需要写 `~/.cache/uv`**（Codex 的 blender MCP 服务端），沙箱拦截时需放行。
6. **Blender 场景并发污染**：三路共用同一 9876 实例，TASK §0.2 规定每个 agent 只动自己的 `${AGENT}_` 前缀对象；每 agent 最多一次 clear。
7. **交付物入口一致性**：round/1 的 DSH 曾把 `index.html` 入口指向不存在的 `js/main.mjs`（实际为 `js/DSH_main.mjs`），导致入口 404。派发时提醒 agent 检查入口引用与实际文件名一致。
