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

> **round/2 运行期修复**（2026-08-14 15:10，已提交到 round/2 分支）：
> - 首页卡死 bug：CODEX/DSH 的 `index.html` 缺 `importmap`，源码 `import 'three'` 在浏览器原生 ESM 下无法解析 → 模块加载失败 → 卡在静态首页。
> - 修复：CODEX `index.html` 补 importmap（含 `three/examples/jsm/` 映射）+ `src/loader.mjs` 将 vite 独有 `import url from '../x.glb'` 改为 `new URL(..., import.meta.url)`（CODEX 补丁 `3e3426a`）；DSH `index.html` 补 importmap（`bb56419`）。
> - 验证：CDP 无头实测三路均可加载进入 Playing，零模块错误；仅剩 headless 环境 PointerLock 限制（真实浏览器无碍）。
>
> **round/2 定向修复（评审反馈驱动，2026-08-14 15:30，已提交到 round/2 分支）**：
> - **CODEX 地面大面积黑块/阴影**（评审反馈"地上总有阴影"）：根因 = 光照不足，`HemisphereLight(0x36486b,0x080b12,0.5)` 下半球近黑 + 月光 0.9 无补光，ACES 映射后暗部塌黑。A/B 像素验证（同渲染器同视角）：修复前地面 mean≈10.3 → 修复后 ≈13.0，暗部不再纯黑。修复 commit `2ee15a6`：加 `AmbientLight(0x223355,0.9)`、半球光升 `(0x3a4a6e,0x141c2e,0.9)`、月光 0.9→1.15；verify 19/0 PASS。非模型问题（GLB 独立渲染正常）、非多进程污染（全程仅 1 个 Blender 进程）。
> - **DSH 完成度提升**（评审反馈"结束早、场景简单"）：commit `b205b36` —— Blender 场景 71→174 节点、材质 9→13、内嵌贴图 0→6（程序化 512px：地砖/锈/警示条/玻璃等）、新增管道群/通风井/排水沟/破损广告牌/水塔细化/杂物；敌人 Box 组合→关节骨架人形（Capsule+关节肢干）+ 动画改 `VectorKeyframeTrack`/`QuaternionKeyframeTrack`（消除 uuid 绑定 no-op 隐患）；光照冷月加强+暖点灯匹配。verify 10/10 PASS，无头 Chromium 零 console error。受限项（代码组合人形、AABB 碰撞、非 PBR）如实保留。

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

## 模型基准（round/3 起）

- 统一档位：**deepseek-v4-flash max**（用户指定，2026-08-14 调整）
- Claude: `deepseek-v4-flash[1m]` + `CLAUDE_CODE_EFFORT_LEVEL=max`（网关不支持 `-max` 后缀模型名，max 走 effort level）
- Codex: `model=deepseek-v4-flash`（slug `gpt-5.6-terra`）+ `model_reasoning_effort="max"`
- DSH: `~/.dsh/settings.yaml` → `deepseek-v4-flash` + `reasoningEffort: max`
- DEVIN: `~/.config/devin/config.json` → `deepseek-v4-flash-max`（devin models 确认存在）
- 注意：Claude 网关对 `deepseek-v4-flash-max` 返回 ModelError，不可用该模型名

## 排查记录（round/3 运行期）

- **Codex 模型名坑（2026-08-14 实测）**：`~/.codex/config.toml` 若 `model = "gpt-5.6-terra"`（deepseek-v4-flash 的 slug 别名，codex 可能自动写入），
  Codex 会话只输出 1 条开场白即 `turn.completed`（无任何工具调用/文件落地）。改回 `model = "deepseek-v4-flash"` 后恢复正常（33 事件/12 工具调用）。
  结论：**Codex 必须写模型名 `deepseek-v4-flash`，不要用 slug**。与 HANDOFF 旧记录"gpt-5.6-* 工具执行力差"一致。
- round/3 重派记录：CODEX 首次（bash-27 内）因上述坑空转，重派后正常；DSH 首次 subagent 失败（动画轨道讨论中终止），重派 `1226f5f1`。

## OpenCode 路接入（第 5 个 Agent，2026-08-14）

- 项目目录 `l4d/opencode`（git 仓库，起点 commit `20275d2`，与四路同基准）
- 驱动：`opencode run --model opencode-go/deepseek-v4-flash --variant max --format json --auto`
  （`--variant max` 对应 flash-max 档；`--auto` 自动批准权限；blender-mcp MCP 已配置）
- **模型组合（重要）**：必须用 `opencode-go/deepseek-v4-flash`（`opencode/` 前缀走另一 provider 会报 `Insufficient balance`）；`--variant max` 对应 flash-max 档。
  实测 2026-08-14：`opencode-go/deepseek-v4-flash` + `--variant max` 可用（回复正常）。
- run_harness.sh 已支持五份 prompt（CLAUDE/CODEX/DSH/DEVIN/OPENCODE）+ 四 CLI 并行（DSH 仍走 subagent）。

## round/5（20260814-184233，五路首次同步）

| Agent | commit (round/5) | verify | GLB 节点 | 对象类别 | 亮点 |
|-------|------------------|--------|----------|----------|------|
| CLAUDE | `7b269ff` | 23/23 | 59 | 11 | 7 模块含游戏状态机 |
| CODEX | `8c853e0` | 22/22 | 74 | 15 | 9 模块含开场 |
| DSH | `e6ce227` | 10/10 | 65 | 18 | 开场镜头实测生效、18 类对象、零孤儿 |
| DEVIN | `88de05e` | 7/7（含光照检查）| 71 | 10 | 修 3 bug（动画绑定语法/碰撞 epsilon/门锁存）+ E2E 全流程 |
| OPENCODE | `e3c3219` | 13/13 | 71 | 14 | 首跑成功、5 贴图、gltf-transform 0 error |

- **OPENCODE 首次接入即完成**：`opencode run --model opencode-go/deepseek-v4-flash --variant max --format json --auto`（模型必须用 `opencode-go/` 前缀）。
- **DEVIN 首跑失败一次**（云端连接错误 `retryable`），重试后完成；期间修 3 个真实 bug（three.js track 语法 `A.b.c`→bracket-index、碰撞浮点边界、门 E 键锁存）并做像素级光照验证。
- **DSH 吸取前轮教训**：GLB 零孤儿节点、出生点开阔、开场镜头实测推进。
- 归档：五路 `round/5` 分支，master 回滚基线，全部 clean。

## 计划：devin_swe1.7 独立测试（SWE-1.7 Max）

- **状态**：⏳ 计划中（等 round/6 五路完成后执行）
- **目录**：`l4d/devin_swe1.7`（git 仓库已建，起点 commit `b75c976`，与五路同基准、TASK 归一化 md5 一致）
- **Agent 标记**：`DEVIN_SWE`（命名空间前缀 `DEVIN_SWE_`）
- **模型**：`devin` CLI + `swe-1-7` = **SWE-1.7 Max**（262K context，Free；devin models list 确认）
- **驱动**：`devin -p "<prompt>" --permission-mode dangerous`（prompt 用 dispatch_prompt 实例化 `DEVIN_SWE`）
- **执行步骤**（round/6 完成后）：
  1. `clean_round.sh --force`（清理工作区 + Blender 场景）
  2. 派发：devin CLI 驱动 devin_swe1.7 路（subagent 或 CLI）
  3. verify 打分 → 归档 `round/6-swe` 或独立 round 分支 → 更新 ROUNDS.md
- **注意**：swe-1.7 是 SWE 专用模型（代码执行强项），与通用 deepseek-v4-flash-max 路不同档，结果**独立对比**（不混入五路排名）
