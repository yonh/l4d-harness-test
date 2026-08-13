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
