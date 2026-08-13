# 三连派发说明（orchestration/dispatch.md）

目标：让 Claude、Codex、DSH 三个 Agent，在**各自的测试项目目录**（`l4d/claude`、`l4d/codex`、`l4d/dsh`）里，读取**同一份**任务书 `TASK.md`，产出到各自命名空间，最后统一按 `verify.sh` 打分。

## 核心文件

| 文件 | 作用 |
|------|------|
| `dispatch_prompt.md` | 三连统一初始提示词模板（`${AGENT}` 占位符，逐字节一致） |
| `run_harness.sh` | 驱动 Claude + Codex 两条外部 CLI 的编排脚本（并行 + 日志） |
| `verify_template.sh` | 每个 Agent 交付物 `verify.sh` 的模板 |

## 派遣方式

### 方式一：run_harness.sh（推荐）
驱动两条外部 CLI（Claude Code、Codex）并行跑同一任务：

```bash
cd /Users/yonh/workspaces/arena/l4d
bash _harness-backup/orchestration/run_harness.sh
```

- 脚本会实例化 `${AGENT}` 为 `CLAUDE` / `CODEX` / `DSH`，生成三个逐字节一致的 prompt。
- Claude 路：`claude -p "<prompt>" --output-format json --dangerously-skip-permissions --no-session-persistence`（在 `l4d/claude`）。
- Codex 路：`codex exec --cd l4d/codex --json --dangerously-bypass-approvals-and-sandbox --ephemeral "<prompt>"`。
- 结果/日志写入 `_harness-backup/runs/<timestamp>/`。
- **DSH 路**：由编排者（当前 harness）用 `subagent` 驱动，prompt 用 `runs/<ts>/prompts/DSH.md`（脚本不负责这一路）。

### 方式二：手动三连（回归复核）
1. 依次进入 `l4d/claude`、`l4d/codex`、`l4d/dsh`。
2. 对每个项目，向对应 CLI（`claude` / `codex` / DSH 会话）发送 `dispatch_prompt.md` 实例化后的同一句提示。
3. 记录每个项目的产出 commit、verify.sh 结果。

## 验收打分
- 自动项：`for p in claude codex dsh; do (cd ../$p && bash ${AGENT}_out/verify.sh); done`
- 人工项：浏览器逐项复核，按任务书 §6.2 记录 0-3 分。
- 排名：客观分优先，主观分做 tie-break。

## 公平性注意
- **除 `${AGENT}` 外，三个 Agent 收到的初始提示词必须逐字节一致**（由 `dispatch_prompt.md` 保证）。
- 派发前，确认 `_harness-backup` 内容已同步进三个项目，`TASK.md` 除 agent 标记外逐字节一致。
- 每次改动任务书/编排/提示词，回到本仓库提交一个新版本，再统一分发。
