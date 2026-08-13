# skeleton —— 可复现构建骨架（占位）

目标：为每个测试项目提供一个**最小可复现的 three.js + vite 模板**占位，使所有 Agent 从一致的构建起点出发，`npm install && npm run build && npm run preview` 即可运行。

（当前为占位说明，模板引擎与包版本待定稿后填入。）

建议基准：
- 运行时：three.js（固定 minor 版本，避免安装漂移）
- 构建：vite
- 入口：`src/main.mjs` → `dist/index.html` + `dist/{AGENT}_rooftop.glb`

分发方式：`_harness-backup/skeleton/` 内的文件复制进每个 `{PROJECT}/`，作为起点提交；Agent 在起点之上实现玩法，不改动构建约定。
