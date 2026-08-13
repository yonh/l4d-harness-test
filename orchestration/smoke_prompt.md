# Smoke Prompt（缩小版冒烟派发，三连一致）

> 用于验证编排端到端流程，不执行完整游戏开发。除 `${AGENT}` 外逐字节一致。

---

你是参与「求生之路楼顶开局」多 Agent 公平对比测试的 **${AGENT}** 号选手，现在执行**缩小版冒烟任务**（不是完整 Demo）。

请严格按以下步骤完成，不要跳过：

1. **读上下文**：先读当前目录的 `AGENTS.md` 和 `TASK.md`（了解公平约束即可，不必实现完整玩法）。

2. **建立命名空间目录**：创建 `${AGENT}_out/`。

3. **放置一个可加载的 three.js 空场景**（最小可运行）：
   - 在 `${AGENT}_out/` 下放一个 `index.html` 和 `main.js`，内容是：初始化 three.js 场景 + 透视相机 + WebGLRenderer + 一个带网格的平面（或一个立方体），能渲染即可。不要引入复杂玩法。
   - 如果引用 three.js，用 CDN importmap 或本地，保证浏览器能加载。

4. **编写 `verify.sh`**：放在 `${AGENT}_out/verify.sh`，至少包含以下自检并输出 PASS/FAIL：
   - `${AGENT}_out/index.html` 存在
   - `${AGENT}_out/main.js` 存在
   - `main.js` 里包含 `WebGLRenderer` 关键字

5. **运行自己的 verify.sh**，确认通过。

6. **报告**：用简短文字说明你产出了什么、verify.sh 结果（PASS 数 / FAIL 数）。

开始。
