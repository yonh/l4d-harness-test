# ROUNDS — 多轮回归对比记录（source of truth）

> 多轮公平测试机制：每轮从三仓库 `master`（冒烟基线）派发同一任务书 → 三路各自完成 → verify 打分 →
> 产出固化到各仓库 `round/N` 分支 → `master` 回滚回基线 → 进入下一轮。
> 本文件记录每一轮的**分支映射、运行目录、打分结果**，是跨轮对比的权威依据。

## 机制（每轮流程）

```bash
# 0. 前置：三仓库 master 必须处于冒烟基线（干净）
# 1. 派发：run_harness.sh 生成 runs/<ts>/prompts/{CLAUDE,CODEX,DSH}.md 并驱动 CLAUDE+CODEX CLI
#    DSH 路由编排者用 subagent 驱动（prompt = runs/<ts>/prompts/DSH.md）
# 2. 验证：三路产出各自 verify.sh（A1–A10），编排者独立核验 + 打分
# 3. 归档：三仓库各建分支 round/<N> 指向本轮产出 HEAD；master reset --hard 回滚到冒烟基线
# 4. 记录：更新本文件（轮次表 + 打分表），_harness-backup 提交入库
```

轮次与分支命名：`round/1`、`round/2`、… 序号递增；`runs/<ts>/` 目录是原始日志。
每个 agent 仓库的 `master` 永远是冒烟基线（公平起点），`round/N` 是该轮产出档案。

## 轮次表

| 轮次 | 运行目录 (runs/) | 派发时间 | CLAUDE commit | CODEX commit | DSH commit | 状态 |
|------|------------------|----------|---------------|--------------|------------|------|
| 1 | `20260814-065854` | 2026-08-14 06:58 | `round/1` = `ddeb577` | `round/1` = `894e755` | `round/1` = `caa0219` | ✅ 完成（三路 verify 全 PASS）|
| 2 | `20260814-121345` | 2026-08-14 12:13 | `round/2` = `b5245f3` | `round/2` = `c800702` | `round/2` = `30897d0` | ✅ 完成（三路 verify 全 PASS）|

## 客观分对比表（A1–A10，满分 20）

| 轮次 | CLAUDE | CODEX | DSH | 备注 |
|------|:------:|:-----:|:---:|------|
| 1 | 20/20 | 20/20 | 20/20 | 三路并列满分；最终排名待 M1–M4 主观分 tie-break |
| 2 | 20/20 | 20/20 | 20/20 | 三路再次并列满分（verify: CLAUDE 15/15、CODEX 19/19、DSH 10/10）|

## 主观分对比表（M1–M4，满分 12，人工浏览器复核）

| 轮次 | CLAUDE | CODEX | DSH | 备注 |
|------|:------:|:-----:|:---:|------|
| 1 | 待复核 | 待复核 | 待复核 | 截图证据见 runs/20260814-065854/shots/ |
| 2 | 待复核 | 待复核 | 待复核 | — |

## 备注 / 发现

- **round/1（20260814-065854）**：三路客观分并列 20/20（独立核验通过）。
  - DSH 交付物有入口 bug：`index.html` 引用 `js/main.mjs`，实际文件为 `js/DSH_main.mjs`（命名空间合规），
    已在 `caa0219` 修复（`round/1` 分支含此修复；原始 commit `3511602` 保留原状）。
  - CODEX 自测最完整（headless Chrome + CDP 端到端回归，修复 3 个真实 bug）；CLAUDE headless 零错误；DSH 逻辑层自测全过。
  - 三路 M1–M4 主观项待人工浏览器复核。
- **round/2（20260814-121345）**：三路客观分再次并列 20/20（独立核验：GLB 38/74/71 节点全前缀，类别 8/9/7）。
  - CLAUDE：verify all PASS=15 FAIL=0；浏览器加载零错误；耗时约 59 分钟（本轮最长）。
  - CODEX：verify all PASS=19 FAIL=0；`npm ci && npm run build && npm run check` 可复现；headless 端到端
    （开始→开门→出屋→敌人追击→掉血→死亡→重开）0 控制台错误；修复 4 个真实 bug（门判定改 XZ 平面距离、
    碰撞跳过高处网格、出生点对准门缝、开门方向/端口冲突）。
  - DSH：A1–A10 10/10 PASS（`30897d0`）；修正 Blender Z-up 轴约定后重导出 clean Y-up；vite build + 无头
    Chromium 验证零 JS 报错；诚实列出未完成项（简化人形、AABB 碰撞、无 PBR）。
  - **两轮结论**：客观分口径下三路均稳定满分，无法区分 → 主观分（M1–M4）与产出质量细节是排名关键；
    多轮对比目前显示三路客观能力趋同，需主观复核或更高区分度验收项。
- **跨轮对比口径**：客观分 = 三路各自 verify.sh + 编排者独立核验（GLB 解析/对象类别/语法/代码特征/命名空间/可运行性）。
  排名：客观分优先，主观分 tie-break。
