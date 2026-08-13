# L4D Harness Backup —— 多 Agent 公平测试回归备份

本仓库记录「求生之路楼顶开局」多 Agent（Claude / Codex / DSH）公平测试的**权威公共基准**（回回归测试的同步起点），不包含任何 Agent 的私有产出。

> **⚠️ 新会话接手指南**：如果你是在一个全新会话中接手此工作，请先读本仓库根目录的 **`HANDOFF.md`**（交接文档），它记录了完整的环境状态、三路驱动方式、如何继续、关键坑与未完成事项。

## 用途

- **回归测试**：每次改动编排逻辑或任务书后，以本仓库为 `source of truth` 重新分发到三个测试项目（`l4d/claude`、`l4d/codex`、`l4d/dsh`），确保三份输入完全一致。
- **同步起点**：`l4d/claude`、`l4d/codex`、`l4d/dsh` 三个测试项目分别 `git init`，各自内嵌一份**本公共资源的副本**，作为每个 Agent 的公平起点提交。

## 目录结构

```
_harness-backup/
├── README.md                        # 本文件
├── L4D_ROOFTOP_TASK.md              # 修订版任务书（含 {AGENT} 占位符，FAIR-PLAY CONTRACT）
├── L4D_ROOFTOP_TASK.original.md     # 原始任务书备份
├── blender-mcp.skill/               # Blender MCP 技能全量（SKILL.md + references/），三项目共享同一份
├── blender.version                  # 共享依赖 blender-mcp 的固定 commit（不复制重仓库）
├── orchestration/                   # 编排/验收脚本源码（workflow 与 verify）
│   ├── dispatch.md                  # 三连派发说明（workflow / subagent 用法）
│   └── verify_template.sh           # 每个 Agent 必须提供的 verify.sh 模板
└── skeleton/                        # 可复现构建骨架占位
    └── (three.js + vite 最小模板)    # 待补充
```

## 公共基准版本

| 项目 | 版本/commit |
|------|-------------|
| blender-mcp（共享依赖） | `3ab8925`（github.com/ahujasid/blender-mcp）|
| Blender MCP addon | v1.2（禁止 `--background`，需 GUI 模式）|
| 任务书 | 修订版，见 `L4D_ROOFTOP_TASK.md` |

## 重新同步到测试项目的命令（供回归复用）

用 `rsync` 或 `cp -R` 把本仓库的公共资源副本分发进三个项目：

```bash
# 示例：把任务书与 skill 分发到每个测试项目
for proj in claude codex dsh; do
  cp L4D_ROOFTOP_TASK.md ../$proj/TASK.md
  cp -R blender-mcp.skill ../$proj/.claude/skills/blender-mcp   # 按各 agent 所需路径调整
done
```

> 注意：实际分发路径按各 Agent 的 skill/MCP 机制不同而异（Claude 项目 = `.claude/skills/`；Codex 项目 = `~/.codex/skills/`；DSH 项目 = `.claude/skills/`）。分发的**内容**必须来自本仓库以保证一致。

## 公平性前提（务必遵守）

1. 三份任务书内容必须逐字节一致（仅 `{AGENT}` 占位代入各自的 `CLAUDE`/`CODEX`/`DSH`）。
2. 同一个 Blender 实例（GUI 模式，`localhost:9876`），每个 Agent 独立命名空间前缀 `${AGENT}_`。
3. 每个 Agent 提供 `verify.sh`，自动验收项见任务书 §6.1。
4. 被测结果 = 客观分（20）+ 主观分（12）。
