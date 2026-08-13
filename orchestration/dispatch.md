# 三连派发说明（orchestration/dispatch.md）

目标：让 Claude、Codex、DSH 三个 Agent，在**各自的测试项目目录**（`l4d/claude`、`l4d/codex`、`l4d/dsh`）里，读取**同一份**任务书 `TASK.md`，产出到各自命名空间，最后统一按 `verify.sh` 打分。

## 派遣方式

### 方式一：DSH workflow（推荐用于无人值守批量）
在 DSH 会话中用 `workflow` 编排三个独立 subagent，每个 agent 负责一个项目目录：

- 每个 subagent 被分配：项目目录 + `{AGENT}` 标记（`CLAUDE`/`CODEX`/`DSH`）+ `TASK.md` 路径 + 相同评测表。
- 各自并发运行，产出到独立目录，互不干涉（命名空间隔离由任务书 §0.1 保证）。
- workflow 结束后统一收集，对三个项目的 `verify.sh` 输出打分。

### 方式二：手动三连（回归复核）
1. 依次进入 `l4d/claude`、`l4d/codex`、`l4d/dsh`。
2. 对每个项目，向对应 CLI（`claude` / `codex` / DSH 会话）发同一句提示，如：
   `请在当前目录按 TASK.md 完成《求生之路楼顶开局》Demo，产出到 ${AGENT}_out/，并编写 verify.sh。`
3. 记录每个项目的产出 commit、verify.sh 结果。

## 验收打分
- 自动项：`for p in claude codex dsh; do (cd ../$p && ./${AGENT}_out/verify.sh); done`
- 人工项：浏览器逐项复核，按任务书 §6.2 记录 0-3 分。
- 排名：客观分优先，主观分做 tie-break。

## 回归注意
- 派发前，先把 `_harness-backup` 的内容补丁进三个项目，使 TASK.md 逐字节一致。
- 每次改动任务书/编排，回到本仓库提交一个新版本，再统一分发。
