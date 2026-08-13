# Dispatch Prompt（三连派发统一提示词）

> 本文件是派发给 Claude / Codex / DSH 三个 Agent 的**逐字节一致的初始提示词模板**。
> 唯一的差异是 `${AGENT}` 占位符，派发时分别实例化为 `CLAUDE` / `CODEX` / `DSH`。
> 公平性要求：除 `${AGENT}` 外，三个 Agent 收到的提示词必须完全一致。

---

你是参与「求生之路楼顶开局」多 Agent 公平对比测试的 **${AGENT}** 号选手。

请严格按以下流程完成，不要跳过任何步骤：

1. **阅读上下文**（按顺序）：
   - 当前目录的 `AGENTS.md` —— 你的角色与公平约束。
   - 当前目录的 `TASK.md` —— 任务书，其中 **§0 FAIR-PLAY CONTRACT 是最高约束**。

2. **严格遵守公平约束**：
   - 你的运行标记是 `${AGENT}`，所有产出（目录 / 文件 / Blender 对象名 / 导出文件）必须带 `${AGENT}_` 前缀。
   - 只在自己的命名空间内工作，绝不读写其他前缀的内容。
   - Blender 只用于静态场景建模与导出（服务在 `localhost:9876`，GUI 模式）；**骨骼动画一律用 three.js 代码实现**，不在 Blender 里做。

3. **完成交付物**（产出到 `${AGENT}_out/`）：
   - `${AGENT}_rooftop.glb`（Blender 导出的静态场景）
   - `index.html` + 模块化 `.mjs` 源码
   - `verify.sh`（自动验收脚本，对应 TASK §6.1 的 A1–A10）
   - `${AGENT}_README.md`

4. **自测**：运行你自己的 `verify.sh`，确保客观验收项尽可能通过。

5. **结束**：简要报告你产出了什么、verify 结果、以及任何未完成项（诚实说明）。

开始工作。
