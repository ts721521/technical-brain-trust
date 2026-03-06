# 方案/计划评审记录

## 1. 评审基本信息
- 评审标题：Technical Brain Trust 部署到 Claw 可落地性评审
- 所属项目：Technical_Brain_Trust
- 发起人：Codex(GPT-5)
- 创建时间：2026-03-04 10:26:20
- 记录文件：<PROJECT_ROOT>/review_records/20260304_102620_Technical-Brain-Trust-部署到-Claw-可落地性评审.md

## 2. 评审目标
评估技术智囊团框架在 Claw 中安装部署的可执行性、运行稳定性与治理边界。

## 3. 当前方案或计划内容
# 🧠 技术智囊团宪章 (Technical Brain Trust Charter)

> **版本**：v1.0  
> **定位**：纯技术顾问团，为任何 Agent 提出的方案提供**多方法论深度审查与优化建议**。  
> **与法庭的区别**：法庭管治理（安全/合规/规则）；智囊团管技术质量（架构/创新/可靠性）。  
> **核心理念**：不只是挑毛病，更要提出更好的方案。

---

## 设计哲学（审查者必读）

> **以下是本框架的根本设计思想，所有规则和机制都服务于这些原则。审查时请以此为判断标准。**

### 1. Claw 是自治体，不是流水线上的工人

Claw（主 Agent）是一个**高自由度的自治体**，具备自我进化和自我发展能力。它自己干活、自己编排、自己学习。**不应该用层层审批和僵化流程去束缚它。** 智囊团和法庭是 Claw 在需要时可以调用的能力，而不是它执行每一步都必须经过的关卡。

### 2. 智囊团是按需调用的，不是常驻流水线

智囊团**不会**自动介入 Claw 的每一个操作。它被触发的典型场景是：
- 人类觉得单个 Agent 的方案可能考虑不周
- 方案涉及复杂技术决策（如设计新的 Agent 团队、架构变更）
- 人类主动说"让智囊团看看"

**典型工作流**：
```
人类下指令 → Claw 出方案 → 人类觉得需要加强
  → 人类触发智囊团审查
    → 三角色并行审查 + 优化建议
      → 人类看完建议 → 同意 → Claw 执行
```

### 3. 智囊团输出的是建议，不是命令

智囊团的价值是**让方案变得更好**，而不是阻止方案执行。它给评分、给建议、给替代方案——但**最终决策权在人类手中**。Claw 不需要因为智囊团的某个低分就停下来。

### 4. 复杂度本身是敌人

如果治理/审查机制太复杂，Claw 就无法自我进化和自我发展——这违背了系统存在的意义。**能简单就不复杂，能自治就不审批。** 智囊团的存在是为了在关键时刻提升质量，而不是增加日常运行的摩擦。

---

## 一、智囊团定位

```
法庭 (Court)                    智囊团 (Brain Trust)
├─ 安全：权限/密钥/越权           ├─ 架构：设计模式/可扩展性/系统拓扑
├─ 合规：宪法/状态机/规则         ├─ 质量：边缘情况/故障模式/压力测试
└─ 技术合规：接口/兼容            └─ 创新：替代方案/更优路径/前沿方法
     ↓                                ↓
 通过/不通过/附条件                 评分 + 优化建议 + 替代方案
```

**智囊团不做通过/拒绝裁决**，只做评分和建议。最终决策权归提案方或人类。

---

## 二、三角色架构

```
              ┌────────────────────┐
              │   方案提交入口      │
              │  (任何 Agent/人类)  │
              └────────┬───────────┘
                       │ 分发方案
         ┌─────────────┼─────────────┐
         │             │             │
    ┌────▼────┐   ┌────▼────┐   ┌────▼────┐
    │ 架构师   │   │ 批判者   │   │ 创新者   │
    │Architect │   │ Critic  │   │Innovator│
    │ Model A  │   │ Model B │   │ Model C │
    └────┬────┘   └────┬────┘   └────┬────┘
         │             │             │
         └─────────────┼─────────────┘
                       │
              ┌────────▼───────────┐
              │   综合审查报告      │
              │ + 优化建议 + 评分   │
              └────────────────────┘
```

### 2.1 架构师 (Architect) — `{{ARCHITECT_MODEL}}`

**视角**：系统设计者，从全局看方案是否"建得好"。

**职责**：
- 评估整体架构的合理性与可扩展性
- 审查组件间的耦合度与依赖关系
- 评估技术选型的适当性
- 识别设计模式的正确/误用
- 评估可维护性与技术债务

**使用方法论**：
- **ATAM**（Architecture Tradeoff Analysis Method）— 权衡分析
- **C4 模型思维** — 从上下文→容器→组件→代码层层审查
- **DDD 评估** — 领域边界是否合理

### 2.2 批判者 (Critic) — `{{CRITIC_MODEL}}`

**视角**：魔鬼代言人，专门找方案会怎么"死"。

**职责**：
- 攻击方案的薄弱环节（红队思维）
- 识别边缘情况和故障模式
- 压力测试逻辑链条
- 质疑未经验证的假设
- 评估最坏情况下的后果

**使用方法论**：
- **Pre-mortem 分析** — 假设方案已失败，倒推原因
- **红队/蓝队** — 主动攻击方案寻找漏洞
- **苏格拉底式追问** — 对每个关键假设连续追问"为什么"
- **FMEA**（Failure Mode and Effects Analysis）— 故障模式与影响分析

### 2.3 创新者 (Innovator) — `{{INNOVATOR_MODEL}}`

**视角**：发散思维者，问"有没有更好的方式"。

**职责**：
- 提出替代方案和优化路径
- 引入新技术/新范式的可能性
- 简化过度复杂的设计
- 发现可复用的现有方案
- 评估长期演进潜力

**使用方法论**：
- **第一性原理** — 从根本需求出发，抛开现有实现重新思考
- **TRIZ** — 用矛盾分析找到创新突破点
- **奥卡姆剃刀** — 最简方案是否可行
- **类比推理** — 其他领域的成熟方案能否借鉴

---

## 三、八大方法论详解

### 3.1 ATAM（架构权衡分析）
```
步骤：
1. 识别方案的质量属性目标（性能/安全/可用性/可修改性）
2. 识别架构决策
3. 分析每个决策对每个质量属性的影响（正面/负面/中性）
4. 识别权衡点（一个决策改善 A 但损害 B）
5. 输出权衡矩阵 + 风险点
```

### 3.2 Pre-mortem 分析
```
步骤：
1. 假设：方案已经上线 6 个月，全面失败了
2. 每个角色独立写出"它为什么失败"（至少 3 条原因）
3. 汇总所有失败原因
4. 对每条原因评估：概率（高/中/低）× 影响（高/中/低）
5. 针对高概率×高影响项提出预防措施
```

### 3.3 红队攻击
```
步骤：
1. 批判者扮演"攻击方"，尝试破坏方案
2. 攻击向量：边界绕过、状态篡改、资源耗尽、逻辑死锁、数据不一致
3. 记录每个攻击尝试的方法、结果、影响
4. 提出防御建议
```

### 3.4 苏格拉底式追问
```
对方案中的每个关键假设：
  → "为什么选择 X？" 
    → "如果 X 不成立会怎样？"
      → "有什么证据支持 X？"
        → "X 的替代方案是什么？"
          → "替代方案的代价是什么？"
```

### 3.5 第一性原理
```
步骤：
1. 剥离方案中的所有"惯例"和"业界常规"
2. 回到原始需求："本质上需要解决什么问题？"
3. 从零开始推导最小必要方案
4. 对比原方案：哪些复杂度是必要的？哪些是惯性？
```

### 3.6 FMEA（故障模式与影响分析）
```
对方案中的每个组件/模块：
  → 可能的故障模式是什么？
    → 故障的影响是什么？（严重度 S: 1-10）
      → 故障发生的概率？（频度 O: 1-10）
        → 现有检测手段？（检测度 D: 1-10）
          → 风险优先级 RPN = S × O × D
```

### 3.7 TRIZ 矛盾分析
```
步骤：
1. 识别方案中的技术矛盾（如"想要高性能但资源有限"）
2. 查找 TRIZ 发明原理中的对应解法
3. 将解法适配到当前场景
```

### 3.8 决策矩阵
```
步骤：
1. 列出所有可选方案（包括原方案和替代方案）
2. 定义评分维度（可行性/性能/成本/复杂度/可维护性/风险）
3. 为每个维度分配权重
4. 逐方案打分
5. 计算加权总分 → 输出排名
```

---

## 四、审查流程

### 4.1 触发方式

```
方式1：人类直接说 → "审查这个方案"
方式2：任何 Agent 提交 → 填写 02_Proposal_Submission_Template.md
方式3：法庭转介 → 法庭认为需要技术深度审查时转介
```

### 4.2 审查流程

```
提交方案
  │
  ├─ 1. 方案分发给三角色（并行）
  │
  ├─ 2. 架构师审查
  │     ├─ ATAM 权衡分析
  │     ├─ 架构层级审查（C4）
  │     └─ 技术选型评估
  │
  ├─ 3. 批判者审查
  │     ├─ Pre-mortem 分析
  │     ├─ 红队攻击
  │     ├─ FMEA 故障分析
  │     └─ 苏格拉底追问
  │
  ├─ 4. 创新者审查
  │     ├─ 第一性原理重推
  │     ├─ 替代方案探索
  │     ├─ 奥卡姆剃刀简化
  │     └─ 决策矩阵对比
  │
  ├─ 5. 三角色独立输出审查意见
  │
  ├─ 6. 合成综合报告
  │     ├─ 共识项（三人一致的结论）
  │     ├─ 分歧项（不同角色的不同看法）
  │     ├─ 综合评分
  │     └─ 优化建议清单（按优先级排序）
  │
  └─ 7. 返回给提案方
        ├─ 接受建议 → 修改方案 → 可选：再次审查
        └─ 不接受 → 记录理由 → 继续
```

### 4.3 审查输出评分体系

每位审查者对方案打出以下分数（1-10分）：

| 维度 | 架构师评 | 批判者评 | 创新者评 | 说明 |
|---|:---:|:---:|:---:|---|
| **可行性** | ✅ | ✅ | ✅ | 能否按描述落地实施 |
| **健壮性** | ✅ | ✅ | — | 边缘/故障场景处理 |
| **可扩展性** | ✅ | — | ✅ | 未来需求增长是否能支撑 |
| **简洁性** | ✅ | — | ✅ | 是否过度复杂 |
| **创新性** | — | — | ✅ | 是否利用了更优方法 |
| **风险度** | — | ✅ | — | 失败概率 × 影响（越低越好） |

**综合评分** = 各维度加权平均（权重可按项目调整）。

---

## 五、智囊团与法庭的协作

```
提案 → 智囊团审查（技术质量）→ 优化后方案 → 法庭审查（安全/合规）→ 执行
```

- 智囊团可在法庭审查前或审查后介入。
- 智囊团意见是**建议性**的（接不接受由提案方决定）。
- 法庭裁决是**强制性**的（必须遵守）。
- 智囊团可主动提出"我有更好的方案"，但需通过同样的审查流程。

---

## 六、模型选择原则

| 原则 | 说明 |
|---|---|
| **多样性** | 三角色**必须使用不同模型**，避免单一模型偏见 |
| **互补性** | 选择在不同能力维度上互补的模型 |
| **可替换** | 模型通过配置指定，可随时更换 |

**推荐搭配策略**：
```
方案 A（跨厂商）：
  架构师 → 强推理模型（如擅长系统设计的）
  批判者 → 强安全/对抗模型（如擅长红队思维的）
  创新者 → 强创意模型（如擅长发散思维的）

方案 B（同厂商不同模型）：
  架构师 → 厂商 X 的高端推理模型
  批判者 → 厂商 X 的代码/安全专用模型
  创新者 → 厂商 X 的通用旗舰模型
```

---

## 七、可配置参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `REVIEW_DEPTH` | `standard` | `quick`(速审) / `standard`(标准) / `deep`(深度) |
| `REQUIRED_METHODS_MIN` | 2 | 每角色最少使用多少种方法论 |
| `CONSENSUS_THRESHOLD` | 2/3 | 达成共识所需比例 |
| `AUTO_SECOND_ROUND` | false | 优化后是否自动触发第二轮审查 |
| `REPORT_FORMAT` | `structured` | 报告格式 |

### 审查深度说明

| 深度 | 方法论使用 | 预计时间 | 适用场景 |
|---|---|---|---|
| `quick` | 每角色 1 种核心方法论 | ~5 分钟 | 小变更、快速验证 |
| `standard` | 每角色 2-3 种方法论 | ~15 分钟 | 常规提案 |
| `deep` | 每角色全部方法论 | ~30 分钟 | 重大架构决策 |

---

## 附录 A 审查意见追踪表

> 供外部 AI 审查本智囊团框架时使用。  
> 在下表末尾**追加新行**，维护方会在「落实状态」和「维护方回复」列更新处理结果。

| 序号 | 模型名 | 针对 | 维度 | 意见 | 落实状态 | 维护方回复 | 复审 |
| :---: | --- | --- | --- | --- | :---: | --- | --- |
| — | *等待审查* | — | — | — | — | — | — |
| 1 | Codex (GPT-5) | 部署到 Claw | 可维护性 | 当前文档缺少“可直接执行”的部署规范（入口命令、目录约定、并行分发实现、失败重试、回滚策略）。仅有方法论与模板，无法保证一次性落地。建议新增《Claw 部署运行手册》与最小可运行示例（含真实模型ID与调用链路）。 | | | |
| 2 | Codex (GPT-5) | 评分与裁决机制 | 可靠性 | 风险度被定义为“越低越好”，但综合评分公式未定义反向归一化，实际集成时容易把高风险误算为高分。建议强制公式：`risk_score = 10 - normalized_risk`，并在模板中固定计算字段。 | | | |
| 3 | Codex (GPT-5) | 智囊团/法庭边界 | 合规性 | 文档强调“智囊团仅建议”，但未定义何时必须升级法庭（如密钥、权限、合规触发词）。若直接部署，可能出现应拦截问题被当作建议放行。建议增加强制升级规则与阻断条件。 | | | |
| 4 | Codex (GPT-5) | 运行成本与SLA | 可迭代性 | 三角色并行审查未定义 token/时延预算、fallback 次序与降级策略。生产部署到 Claw 后将难以控成本和稳定性。建议在 `config/brain_trust_config.yaml` 增加预算上限、超时与降级策略字段，并在流程中强制执行。 | | | |

*审查维度：合理性 / 可靠性 / 合规性 / 可维护性 / 可迭代性。*

---

*End of Technical Brain Trust Charter v1.0*

## 4. 项目背景文档（评审前必读）
| 文档路径/链接 | 阅读原因 |
| --- | --- |
| <PROJECT_ROOT>/00_Brain_Trust_Charter.md | 核心宪章与规则定义 |
| <PROJECT_ROOT>/01_Review_Workflow.md | 主流程与触发机制 |
| <PROJECT_ROOT>/02_Proposal_Submission_Template.md | 输入契约模板 |
| <PROJECT_ROOT>/03_Review_Report_Template.md | 输出契约模板 |
| <PROJECT_ROOT>/config/brain_trust_config.yaml | 部署参数与模型配置 |
| <PROJECT_ROOT>/roles/architect/SKILL.md | 角色执行要求 |
| <PROJECT_ROOT>/roles/critic/SKILL.md | 风险审查要求 |
| <PROJECT_ROOT>/roles/innovator/SKILL.md | 替代方案与简化要求 |

## 5. 需要其他 AI 重点评审项
- Claw集成路径与运行入口是否明确
- 评分计算可执行性与一致性
- 智囊团与法庭边界的阻断规则
- 并行审查的成本、时延与降级机制

## 6. 给其他 AI 的协作指令（可复制）
请你基于本记录开展方案评审：
1. 先完整阅读「第4节 项目背景文档」。
2. 再审阅「第3节 当前方案或计划内容」。
3. 从「第5节 重点评审项」逐项给出结论、风险、改进建议。
4. 将你的意见追加到「第7节 评审意见登记表」中，标明 AI 名称与时间。
5. 若引用项目事实，请写明对应文档路径或链接。

## 7. 评审意见登记表
| 时间 | AI/评审人 | 关注点 | 发现问题/风险 | 建议修改 | 依据文档 |
| --- | --- | --- | --- | --- | --- |
| 2026-03-04 10:26:46 | Codex(GPT-5) | Claw集成与执行入口 | 缺少可执行部署链路：当前只有方法论文档与模板，没有主Agent调用入口、并行分发实现、失败重试和回滚流程，直接安装到Claw后无法稳定运行。 | 新增《Claw部署运行手册》+ run_brain_trust_review 最小可运行示例（输入=提案Markdown，输出=结构化审查报告），并明确命令、环境变量、目录约定。 | 00_Brain_Trust_Charter.md;01_Review_Workflow.md;config/brain_trust_config.yaml |
| 2026-03-04 10:26:46 | Codex(GPT-5) | 评分可执行性 | 风险度定义为越低越好，但综合评分未给出反向归一化规则，工程实现时会产生口径不一致或误判。 | 在配置与模板中固定计算公式：risk_score = 10 - normalized_risk；并将评分计算写成可复用函数，报告里输出每维原始分与转换分。 | 00_Brain_Trust_Charter.md:4.3;03_Review_Report_Template.md |
| 2026-03-04 10:26:46 | Codex(GPT-5) | 智囊团与法庭边界 | 文档仅描述职责区别，未定义强制升级法庭的触发条件（如权限越权、密钥暴露、合规红线），存在应阻断事项被建议性放行的风险。 | 增加 court_escalation_rules：触发词、证据要求、阻断级别和处理时序；当命中规则时，智囊团报告必须附“暂停执行”标记。 | 00_Brain_Trust_Charter.md:一、五 |
| 2026-03-04 10:26:46 | Codex(GPT-5) | 成本、时延与降级机制 | 三角色并行审查没有token预算、超时控制、fallback顺序与降级策略，落地后将难以控成本和SLA。 | 在配置中增加 max_tokens_per_review, timeout_seconds, fallback_order, degraded_mode；并定义超时后的最小可交付报告。 | config/brain_trust_config.yaml;01_Review_Workflow.md |
| 2026-03-04 17:59:31 | Codex(GPT-5) | 执行编排可落地性 | 文档已定义人工分发与报告合成流程，但仓库未提供可执行的 orchestrator/workflow 脚本或 .agents/workflows 文件，当前只能人工执行，无法保证稳定并行与可重复交付。 | 补齐最小可运行入口（例如 run_brain_trust_review.sh 或 .agents/workflows/brain_trust_review.md），实现：输入提案→并行调用三角色→生成 summary_report.md + structured_summary.json。 | 01_Review_Workflow.md:45-75;03_Review_Report_Template.md:1-103;仓库文件清单缺少 workflow/script 可执行入口 |
| 2026-03-04 17:59:31 | Codex(GPT-5) | 配置可部署性 | config/brain_trust_config.yaml 与角色 SKILL 仍包含 {{...}} 模型占位符，未实参化时会导致 Claw 运行时无法按角色加载真实模型与 fallback。 | 新增 deployment.env.example（或 setup 脚本）并在部署步骤中增加“占位符替换校验”，要求部署前所有 {{...}} 已替换为可用模型ID。 | config/brain_trust_config.yaml:9-20;00_Brain_Trust_Charter.md:109,125,142;roles/architect/SKILL.md:10;roles/critic/SKILL.md:10;roles/innovator/SKILL.md:10 |
| 2026-03-04 17:59:31 | Codex(GPT-5) | 治理边界一致性 | 宪章附录声称“强制升级法庭规则 + court_escalation 字段已落实”，但正文未提供可执行规则条款，三角色结构化摘要也未包含 court_escalation 字段，落地时无法程序化触发升级。 | 在宪章正文新增强制升级规则表（触发条件/证据/动作），并统一三角色 JSON 输出契约（mandatory: court_escalation{required,reason,severity}）。 | 00_Brain_Trust_Charter.md:390-399;roles/architect/SKILL.md:99-106;roles/critic/SKILL.md:113-120;roles/innovator/SKILL.md:147-154 |
| 2026-03-04 17:59:31 | Codex(GPT-5) | CLI 命令兼容性 | 部署文档中的关键 CLI 命令与本地 OpenClaw 2026.3.2 基本兼容，这是可落地的正向条件；但文档未给出 --non-interactive 与失败重试示例，批量部署时仍存在人工中断风险。 | 在部署指南补充一套非交互命令模板（agents add --non-interactive）与幂等重试示例，降低首次部署失败率。 | 00_DEPLOY_BRAIN_TRUST.md:320-359;本地命令帮助: openclaw agents --help/openclaw agents add --help/openclaw agents set-identity --help |
## 8. 最终结论与后续动作
- 结论：`有条件通过`
- 后续动作：
- 补齐并提交可执行编排入口文件（workflow 或脚本）
- 完成占位符实参化并增加部署前校验
- 统一 court_escalation 规则与三角色 JSON 契约后再做一次端到端演练

## 9. 天条对齐修订留痕（2026-03-04）

| 冲突点 | 对应天条 | 修改文件 | 修改摘要 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- | --- |
| 工作流存在外部转介链路 | 天条一 | 00_Brain_Trust_Charter.md;01_Review_Workflow.md | 删除“外部转介/升级”流程，固化纯智囊团闭环（提案->三角色并行->综合报告->人类拍板） | 已完成（关键文档未再出现相关流程词） | 2026-03-04 |
| 天条三仅在单角色中强制 | 天条三 | roles/architect/SKILL.md;roles/critic/SKILL.md;roles/innovator/SKILL.md;03_Review_Report_Template.md | 三角色统一新增“意图纠偏结论”与 `intent_alignment` 结构化字段；报告模板新增“意图纠偏汇总” | 已完成（3 角色契约字段一致） | 2026-03-04 |
| 天条四缺少证据位点 | 天条四 | roles/architect/SKILL.md;roles/critic/SKILL.md;roles/innovator/SKILL.md;03_Review_Report_Template.md | 三角色 JSON 新增 `opensource_validation[]`；报告模板新增“开源推荐验证证据”章节 | 已完成（推荐开源时有强制证据位点） | 2026-03-04 |
| 天条六未形成模板约束 | 天条六 | 00_Brain_Trust_Charter.md;roles/architect/SKILL.md;roles/critic/SKILL.md;roles/innovator/SKILL.md;03_Review_Report_Template.md | 在宪章新增“原则落地约束”；角色与报告模板新增“复杂度削减建议/结论” | 已完成（模板中存在强制位点） | 2026-03-04 |
| 配置仅占位符不可直接部署 | 天条二 | config/brain_trust_config.yaml;config/brain_trust.env.example;scripts/validate_brain_trust_env.sh | 模型配置改为环境变量契约，新增部署前校验脚本（必填变量、模型互异、runtime键完整） | 已完成（校验脚本可执行） | 2026-03-04 |
| 缺少可执行入口 | 天条二/六 | .agents/workflows/brain_trust_review.md;scripts/run_brain_trust_review.sh | 新增 workflow 与执行脚本，支持并行三角色审查并生成 5 个产物 | 已完成（脚本/工作流已创建并通过语法检查，未执行线上模型调用） | 2026-03-04 |
| 部署过程交互/不幂等 | 天条六 | 00_DEPLOY_BRAIN_TRUST.md | 新增 Step 0（env+校验），补充 `--non-interactive` 与幂等重试示例 | 已完成（文档命令可复制执行） | 2026-03-04 |

## 10. 三专家联合复审（2026-03-04）

| 专家角色 | 方法论 | 关键发现 | 评分 | 对天条影响 | 结论 | 时间 |
| --- | --- | --- | --- | --- | --- | --- |
| 架构师 | ATAM + C4 + 意图偏差检测 | 角色契约已形成结构化闭环（intent_alignment + complexity_reduction + opensource_validation），聚合脚本兼容新旧输出，部署路径可执行性显著提升。 | 9.2/10 | 天条二/三/六落实度提升，尤其是“方法论+输出”双重约束已建立。 | 建议采纳 | 2026-03-04 |
| 批判者 | Pre-mortem + 红队 + FMEA + 意图偏差检测 | 主要风险点从“字段缺失”转为“角色输出不规范时的退化行为”，当前已提供回退策略和降级标记，剩余风险可控。 | 8.9/10 | 天条三与天条六从口号变为可验证机制，风险由高降至中低。 | 建议优化后采纳（持续监控输出一致性） | 2026-03-04 |
| 创新者 | 第一性原理 + 决策矩阵 + 奥卡姆 + 意图偏差检测 | 在不扩展治理体系的前提下完成最小补强，避免过度设计；新增 complexity_reduction 独立结构，比关键词猜测更稳健。 | 9.3/10 | 天条六（简单至上）得到更工程化表达，且未引入额外外部依赖。 | 建议采纳 | 2026-03-04 |

### 联合结论（建议语义）

- **综合建议等级**：`建议采纳`
- **联合评分（参考）**：`9.1/10`
- **共识项**：
  1. 天条三已从“字段约束”升级为“方法论+字段”双重约束。
  2. 天条六已从“关键词猜测”升级为“结构化输入优先 + 回退兼容”。
  3. 当前方案保持最小改动，不增加外部治理耦合。
- **分歧项（轻微）**：
  1. 是否进一步自动化 `final_score` 计算：本轮按约束保持人工计算位，后续可作为独立迭代。

## 11. 自评建议采纳与可靠性补强留痕（2026-03-04）

| 建议项 | 采纳结论 | 修改文件 | 修改摘要 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- | --- |
| 综合评分自动计算（final_score 不再硬编码 0） | 采纳 | scripts/run_brain_trust_review.sh;03_Review_Report_Template.md | 在合成逻辑中新增按权重自动计算综合分；模板同步“自动计算+人工复核可选”与字段示例。 | 已完成（语法检查通过，结构化输出字段已更新） | 2026-03-04 |
| 角色超时控制 + 重试 | 采纳 | scripts/run_brain_trust_review.sh | 增加基于配置的超时与重试机制（timeout_per_role_seconds / max_attempts / backoff_seconds），失败写入 attempt 留痕。 | 已完成（脚本语法通过；失败路径会生成 stderr 留痕） | 2026-03-04 |
| 降级模式评分重归一化 | 采纳 | scripts/run_brain_trust_review.sh;03_Review_Report_Template.md | 缺失维度时仅对可用维度重归一化权重，输出 used_weights 与 missing_dimensions。 | 已完成（score_summary 字段已落地） | 2026-03-04 |
| 方案长度保护（超长截断并留痕） | 采纳 | config/brain_trust_config.yaml;scripts/validate_brain_trust_env.sh;scripts/run_brain_trust_review.sh | 新增 runtime.max_proposal_chars，超限截断并输出 input_guard 审计字段。 | 已完成（配置与校验脚本已同步） | 2026-03-04 |
| JSON 解析多策略回退与诊断 | 采纳 | scripts/run_brain_trust_review.sh | JSON 提取从单一正则升级为 fenced/raw_decode/whole_text 多策略，新增 parse_diagnostics。 | 已完成（解析失败不再中断合成流程） | 2026-03-04 |

## 12. 评审编排机制吸纳留痕（2026-03-04）

| 建议项 | 采纳结论 | 修改文件 | 修改摘要 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- | --- |
| 三段式编排（独立评审 -> 交叉复核 -> 总编整合） | 采纳 | 01_Review_Workflow.md;00_Brain_Trust_Charter.md | 工作流与宪章同步引入三段式结构，保留人类最终拍板。 | 已完成（文档流程一致） | 2026-03-04 |
| 引入总编/整合角色 | 条件采纳 | 01_Review_Workflow.md;00_Brain_Trust_Charter.md | 新增 Editor/Chair 定位，职责为消重合并与冲突说明，不做裁决。 | 已完成（语义保持建议制） | 2026-03-04 |
| 统一量表 + 强制 P0/P1/替代方案/验证方式 | 采纳 | 01_Review_Workflow.md;00_Brain_Trust_Charter.md;03_Review_Report_Template.md | 明确统一量表与输出约束，新增 P0/P1 清单及行动项模板。 | 已完成（模板与流程对齐） | 2026-03-04 |
| Go/No-Go 与总编裁决权 | 不采纳 | 00_Brain_Trust_Charter.md;03_Review_Report_Template.md | 保持“建议语义”，明确智囊团与总编不做最终裁决。 | 已完成（符合天条一与设计哲学） | 2026-03-04 |

## 13. 三段式编排脚本落地留痕（2026-03-04）

| 建议项 | 采纳结论 | 修改文件 | 修改摘要 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- | --- |
| Stage 2 交叉复核落地到执行脚本 | 采纳 | scripts/run_brain_trust_review.sh | 新增交叉复核 prompt 与执行函数，生成 `*_cross_review.md` 产物并记录 Stage 2 状态。 | 已完成（回归脚本通过，产物可生成） | 2026-03-04 |
| Stage 3 总编整合落地到执行脚本 | 采纳 | scripts/run_brain_trust_review.sh | 新增总编整合输出 `editor_review.md`，结构化摘要新增 `final_recommendation/orchestration/editor_summary`。 | 已完成（结构化 JSON 可解析） | 2026-03-04 |
| 输出契约与配置同步 | 采纳 | 03_Review_Report_Template.md;config/brain_trust_config.yaml | 模板补充编排字段示例；配置 output.files 增加 cross review 与 editor 产物。 | 已完成（文档与脚本一致） | 2026-03-04 |

## 14. 最小一致性修补留痕（2026-03-04）

| 建议项 | 采纳结论 | 修改文件 | 修改摘要 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- | --- |
| final_recommendation 纳入 Stage 2 状态 | 采纳 | scripts/run_brain_trust_review.sh | 将 `stage2_status` 纳入建议语义判定，避免 Stage 2 不足时误判“建议采纳”。 | 已完成（回归通过） | 2026-03-04 |
| Stage 1 强制输出新增契约字段 | 采纳 | scripts/run_brain_trust_review.sh | 提示词新增 `consensus_checks/p0_items/p1_items/alternative_proposals` 与固定条目格式约束。 | 已完成（脚本语法+回归通过） | 2026-03-04 |
| 审查入口文档与三段式同步 | 采纳 | 00_START_REVIEW_HERE.md | 更新为“三角色+总编整合”口径，并指向统一评审记录留痕。 | 已完成（文档检查通过） | 2026-03-04 |
| 部署文档补三段式 E2E 验收 | 采纳 | 00_DEPLOY_BRAIN_TRUST.md | 新增 `run_brain_trust_review.sh` 端到端验证步骤和 9 个产物检查。 | 已完成（命令可复制执行） | 2026-03-04 |

## 15. 契约对齐补丁留痕（2026-03-04）

| 建议项 | 采纳结论 | 修改文件 | 修改摘要 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- | --- |
| 补齐 orchestration.stage3_status 契约字段 | 采纳 | scripts/run_brain_trust_review.sh;03_Review_Report_Template.md;scripts/test_run_brain_trust_review_regression.sh | 结构化摘要新增 `orchestration.stage3_status`；模板示例同步；回归脚本新增断言，确保契约长期稳定。 | 已完成（语法检查通过，回归通过） | 2026-03-04 |
| 兼容 openclaw JSON 包装输出 | 采纳 | scripts/run_brain_trust_review.sh | 角色输出提取器新增 `payloads[].text` 解包逻辑，避免真实运行中分数字段提取不到导致 `final_score=0`。 | 已完成（实跑可解析到已成功角色的 scores） | 2026-03-04 |

## 16. 四供应商模型分配与容灾留痕（2026-03-05）

约束补充：
- OpenAI 硬约束：仅允许 `openai-codex/gpt-5.3-codex`，禁用 Spark 与其他 OpenAI 版本。
- Stage1 从并行改为串行：原因是 OpenClaw 默认模型配置全局共享，并行会产生模型覆盖冲突。

| 角色 | 主模型 | fallback1 | fallback2 | fallback3 | 实际生效 | 切换结果 | 时间 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| architect | openai-codex/gpt-5.3-codex | zai/glm-5 | google-gemini-cli/gemini-3.1-pro-preview | bailian/qwen3.5-plus | 运行时按角色链路 attempt1->4 切换 | 已支持 timeout/quota 触发后补切换并留痕到 `model_routing_summary` | 2026-03-05 |
| critic | zai/glm-5 | openai-codex/gpt-5.3-codex | google-gemini-cli/gemini-3-pro-preview | bailian/qwen3-max-2026-01-23 | 同上 | 同上 | 2026-03-05 |
| innovator | google-gemini-cli/gemini-3.1-pro-preview | openai-codex/gpt-5.3-codex | zai/glm-4.7 | bailian/kimi-k2.5 | 同上 | 同上 | 2026-03-05 |

可用模型快照：
- `/tmp/brain_trust_model_inventory/available_models.json`
- `/tmp/brain_trust_model_inventory/available_models.md`

## 17. GitHub发布与可移植部署留痕（2026-03-05）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增仓库基线文件（README/.gitignore） | README.md;.gitignore | 建立 GitHub 发布最小基线，统一入口与忽略规则，避免把本地敏感/运行产物提交到远端。 | 已完成（文件存在且规则覆盖 env/产物/临时目录） | 2026-03-05 |
| 新增发布说明与变更记录 | DEPLOYMENT_RELEASE.md;DEPLOYMENT_CHANGELOG.md | 形成“可复制执行 + 可追踪迭代”的发布文档双件套。 | 已完成（发布入口、验收矩阵、故障恢复、变更格式已落地） | 2026-03-05 |
| 新增发布元数据契约 | config/deployment_release.yaml | 把版本、兼容、模型策略、验收命令固化为机器可读真源。 | 已完成（release_version/openclaw_compatibility/openai_policy 等字段齐全） | 2026-03-05 |
| 新增统一部署入口脚本 | scripts/bootstrap_brain_trust.sh | 让其他 AI 在新 Claw 环境可一条命令执行预检、注册、同步、回归、E2E 并生成报告。 | 已完成（脚本参数与部署报告契约已实现） | 2026-03-05 |
| 新增 GitHub CI 验证工作流 | .github/workflows/brain_trust_verify.yml | 把脚本语法与回归测试纳入 PR/主干门禁，防止发布回归。 | 已完成（workflow 已创建，校验项与回归项可执行） | 2026-03-05 |
| 部署手册入口重定向 | 00_DEPLOY_BRAIN_TRUST.md | 明确标准发布入口，减少执行分歧。 | 已完成（文档顶部已标注以 DEPLOYMENT_RELEASE 为准） | 2026-03-05 |

## 18. 盘古执行闭环落地留痕（2026-03-05）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| Stage4 执行阶段落地（默认自动触发） | scripts/run_brain_trust_review.sh | 解决“三段式只审不执”缺口，形成 Stage1/2/3/4 闭环。 | 已完成（回归含正常与 `pangu_fail` 降级路径通过） | 2026-03-05 |
| Stage4 契约字段写入结构化摘要 | scripts/run_brain_trust_review.sh;03_Review_Report_Template.md | 固化 `orchestration.stage4_status/stage4_executor` 与 `execution_summary` 机读契约。 | 已完成（`structured_summary.json` 含新增字段） | 2026-03-05 |
| Bootstrap 纳入 pangu 与 Stage4 报告字段 | scripts/bootstrap_brain_trust.sh | 部署报告需可证明 Stage4 链路可用。 | 已完成（report 增加 `agents.required`、`execution_chain.status`、`e2e.stage4_status`） | 2026-03-05 |
| 环境校验新增 pangu 与 execution 配置约束 | scripts/validate_brain_trust_env.sh;config/brain_trust_config.yaml | 防止缺少执行角色或缺失 runtime.execution 导致运行时失败。 | 已完成（脚本语法通过，键与 agent 检查生效） | 2026-03-05 |
| 回归脚本新增 Stage4 断言 | scripts/test_run_brain_trust_review_regression.sh | 防止后续变更回退 Stage4 行为。 | 已完成（断言 `stage4_status/execution_summary` 与产物存在） | 2026-03-05 |
| 环境缺失 pangu 导致校验失败 | scripts/validate_brain_trust_env.sh;scripts/bootstrap_brain_trust.sh | Stage4 启用后 `pangu` 成为硬依赖；需在部署链路中自动纳入。 | 已完成（幂等注册 `pangu` 后 `validate` 通过，bootstrap 报告显示 `agents.required` 包含 `pangu`） | 2026-03-05 |
| 工作流/宪章/部署文档改为四段式口径 | .agents/workflows/brain_trust_review.md;01_Review_Workflow.md;00_Brain_Trust_Charter.md;00_DEPLOY_BRAIN_TRUST.md;DEPLOYMENT_RELEASE.md;README.md;00_START_REVIEW_HERE.md | 消除“文档口径与实现不一致”。 | 已完成（Stage1 串行 + Stage4 自动执行语义统一） | 2026-03-05 |
| 发布元数据与验收项更新 Stage4 | config/deployment_release.yaml;DEPLOYMENT_CHANGELOG.md | 保证跨 Claw 移植时可按同一契约验收。 | 已完成（release 升级 `v1.1.0`，新增 Stage4 验收检查） | 2026-03-05 |

## 19. 盘古执行权限与多层调度落盘留痕（2026-03-05）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| pangu agent 级执行权限落盘 | `~/.openclaw/openclaw.json` | 保持 `main` 入口不提权，仅对 `pangu` 开启执行能力，匹配“执行+孵化”职责。 | 已完成（`global tools.profile=messaging`，`pangu.tools.profile=full`） | 2026-03-05 |
| 审批模式与最小 allowlist 落盘 | `~/.openclaw/exec-approvals.json` | 防止全自动高危放开，同时确保 `clawhub` 操作不被无谓阻塞。 | 已完成（保留审批模式，`agents.pangu.allowlist` 增加 `/opt/homebrew/bin/clawhub`） | 2026-03-05 |
| 盘古工作区规则改造（执行+孵化+防空转） | `~/.openclaw/workspaces/pangu/AGENTS.md`;`~/.openclaw/workspaces/pangu/SOUL.md`;`~/.openclaw/workspaces/pangu/TOOLS.md` | 修复“盘古只会建议、不直接执行”和“session_status 空转”问题，并固化 scheduler 孵化模板。 | 已完成（文档已落盘，包含审批、SOP、回滚与 anti-loop 规则） | 2026-03-05 |
| 项目部署文档同步运行策略 | 00_DEPLOY_BRAIN_TRUST.md;DEPLOYMENT_RELEASE.md;config/deployment_release.yaml | 保证“运行配置与仓库文档”一致，便于跨 Claw 1:1 复刻。 | 已完成（新增 runtime topology 与 permission policy，release 升级 `v1.2.0`） | 2026-03-05 |
| 盘古执行能力实测（本地模式） | OpenClaw runtime（agent:pangu） | 验证盘古已不再是 `sessions_*` 限制工具集，需可直接执行外部命令。 | 已完成（`openclaw agent --agent pangu --local` 实测可调用 `exec` 并成功执行 `clawhub inspect self-improving-agent`；首选模型超时后后补模型成功） | 2026-03-05 |
| `self-improving-agent` 安装阻塞与恢复指引 | 00_DEPLOY_BRAIN_TRUST.md;DEPLOYMENT_RELEASE.md | 实测安装命令出现 `Rate limit exceeded`，且 `openclaw skills info` 对第三方 ClawHub 技能存在可见性差异。 | 已完成（文档新增 `clawhub login -> install -> clawhub list` 主验证链，并补充兼容性说明） | 2026-03-05 |

## 20. Main 分发中枢与分层记忆治理落地留痕（2026-03-05）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| main agent 级执行权限落盘 | `~/.openclaw/openclaw.json` | main 需具备“可执行或可分发”的基础能力，避免只给命令模板。 | 已完成（`main.tools.profile=full`，全局 `tools.profile=messaging` 保持不变） | 2026-03-05 |
| main 最小 allowlist 落盘 | `~/.openclaw/exec-approvals.json` | 在审批模式下支持 main 执行安装/检查/同步类任务。 | 已完成（`main` 新增 `openclaw/clawhub/git/python3/pip3` 最小条目） | 2026-03-05 |
| main 路由学习规则固化 | `~/.openclaw/workspace/AGENTS.md`;`~/.openclaw/workspace/SOUL.md`;`~/.openclaw/workspace/TOOLS.md` | 建立“分类执行 + 自动委派 + 路由学习落盘”闭环。 | 已完成（新增 intent 分类、自动分发与 `ROUTING_DECISIONS.jsonl` 记录要求） | 2026-03-05 |
| 盘古直写增强与审计规则固化 | `~/.openclaw/workspaces/pangu/AGENTS.md`;`~/.openclaw/workspaces/pangu/SOUL.md`;`~/.openclaw/workspaces/pangu/TOOLS.md` | 允许盘古增强 main，同时限制越界并强制留痕。 | 已完成（新增直写白名单、禁止路径和双日志审计要求） | 2026-03-05 |
| 分层记忆目录初始化 | `~/.openclaw/workspace/memory/*`;`~/.openclaw/workspaces/pangu/memory/*`;`~/.openclaw/workspaces/.scheduler-template/memory/*` | 当前缺少长期记忆层，需建立主共享/角色私有结构。 | 已完成（目录与模板文件已创建） | 2026-03-05 |
| 新增治理脚本（初始化/压缩/晋升） | `scripts/bootstrap_agent_memory_layers.sh`;`scripts/route_learning_compact.sh`;`scripts/promote_skill_from_pangu_to_main.sh` | 让分层记忆和灰度晋升可执行、可重复、可审计。 | 已完成（脚本创建并设置可执行权限） | 2026-03-05 |
| 发布文档与元数据同步 | 00_DEPLOY_BRAIN_TRUST.md;DEPLOYMENT_RELEASE.md;config/deployment_release.yaml | 保证跨 Claw 部署口径一致并可复刻。 | 已完成（release 升级 `v1.3.0`，新增 main mixed router 与 memory governance 契约） | 2026-03-05 |

## 21. Main 委派可达性补丁留痕（2026-03-05）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增委派可达性契约 | `~/.openclaw/workspace/AGENTS.md`;`~/.openclaw/workspace/TOOLS.md` | 修复“会分配但不一定送达”缺口，固化 `delegate_preflight` 与 `send->spawn->resend`。 | 已完成（新增失败码与重任务降级策略，不再要求 main 强兜底） | 2026-03-05 |
| 路由日志结构扩展 | `~/.openclaw/workspace/memory/ROUTING_DECISIONS.jsonl`;`scripts/route_learning_compact.sh` | 提升委派问题可诊断性，统计恢复率与不可达频次。 | 已完成（脚本可输出 delegate success/recovery/unreachable 指标） | 2026-03-05 |
| 新增委派可靠性验证脚本 | `scripts/verify_main_delegate_reliability.sh` | 把委派三场景（正常/会话缺失恢复/不可达降级）转为可重复验收。 | 已完成（脚本输出 `delegate_reliability_report.json`，默认 mock 可稳定通过） | 2026-03-05 |
| 部署与发布元数据同步 | 00_DEPLOY_BRAIN_TRUST.md;DEPLOYMENT_RELEASE.md;config/deployment_release.yaml;DEPLOYMENT_CHANGELOG.md | 保障跨 Claw 复刻时策略、验收、版本一致。 | 已完成（release 升级 `v1.3.1`） | 2026-03-05 |

## 22. 盘古突发任务排程补丁留痕（2026-03-05）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增 execution_heavy 队列排程契约 | config/brain_trust_config.yaml;scripts/run_brain_trust_review.sh | 解决“突发任务下仅委派无排程”缺口，补齐 `max_inflight/queue_max/backlog_scale_threshold` 等运行约束。 | 已完成（配置已生效，Stage4 接入调度入口） | 2026-03-05 |
| 新增队列调度脚本 | scripts/pangu_task_scheduler.sh | 提供 `enqueue/dispatch-once/complete/drain/stats` 原子调度能力，并基于文件锁保证并发安全。 | 已完成（脚本创建并通过语法检查） | 2026-03-05 |
| 新增扩容脚本 | scripts/ensure_scheduler_capacity.sh | 当积压超过阈值时自动复用/孵化 `scheduler-*`，并输出路由动作与失败码。 | 已完成（脚本创建并通过语法检查） | 2026-03-05 |
| Stage4 输出新增排程摘要 | scripts/run_brain_trust_review.sh;03_Review_Report_Template.md | 让调度行为可审计，结构化输出 `scheduling_summary`（队列ID、等待时延、调度目标、扩容动作）。 | 已完成（`structured_summary.json` 字段已补齐） | 2026-03-05 |
| 路由学习指标扩展 | scripts/route_learning_compact.sh | 增加排程视角统计（排队占比、平均等待、扩容次数、路由次数）。 | 已完成（脚本输出新增 scheduler_metrics） | 2026-03-05 |
| 运行时规则与发布文档同步 | ~/.openclaw/workspace/AGENTS.md;~/.openclaw/workspace/TOOLS.md;~/.openclaw/workspaces/pangu/AGENTS.md;00_DEPLOY_BRAIN_TRUST.md;DEPLOYMENT_RELEASE.md;config/deployment_release.yaml;DEPLOYMENT_CHANGELOG.md | 保证“运行策略、实施手册、发布契约”一致，便于跨环境复刻。 | 已完成（release 升级 `v1.4.0`） | 2026-03-05 |

## 23. GitHub 发布隔离与可复制交付留痕（2026-03-05）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 引入双分支发布模型（main/release） | README.md;DEPLOYMENT_RELEASE.md | 防止真实迭代与公开发布互相污染，保证公开版本稳定可复制。 | 已完成（文档明确分支职责与发布流程） | 2026-03-05 |
| 新增发布白名单清单 | release/release_manifest.txt | 固化“哪些文件可进入 release”规则，避免夹带本地运维细节。 | 已完成（manifest 已覆盖公开必要文件） | 2026-03-05 |
| 新增公开安全检查脚本 | scripts/verify_public_release.sh | 提交前阻断密钥模式、个人绝对路径、运行态污染文件。 | 已完成（脚本创建并纳入校验链） | 2026-03-05 |
| 新增 release 分支构建脚本 | scripts/build_release_branch.sh | 从 main 自动生成 release，保证发布可重复、可审计、可打标签。 | 已完成（支持版本号、dry-run、报告输出） | 2026-03-05 |
| 新增 release 分支 CI 门禁 | .github/workflows/public_release_verify.yml | 对 release 的 push/PR 强制执行公开安全检查，失败阻断合并。 | 已完成（workflow 已创建） | 2026-03-05 |
| 发布元数据与版本同步 | config/deployment_release.yaml;DEPLOYMENT_CHANGELOG.md | 把新发布机制纳入契约真源与版本演进记录。 | 已完成（release_version 更新为 v1.4.1） | 2026-03-05 |

## 24. AI可感知发布机制与人类手册补强留痕（2026-03-05）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增 AI 发布协议文档 | docs/AI_RELEASE_PROTOCOL.md | 让其他 AI 能直接识别角色分工、阻断条件与发布命令。 | 已完成（协议含角色、流程、阻断条件、输出契约） | 2026-03-05 |
| 新增人类发布 Runbook | docs/HUMAN_RELEASE_RUNBOOK.md | 给人类维护者提供单页可执行步骤与故障恢复路径。 | 已完成（含触发条件、5步流程、回滚与验收清单） | 2026-03-05 |
| 新增发布导航页 | docs/RELEASE_OVERVIEW.md | 提供 AI 与人类统一入口，降低机制理解成本。 | 已完成（含总览图、索引、Quick Path） | 2026-03-05 |
| 新增文档一致性校验脚本 | scripts/check_release_docs_consistency.sh | 防止发布文档漂移，保证版本与命令一致。 | 已完成（脚本可执行且纳入验收链） | 2026-03-05 |
| CI 增加文档一致性门禁 | .github/workflows/public_release_verify.yml | release 分支不仅校验安全，还校验机制可理解。 | 已完成（新增语法与执行步骤） | 2026-03-05 |
| release 白名单纳入 docs | release/release_manifest.txt | 确保公开分支包含 AI 协议与人类手册。 | 已完成（manifest 已追加 docs 路径） | 2026-03-05 |
| 元数据与版本同步到 v1.4.2 | config/deployment_release.yaml;DEPLOYMENT_CHANGELOG.md;DEPLOYMENT_RELEASE.md;README.md | 保证发布版本、文档入口、验收命令一致。 | 已完成（版本与命令已同步） | 2026-03-05 |

## 25. 静态矩阵移除与团队接口代理契约上线留痕（2026-03-05）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 静态模型矩阵从部署口径移除 | 00_DEPLOY_BRAIN_TRUST.md;DEPLOYMENT_RELEASE.md | 模型分配改为架构阶段动态输出物，避免部署层写死。 | 已完成（文档新增“动态输出契约”，无静态团队矩阵要求） | 2026-03-05 |
| 新增 LuBan 团队输出模板 | roles/luban/AGENTS.md;roles/luban/TOOLS.md;roles/luban/templates/* | 固化团队创建必须产出 3 文件（蓝图、Agent 契约、模型分配）。 | 已完成（模板已落盘） | 2026-03-05 |
| 新增团队契约校验脚本 | scripts/validate_team_contract.sh | 缺文件或 schema 不合法时阻断实施。 | 已完成（脚本新增并可执行） | 2026-03-05 |
| 新增 LuBan 初始化脚本 | scripts/bootstrap_luban_role.sh | 统一创建鲁班工作区、模板和初始化报告，保证可复刻。 | 已完成（脚本新增并接入 bootstrap） | 2026-03-05 |
| bootstrap 链路纳入 LuBan 与契约校验 | scripts/bootstrap_brain_trust.sh | 部署阶段即验证“接口代理”契约，防止后置风险。 | 已完成（deploy report 增加 `luban` 与 `team_contract_validation` 状态） | 2026-03-05 |
| 发布元数据纳入契约与脚本检查 | config/deployment_release.yaml;release/release_manifest.txt | 保证 release 产物包含 LuBan 规则与校验脚本。 | 已完成（required_scripts/acceptance_checks/manifest 已更新） | 2026-03-05 |

## 26. 质量自把关与持续提升补充留痕（2026-03-06）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增质量自把关原则（QSGP）与持续提升原则（QEL） | 00_Brain_Trust_Charter.md | 将“团队自治”扩展为“质量自治”，避免交付无门禁、无责任闭环。 | 已完成（新增 5.5 条款，明确三关门禁与 blocked 规则） | 2026-03-06 |
| 工作流新增 Stage 5 质量门禁与改进回写 | 01_Review_Workflow.md | 让 Stage4 后有质量复核与周期改进出口，形成可持续提升闭环。 | 已完成（Stage 5、失败处理与产物定义已落盘） | 2026-03-06 |
| 审查入口新增质量检查项 | 00_START_REVIEW_HERE.md | 审查阶段强制检查 `quality_gate_report` 与 `quality_improvement_log`，防止遗漏。 | 已完成（检查清单新增 QSGP/QEL 条目） | 2026-03-06 |
| 发布说明补充质量闭环契约 | DEPLOYMENT_RELEASE.md | 在发布级文档中同步“质量自把关 + 持续改进”设计约束，统一口径。 | 已完成（新增 Quality Closed-Loop Contract 节） | 2026-03-06 |
| 元数据新增质量契约产物与验收检查 | config/deployment_release.yaml | 将质量契约转为机器可读项，支持后续自动化校验与追踪。 | 已完成（新增 quality_contract_outputs/constraints 与 rg 验收项） | 2026-03-06 |

## 27. 执行阻塞与“假完成”P0热修留痕（2026-03-06）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| Stage4 新增完成态硬门禁（execution_proof） | scripts/run_brain_trust_review.sh | 解决“返回成功但未落地产物”问题，禁止仅凭调用返回标记完成。 | 已完成（proof 不通过强制降级，失败码 `completion_without_artifact`） | 2026-03-06 |
| 队列 complete 新增 proof 参数与强制校验 | scripts/pangu_task_scheduler.sh | 防止 `execution_heavy` 任务在无关键产物时误标 `completed`。 | 已完成（`--result success` 需 proof；否则自动转 failed） | 2026-03-06 |
| Stage4 失败诊断写回 parse_diagnostics | scripts/run_brain_trust_review.sh | 让调度失败与执行失败进入统一结构化诊断，不再静默失败。 | 已完成（新增 `stage4:*` 与 `scheduler:*` 诊断条目） | 2026-03-06 |
| Stage4 失败/降级写入路由流水 | scripts/run_brain_trust_review.sh;~/.openclaw/workspace/memory/ROUTING_DECISIONS.jsonl | 提升“会分配但不达成”的可追踪性。 | 已完成（新增 delegate/queue/error_code 结构化留痕） | 2026-03-06 |
| main 委派 SOP 命令纠错 | ~/.openclaw/workspace/TOOLS.md;~/.openclaw/workspace/AGENTS.md | 解决 `openclaw session(s) spawn` 在当前 CLI 不存在导致的委派失败。 | 已完成（统一改为 `openclaw agent --agent <id> --message ...` 的可执行命令） | 2026-03-06 |
| 监控任务投递与判定修复 | ~/.openclaw/cron/jobs.json（热修直改+gateway重载） | 解决 `delivery=none` 导致“监控自说自话”，并更新联合判定提示词。 | 部分完成（`delivery.mode` 已切 `announce`，旧停止任务已禁用；但 run history 仍出现 `not-delivered`，需继续排查通道投递链） | 2026-03-06 |
| 监控链路剩余问题留痕 | ~/.openclaw/cron/runs/b8735aa6-0b7d-4613-97bf-c15db61fa9d3.jsonl | 实际运行出现“执行成功但未投递”，需保留风险可追踪证据。 | 已记录（246 次中 245 次 `deliveryStatus=not-delivered`） | 2026-03-06 |
| 通道运行态异常留痕 | `openclaw health --json`;`openclaw channels status --probe` | 解释“监控执行成功但无外部消息”根因。 | 已记录（health 显示 Telegram `running=false/tokenSource=none`，probe 临时可用但未稳定） | 2026-03-06 |
| 模型/鉴权失败证据留痕 | ~/.openclaw/logs/gateway.err.log;~/.openclaw/logs/gateway.log | 解释“任务卡住/超时”根因（非业务逻辑）。 | 已记录（存在 `OAuth token refresh failed`、`No API key found`、`lane wait exceeded`） | 2026-03-06 |
| Agent 初始化未完成留痕 | `openclaw status --json` | 解释“已分配但迟迟不执行”在多团队下的系统性阻塞。 | 已记录（`bootstrapPendingCount=16`，含 main/pangu/luban 等） | 2026-03-06 |

## 28. 多团队自治MVP（可靠性优先）修订留痕（2026-03-06）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 业务产物路径契约落地（3_ClawDocs） | config/brain_trust_config.yaml;scripts/validate_docs_path_policy.sh;scripts/run_brain_trust_review.sh | 解决业务产物仍落仓库 `reviews/`、路径无约束问题。 | 已完成（默认输出改为 `/Volumes/TB512/3_ClawDocs/<team>/review/<yyyymm>/`，非合规路径会拦截） | 2026-03-06 |
| 产物台账机制落地 | scripts/register_artifact_index.sh;scripts/run_brain_trust_review.sh | 解决产物不可检索、不可审计问题。 | 已完成（关键产物自动写入 `artifact_index.jsonl`） | 2026-03-06 |
| 验收职责与产物契约落地 | scripts/run_brain_trust_review.sh;03_Review_Report_Template.md;01_Review_Workflow.md | 明确“有人验收”，避免执行完成语义漂移。 | 已完成（新增 `acceptance_report.json`，`reviewer=braintrust_compliance`） | 2026-03-06 |
| 质量门禁运行态补齐 | scripts/run_brain_trust_review.sh;config/brain_trust_config.yaml | 将 Stage5 从设计稿延伸到运行产物层。 | 已完成（新增 `quality_gate_report.json`，失败标记 `blocked`） | 2026-03-06 |
| 监控/CLI 契约对齐 | 00_DEPLOY_BRAIN_TRUST.md;DEPLOYMENT_RELEASE.md;~/.openclaw/workspace/AGENTS.md;~/.openclaw/workspace/TOOLS.md | 修正 `process list` 不存在导致监控误判。 | 已完成（统一改为 `openclaw sessions --all-agents --active 30 --json`） | 2026-03-06 |
| 知识治理主责分离落地 | ~/.openclaw/workspaces/wenquxing/*;~/.openclaw/workspaces/knowledge_manager/* | 解决“谁维护画像”责任不清。 | 已完成（`wenquxing` 主写入，`knowledge_manager` 审计治理） | 2026-03-06 |
| 验收角色规则实化 | ~/.openclaw/workspaces/braintrust_compliance/* | 解决“审核后谁验收”缺口。 | 已完成（验收SOP与 `acceptance_report` 输出约束已落盘） | 2026-03-06 |
| 发布机制与文档一致性更新 | README.md;DEPLOYMENT_RELEASE.md;config/deployment_release.yaml;DEPLOYMENT_CHANGELOG.md;release/release_manifest.txt;docs/TEAM_STORAGE_POLICY.md | 保证 AI/人类后续按同一口径迭代与发布。 | 已完成（版本升级到 `v1.5.0`，新增存储规范文档与脚本白名单） | 2026-03-06 |

## 29. 文曲星/学者场景补齐与角色覆盖修订留痕（2026-03-06）

| 变更项 | 文件 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 宪章新增学习治理与通知闭环硬约束 | 00_Brain_Trust_Charter.md | 将“文曲星学习计划”从建议升级为可审查契约，明确 `scholar` 唯一学习入口与 `feige_notifier` 通知职责。 | 已完成（新增 5.7 条款，明确角色边界、学习节奏、失败阻断与必备产物） | 2026-03-06 |
| 宪章新增开源学习评分与入库门槛 | 00_Brain_Trust_Charter.md | 防止学习源“只收集不筛选”，统一优秀项目评估标准。 | 已完成（新增 `project_score` 模型与 `>=70` 入库门槛） | 2026-03-06 |
| 工作流新增 Scholar 每日闭环 | 01_Review_Workflow.md | 将学习任务纳入“学习->审查->验收->通知”稳定链路，补足 4:00 通知与回执要求。 | 已完成（新增 Scholar Learning Loop、必备产物与失败恢复规则） | 2026-03-06 |
| 审查入口新增 Scholar 检查项 | 00_START_REVIEW_HERE.md | 让后续方案评审可直接判定学习体系是否合规可落地。 | 已完成（新增 `scholar/feige_notifier/project_score/QMD` 检查项） | 2026-03-06 |
| 发布级契约新增 Scholar 学习条款与 K1-K3 严格测试 | DEPLOYMENT_RELEASE.md | 把学习体系从“运维经验”提升为“发布契约”，便于跨环境复制和验收。 | 已完成（新增 Scholar Learning Contract 与 K1/K2/K3 测试门槛） | 2026-03-06 |
| 元数据新增学习契约字段与验收检查 | config/deployment_release.yaml | 将学习角色、产物、约束机器可读化，支持自动一致性检查。 | 已完成（新增 topology/required_artifacts/constraints 与 rg 验收条目） | 2026-03-06 |
| 本轮边界声明（不施工） | 本章节（留痕） | 避免“运维期方案修订”和“Claw 运行态变更”边界混淆。 | 已完成（本轮仅改仓库设计与测试文档，未改 `~/.openclaw/*`） | 2026-03-06 |

## 30. 文曲星/学者施工落地留痕（2026-03-06）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增实体角色 `scholar` 与 `feige_notifier` | `~/.openclaw/openclaw.json`;`~/.openclaw/workspaces/scholar/*`;`~/.openclaw/workspaces/feige_notifier/*` | 将设计层角色落地为可执行 Agent，消除“有方案无实体”缺口。 | 已完成（`openclaw agents list` 可见两角色，且带身份标识） | 2026-03-06 |
| 学习子团队从模板改为实体 SOP | `~/.openclaw/workspaces/km_collector/*`;`~/.openclaw/workspaces/km_organizer/*`;`~/.openclaw/workspaces/km_indexer/*` | 解决 `km_*` 角色“模板化、无明确职责”问题。 | 已完成（AGENTS/TOOLS 已绑定采集、评分、索引职责与输出） | 2026-03-06 |
| `main` 路由新增 `knowledge_learning -> scholar` | `~/.openclaw/workspace/AGENTS.md`;`~/.openclaw/workspace/SOUL.md`;`~/.openclaw/workspace/TOOLS.md` | 保证学习请求单入口，不再打散直连内部角色。 | 已完成（主路由规则与委派SOP已写入） | 2026-03-06 |
| 学习与通知模型链落地 | `~/.openclaw/openclaw.json`（agent级 model 对象） | 避免全局 defaults 串改导致角色模型漂移。 | 已完成（`scholar`=`zai/glm-5`；`feige_notifier`=`gemini-2.0-flash`；均含3级fallback） | 2026-03-06 |
| 权限最小可用放开（审批仍 ask） | `~/.openclaw/exec-approvals.json` | 保障学习链路可调用 `notebooklm/qmd/openclaw`，但不放开高危自动执行。 | 已完成（`scholar/wenquxing/knowledge_manager/km_*` 与 `feige_notifier` allowlist 已落地） | 2026-03-06 |
| 新增学习定时任务 | OpenClaw cron jobs: `Scholar Daily Learning Review 04:00`;`Scholar Idle Learning 2h` | 将“每日课题+04:00审查后通知+空闲学习”转为系统定时执行。 | 已完成（`openclaw cron list` 可见两任务启用） | 2026-03-06 |
| 仓库部署脚本同步新角色 | `scripts/bootstrap_brain_trust.sh`;`scripts/validate_brain_trust_env.sh`;`config/deployment_release.yaml`;`roles/scholar/*`;`roles/feige_notifier/*` | 保障后续跨Claw复制部署不漏角色、不漏校验。 | 已完成（bootstrap required roles 与 env 校验均已包含新角色） | 2026-03-06 |
| 施工风险记录：并行写配置会互相覆盖 | OpenClaw CLI 施工过程 | 实测并行执行 `agents/models/set-identity` 会发生配置覆盖。 | 已闭环（改为串行写入并复核最终状态） | 2026-03-06 |

## 31. 施工收口与严格测试补充留痕（2026-03-06）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 修复 env 校验对 Agent 存在性的误判 | `scripts/validate_brain_trust_env.sh` | `openclaw agents list` 输出形态变化导致仅靠文本匹配容易误报缺角色。 | 已完成（改为优先 `--json` 解析 `id`，文本模式仅作兜底） | 2026-03-06 |
| 修复回归脚本假环境缺角色 | `scripts/test_run_brain_trust_review_regression.sh` | 新增 `scholar/feige_notifier` 后，fake agents 列表未同步导致回归假失败。 | 已完成（补齐 fake 列表；回归脚本通过） | 2026-03-06 |
| 全量回归复验 | `scripts/test_run_brain_trust_review_regression.sh` | 确认新增角色与校验逻辑修复后不引入回归。 | 已完成（输出 `All regression checks passed.`） | 2026-03-06 |
| 真实 E2E 跑通（外置盘落盘） | `/Volumes/TB512/3_ClawDocs/team-brain-trust/review/202603/*` | 验证“不是只改文档”，施工链路可真实产出。 | 已完成（`run_brain_trust_review.sh --local` 产物齐全，`structured_summary.json` 可解析，`artifact_index.jsonl` 有台账记录） | 2026-03-06 |
| Scholar 无外发 dry-run 冒烟 | `scholar` 运行态 + `/Volumes/TB512/3_ClawDocs/team-brain-trust/*` | 验证学习角色可真实生成学习产物并更新台账。 | 已完成（学习5类产物已落盘；通知链路按 dry-run 跳过） | 2026-03-06 |
| Scholar fallback 链修正 | `~/.openclaw/openclaw.json`（agent `scholar`） | 发现 fallback 漂移为重复项，缺少 Google 后补。 | 已完成（主模型 `zai/glm-5`，fallback: `openai-codex/gpt-5.3-codex -> google-gemini-cli/gemini-3.1-pro-preview -> bailian/qwen3.5-plus`） | 2026-03-06 |

### 31.1 路径策略与台账格式补充（2026-03-06）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| Scholar 存储规则强化为 `custom-learning/<yyyymm>` | `~/.openclaw/workspaces/scholar/AGENTS.md`;`~/.openclaw/workspaces/scholar/TOOLS.md`;`roles/scholar/AGENTS.md`;`roles/scholar/TOOLS.md` | 纠正学习产物散落目录，避免与 3_ClawDocs 路径治理冲突。 | 已完成（复验产物落在 `/Volumes/TB512/3_ClawDocs/team-brain-trust/custom-learning/202603/`） | 2026-03-06 |
| Scholar 台账格式现状记录 | `/Volumes/TB512/3_ClawDocs/team-brain-trust/ops/202603/artifact_index.jsonl` | Scholar dry-run 追加的是 `run_id` 聚合记录，不是标准逐文件字段结构。 | 已记录（当前可追溯但格式不统一，后续需对齐 `register_artifact_index.sh` 标准字段） | 2026-03-06 |

### 31.2 台账标准化收口（2026-03-06）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增历史台账规范化脚本 | `scripts/normalize_artifact_index.sh` | 将历史 `run_id` 聚合行转换为标准逐文件字段，消除格式漂移。 | 已完成（`artifact_index.jsonl` 已迁移并保留 `.bak` 备份） | 2026-03-06 |
| 新增台账格式校验脚本 | `scripts/validate_artifact_index_format.sh` | 建立可执行门禁，防止后续写入非标准结构。 | 已完成（校验通过，字段与路径均合规） | 2026-03-06 |
| 强化注册脚本 artifact 枚举校验 | `scripts/register_artifact_index.sh` | 防止写入 `learning_topic_plan` 等非法 artifact 分类。 | 已完成（仅允许 `review/execution/deploy/release/evidence/ops/custom-*`） | 2026-03-06 |
| Scholar 台账规则升级 | `~/.openclaw/workspaces/scholar/AGENTS.md`;`~/.openclaw/workspaces/scholar/TOOLS.md`;`roles/scholar/AGENTS.md`;`roles/scholar/TOOLS.md` | 让学习产物与台账语义一致，固定使用 `--artifact custom-learning`。 | 已完成（实测新写入为标准字段，无 `run_id` 聚合行） | 2026-03-06 |

## 32. 任务台账生命周期与验收回写落地留痕（2026-03-06）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增统一任务台账脚本 `task_ledger.sh` | scripts/task_ledger.sh | 补齐“任务发布/执行/审核/验收/回流”可追踪状态机，避免仅靠口头完成。 | 已完成（支持 `create/transition/get/list`，强制状态机与回流路径） | 2026-03-06 |
| 新增台账状态机单测 | scripts/tests/test_task_ledger.sh | 防止状态机回归，保证 `acceptance -> in_progress` 回流可执行。 | 已完成（测试输出 `task_ledger tests passed`） | 2026-03-06 |
| 主流程接入台账自动回写 | scripts/run_brain_trust_review.sh | 让 Stage1/3/5 自动写生命周期，不再依赖人工登记。 | 已完成（自动回写 `published/assigned/in_progress/review/acceptance/done`） | 2026-03-06 |
| 验收阻断自动回流落地 | scripts/run_brain_trust_review.sh | 解决“验收 blocked 但任务状态仍显示完成”的假完成问题。 | 已完成（`acceptance_report.status=blocked` 时强制回写 `in_progress` + `reopen_actions`） | 2026-03-06 |
| 新增验收回写联动测试 | scripts/tests/test_acceptance_gate.sh | 验证 pass/blocked 两条路径的台账状态联动正确。 | 已完成（测试输出 `acceptance gate tests passed`） | 2026-03-06 |
| 新增渠道绑定可见性校验脚本 | scripts/check_interface_bindings.sh | 明确 `openclaw agents bindings` 为渠道绑定视图，补齐默认告警与严格阻断（`--strict`）两种验收模式。 | 已完成（默认告警不阻断，严格模式可强制失败） | 2026-03-06 |
| 部署与发布契约同步 | 01_Review_Workflow.md;00_DEPLOY_BRAIN_TRUST.md;DEPLOYMENT_RELEASE.md;config/deployment_release.yaml;release/release_manifest.txt | 将台账脚本与验收测试纳入标准发布与验收链，避免文档-实现脱节。 | 已完成（新增命令与契约检查项） | 2026-03-06 |
| 全量回归复验 | scripts/test_run_brain_trust_review_regression.sh | 确认新增台账回写不破坏既有 Stage1-5 与评分/路由逻辑。 | 已完成（输出 `All regression checks passed.`） | 2026-03-06 |

## 33. 阶段二运行态收敛与安全基线落地留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增运行态日报脚本（05:00） | `scripts/runtime_health_audit.sh` | 需要“人不登录系统也能监督”的固定监督产物，覆盖模型漂移、安全状态、队列失败、团队台账缺口。 | 已完成（每日4类文件落盘到 `/Volumes/TB512/3_ClawDocs/team-brain-trust/ops/202603/`） | 2026-03-07 |
| 新增05:00定时安装器 | `scripts/install_runtime_audit_cron.sh` | 将日报从手工触发改为稳定自动执行。 | 已完成（`crontab -l` 已出现 `BT_RUNTIME_AUDIT` 条目） | 2026-03-07 |
| 新增阶段二收敛脚本 | `scripts/phase2_runtime_convergence.sh` | 一次性执行模型基线校准 + 安全基线收敛 + 网关重启 + 首次审计。 | 已完成（生成 `runtime_convergence_record-20260307-004051.json`） | 2026-03-07 |
| 修复模型收敛语义误差（关键） | `scripts/phase2_runtime_convergence.sh`;`scripts/runtime_health_audit.sh` | OpenClaw 默认模型作用域为全局；早期按角色持久写入会被后写覆盖并造成漂移误报。 | 已完成（改为“全局基线=architect链路 + 角色链路仅记录用于运行时切换”，`model_drift.count=0`） | 2026-03-07 |
| 新增阶段二回归测试 | `scripts/tests/test_runtime_health_audit.sh`;`.github/workflows/brain_trust_verify.yml` | 防止审计脚本结构漂移导致无效日报。 | 已完成（测试通过，CI 已纳入语法+执行检查） | 2026-03-07 |
| 环境与部署契约同步 | `config/brain_trust_config.yaml`;`scripts/validate_brain_trust_env.sh`;`config/deployment_release.yaml`;`release/release_manifest.txt`;`README.md`;`00_DEPLOY_BRAIN_TRUST.md`;`DEPLOYMENT_RELEASE.md`;`DEPLOYMENT_CHANGELOG.md` | 保证“脚本、文档、发布元数据、CI”同一口径，避免后续 AI 发布偏差。 | 已完成（版本升级 `v1.6.0`，文档一致性检查通过） | 2026-03-07 |
| 安全基线收敛结果留痕 | `openclaw security audit --json`（运行态） | 验证 P0 安全目标是否达标。 | 已完成（critical=0，high=0；剩余 warn=1 为 `gateway.trusted_proxies_missing`） | 2026-03-07 |
| 运行态剩余问题留痕 | `runtime_health_report-20260307-050000.json` | 保持“异常可见+可整改”。 | 已记录（队列失败任务=2，cron投递异常=2，团队台账缺口存在） | 2026-03-07 |

## 34. 阶段二遗留问题收口留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 修复队列失败误报口径 | `scripts/runtime_health_audit.sh` | 原逻辑把历史失败长期计入 P0，导致“已恢复系统仍持续告警”。 | 已完成（改为 `failed_total + failed_recent(24h)` 双指标；当前 `failed_recent=0`） | 2026-03-07 |
| 修复 cron 投递异常误判 | `scripts/runtime_health_audit.sh` | 原逻辑把 `delivery=none/not-requested` 与 `not-delivered` 全部算异常，噪声过高。 | 已完成（仅对 `lastRunStatus=error` 或 `deliveryStatus in {failed,error}` 计入 issue；当前 `delivery_issues=[]`） | 2026-03-07 |
| 修复跨团队台账缺失 | `scripts/phase2_runtime_convergence.sh` | 审计报“team-knowledge/team-rd 缺台账”，影响跨团队闭环可见性。 | 已完成（收敛脚本自动初始化 `team-brain-trust/team-knowledge/team-rd` 台账） | 2026-03-07 |
| 修复台账初始化时序 | `scripts/phase2_runtime_convergence.sh` | 台账初始化原在审计之后，导致报告仍显示 `exists=false`。 | 已完成（初始化前置到审计前，报告中三团队 `exists=true`） | 2026-03-07 |
| 收敛监控 cron 执行负载 | OpenClaw cron job `b8735aa6-0b7d-4613-97bf-c15db61fa9d3` | 监控提示词过重导致超时/不稳定。 | 已完成（改轻量心跳提示词+60秒超时+best-effort；最近状态 `lastRunStatus=ok`） | 2026-03-07 |
| 收敛 scholar idle cron 超时 | OpenClaw cron job `a91a1133-afb5-4376-8465-0ac0593fa8f3` | Idle 学习任务过重导致连续 timeout。 | 已完成（改轻量离线课题+90秒超时+flash模型；最近状态 `lastRunStatus=ok`） | 2026-03-07 |
| 回归复验 | `scripts/tests/test_runtime_health_audit.sh`;`scripts/test_run_brain_trust_review_regression.sh` | 防止收口修复引入回归。 | 已完成（两项测试均通过） | 2026-03-07 |


## 35. 阶段二残留项最终清零留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| security warn 清零 | OpenClaw runtime (`gateway.trustedProxies` + gateway reinstall/restart) | `trusted_proxies_missing` 持续告警影响安全基线验收。 | 已完成（`openclaw security audit` 结果：critical=0, warn=0） | 2026-03-07 |
| 监控与学习 cron 超时收敛 | OpenClaw cron jobs `b8735...`,`a91a...` | 监控与 idle 学习任务提示词过重，手动触发易 timeout。 | 已完成（两任务最近状态均 `lastRunStatus=ok`） | 2026-03-07 |
| 审计 backlog 噪声清理 | `scripts/runtime_health_audit.sh` | 历史失败与无投递模式误判导致日报长期虚高。 | 已完成（`delivery_issues=[]`；`failed_recent=0`；`improvement_backlog.p0/p1` 均为空） | 2026-03-07 |
| 阶段二回归复验 | `scripts/tests/test_runtime_health_audit.sh`;`scripts/test_run_brain_trust_review_regression.sh` | 确认收口修复未引入回归。 | 已完成（两项测试均通过） | 2026-03-07 |


## 36. 下一阶段启动：知识团队+研发团队MVP闭环落地留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增MVP闭环执行脚本 | `scripts/run_mvp_team_closure.sh` | 需要把“知识团队+研发团队先跑通闭环”从口头计划变成一键执行。 | 已完成（支持两团队批量生成 lifecycle + acceptance 证据） | 2026-03-07 |
| 新增MVP闭环测试脚本 | `scripts/tests/test_mvp_team_closure.sh` | 防止后续迭代把闭环脚本跑坏。 | 已完成（测试通过） | 2026-03-07 |
| 发布契约纳入MVP闭环 | `config/deployment_release.yaml`;`release/release_manifest.txt`;`.github/workflows/brain_trust_verify.yml` | 保证发布链路与CI对齐，不出现“有脚本但没纳入验收”。 | 已完成（required_scripts/acceptance/CI 已纳入） | 2026-03-07 |
| 部署文档同步下一阶段入口 | `00_DEPLOY_BRAIN_TRUST.md`;`DEPLOYMENT_RELEASE.md`;`README.md`;`DEPLOYMENT_CHANGELOG.md` | 让人类与AI都能按统一入口执行下一阶段。 | 已完成（新增阶段三MVP闭环命令与验收点） | 2026-03-07 |
| 版本推进 | `config/deployment_release.yaml` | 与本轮发布内容一致化。 | 已完成（`release_version` 更新为 `v1.6.1`） | 2026-03-07 |


## 37. 下一阶段继续：Smart3D 团队MVP扩容闭环留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 扩展MVP闭环 owner 映射 | `scripts/run_mvp_team_closure.sh` | 让脚本可覆盖更多团队，避免 `team-smart3d` 误用 `rd_lead`。 | 已完成（新增映射：`team-smart3d -> smart3d_lead`，并支持 proposal/default） | 2026-03-07 |
| 强化MVP测试覆盖 Smart3D | `scripts/tests/test_mvp_team_closure.sh` | 防止团队扩容时 owner/闭环证据回归失效。 | 已完成（新增 `team-smart3d` 测试与 owner 断言） | 2026-03-07 |
| 部署文档新增 Smart3D 扩容入口 | `00_DEPLOY_BRAIN_TRUST.md`;`DEPLOYMENT_RELEASE.md`;`README.md` | 明确“阶段三后继续扩容”可执行命令，减少人工判断。 | 已完成（新增 `team-smart3d` 闭环命令与验证点） | 2026-03-07 |
| 发布元数据与版本推进 | `config/deployment_release.yaml`;`DEPLOYMENT_CHANGELOG.md`;`docs/*.md` | 保持发布文档、元数据、校验脚本一致。 | 已完成（版本升级到 `v1.6.2`，新增 Smart3D 验收命令） | 2026-03-07 |

## 38. 下一阶段继续：跨团队覆盖收敛（Smart3D + Proposal）留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 运行态审计默认团队扩容 | `scripts/runtime_health_audit.sh` | 原默认仅覆盖 `team-knowledge/team-rd`，未覆盖 Smart3D/Proposal，存在监控盲区。 | 已完成（默认团队扩展为 `team-brain-trust,team-knowledge,team-rd,team-smart3d,team-proposal`） | 2026-03-07 |
| 阶段二收敛脚本台账初始化扩容 | `scripts/phase2_runtime_convergence.sh` | 防止审计先报“缺台账”，保证扩容团队纳入同一收敛链。 | 已完成（初始化同上5支团队台账） | 2026-03-07 |
| MVP闭环默认范围扩容 | `scripts/run_mvp_team_closure.sh` | 将 Smart3D 从“手工补跑”升级为默认覆盖，减少漏执行。 | 已完成（默认 teams 改为 `team-knowledge,team-rd,team-smart3d`） | 2026-03-07 |
| Proposal owner 映射与回归覆盖 | `scripts/run_mvp_team_closure.sh`;`scripts/tests/test_mvp_team_closure.sh` | 避免 `team-proposal` 执行 owner 错配。 | 已完成（`team-proposal -> proposal_lead`，测试已断言） | 2026-03-07 |
| 发布文档与元数据同步 | `00_DEPLOY_BRAIN_TRUST.md`;`DEPLOYMENT_RELEASE.md`;`README.md`;`config/deployment_release.yaml`;`DEPLOYMENT_CHANGELOG.md`;`docs/*.md` | 保证“脚本可执行范围”与“文档/发布版本”一致，避免 AI 发布漂移。 | 已完成（版本推进 `v1.6.3`，新增 Proposal 扩容命令） | 2026-03-07 |

## 39. 下一阶段继续：Agent 初始化阻塞收敛补丁留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增 Agent 会话预热脚本 | `scripts/bootstrap_agent_sessions.sh` | 运行态 `bootstrapPendingCount` 长期偏高会导致“任务分配后迟滞执行”。 | 已完成（支持多 agent 轻量预热、strict/non-strict、JSON 报告） | 2026-03-07 |
| 阶段二收敛接入预热步骤 | `scripts/phase2_runtime_convergence.sh` | 将“初始化阻塞收敛”从人工补救变成标准流程。 | 已完成（新增 `--bootstrap-agent-sessions`，默认开启） | 2026-03-07 |
| 日报新增初始化阻塞诊断 | `scripts/runtime_health_audit.sh` | 之前日报没有 `bootstrapPending` 维度，隐性阻塞不可见。 | 已完成（新增 `agent_bootstrap.pending_count/pending_agents`） | 2026-03-07 |
| 新增回归测试覆盖 | `scripts/tests/test_bootstrap_agent_sessions.sh`;`scripts/tests/test_runtime_health_audit.sh` | 防止收敛补丁回归失效。 | 已完成（两项测试通过） | 2026-03-07 |
| CI/发布契约同步 | `.github/workflows/brain_trust_verify.yml`;`release/release_manifest.txt`;`config/deployment_release.yaml`;`DEPLOYMENT_RELEASE.md`;`README.md`;`00_DEPLOY_BRAIN_TRUST.md`;`DEPLOYMENT_CHANGELOG.md`;`docs/*.md` | 保证脚本、文档、验收命令一致，不出现“修了但不验”。 | 已完成（版本推进 `v1.6.4`） | 2026-03-07 |

## 40. 下一阶段继续：Stage5 质量演进产物工程化留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| Stage5 输出新增 QEL 产物 | `scripts/run_brain_trust_review.sh` | 之前仅产出 `quality_gate_report.json`，`quality_improvement_log.jsonl/quality_baseline.yaml` 仍停留在设计层。 | 已完成（每次审查自动追加改进日志，并在缺失时生成基线文件） | 2026-03-07 |
| 产物台账接入 QEL 文件 | `scripts/run_brain_trust_review.sh` | 保证新产物可审计、可检索。 | 已完成（`register_artifact_indexes` 已纳入两个新文件） | 2026-03-07 |
| 回归测试增强 | `scripts/test_run_brain_trust_review_regression.sh` | 防止后续改动导致 Stage5 产物丢失。 | 已完成（正常/失败路径都断言 `quality_improvement_log.jsonl`，正常路径断言 `quality_baseline.yaml`） | 2026-03-07 |
| 配置与发布契约同步 | `config/brain_trust_config.yaml`;`config/deployment_release.yaml`;`DEPLOYMENT_RELEASE.md`;`DEPLOYMENT_CHANGELOG.md`;`README.md`;`docs/*.md` | 保证文档、元数据、验收命令一致。 | 已完成（版本推进 `v1.6.5`） | 2026-03-07 |

## 41. 下一阶段继续：QEL周期汇总工程化留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增质量演进汇总脚本 | `scripts/quality_evolution_compact.sh` | QEL 之前只有单次日志，缺少周期趋势与团队对比视图。 | 已完成（输出 `quality_evolution_report-*.json/.md`） | 2026-03-07 |
| 日报接入质量演进汇总 | `scripts/runtime_health_audit.sh` | 让 05:00 日报自动包含质量趋势，不再需要手工汇总。 | 已完成（新增 `quality_evolution` 段与阈值告警逻辑） | 2026-03-07 |
| 新增质量汇总测试 | `scripts/tests/test_quality_evolution_compact.sh` | 防止脚本回归导致质量趋势缺失。 | 已完成（测试通过） | 2026-03-07 |
| CI/发布契约同步 | `.github/workflows/brain_trust_verify.yml`;`release/release_manifest.txt`;`config/deployment_release.yaml`;`DEPLOYMENT_RELEASE.md`;`DEPLOYMENT_CHANGELOG.md`;`README.md`;`00_DEPLOY_BRAIN_TRUST.md`;`docs/*.md` | 保证新增能力可发布、可验收、可复现。 | 已完成（版本推进 `v1.6.6`） | 2026-03-07 |

## 42. 下一阶段继续：路由学习日报工程化留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 路由学习脚本支持产物导出 | `scripts/route_learning_compact.sh` | 原脚本仅回写 `~/.openclaw`，人类无法在 3_ClawDocs 直观看趋势。 | 已完成（新增 `--report-json/--report-md` 输出能力） | 2026-03-07 |
| 日报接入路由学习报告 | `scripts/runtime_health_audit.sh` | 让 05:00 日报同时覆盖执行健康、质量演进、路由演进。 | 已完成（新增 `route_learning_report-*.json/.md` 与 `runtime_health_report.route_learning` 字段） | 2026-03-07 |
| 新增路由学习回归测试 | `scripts/tests/test_route_learning_compact.sh` | 防止后续修改导致路由趋势报告失效。 | 已完成（测试通过） | 2026-03-07 |
| CI/发布契约同步 | `.github/workflows/brain_trust_verify.yml`;`release/release_manifest.txt`;`config/deployment_release.yaml`;`DEPLOYMENT_RELEASE.md`;`DEPLOYMENT_CHANGELOG.md`;`README.md`;`00_DEPLOY_BRAIN_TRUST.md`;`docs/*.md` | 保证“新增能力=新增验收”，防止发布链路遗漏。 | 已完成（版本推进 `v1.6.7`） | 2026-03-07 |

## 43. 下一阶段继续：运行态 backlog 自动回写任务台账留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增运行态 backlog 同步脚本 | `scripts/sync_runtime_backlog_tasks.sh` | 每日审计已产出 P0/P1 待改进项，但未自动进入任务生命周期，导致整改追踪断层。 | 已完成（支持读取 `runtime_health_report` 并去重写入 `task_ledger.jsonl`） | 2026-03-07 |
| 日报接入 backlog 自动回写 | `scripts/runtime_health_audit.sh` | 将“发现问题”与“任务化整改”打通，避免仅停留在报告层。 | 已完成（新增 `backlog_sync_report-*.json` 与 `runtime_health_report.backlog_sync`） | 2026-03-07 |
| 新增 backlog 同步单测 | `scripts/tests/test_sync_runtime_backlog_tasks.sh` | 防止去重/写入逻辑回归，保障重复运行幂等。 | 已完成（首轮创建2条、二次运行全跳过） | 2026-03-07 |
| 运行态审计测试补齐新契约 | `scripts/tests/test_runtime_health_audit.sh` | 确保日报生成时 backlog 同步状态和产物都可验证。 | 已完成（断言 `backlog_sync.status=generated`） | 2026-03-07 |
| CI/发布契约与文档同步 | `.github/workflows/brain_trust_verify.yml`;`release/release_manifest.txt`;`config/deployment_release.yaml`;`DEPLOYMENT_RELEASE.md`;`README.md`;`00_DEPLOY_BRAIN_TRUST.md`;`DEPLOYMENT_CHANGELOG.md` | 保证“新增能力=新增验收=新增发布说明”，避免脚本能力漂移。 | 已完成（版本推进 `v1.6.8`） | 2026-03-07 |

## 44. 下一阶段继续：任务台账SLA审计闭环留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 新增任务台账SLA审计脚本 | `scripts/audit_task_ledger_sla.sh` | 现有日报仅看台账存在性，无法识别“任务长期卡住”风险。 | 已完成（支持跨团队台账审计、超时阈值识别、缺台账识别） | 2026-03-07 |
| 日报接入台账SLA审计结果 | `scripts/runtime_health_audit.sh` | 将“监督任务是否真正推进”纳入每日固定输出与改进清单。 | 已完成（新增 `task_ledger_audit_report-*.json` 与 `runtime_health_report.task_ledger_audit`） | 2026-03-07 |
| 新增台账审计回归测试 | `scripts/tests/test_audit_task_ledger_sla.sh` | 防止阈值逻辑/缺台账识别/字段结构回归。 | 已完成（测试通过） | 2026-03-07 |
| 审计主流程测试补齐新契约 | `scripts/tests/test_runtime_health_audit.sh` | 确保每日审计产物和结构字段完整。 | 已完成（断言 `task_ledger_audit.status=generated`） | 2026-03-07 |
| CI/发布契约与文档同步 | `.github/workflows/brain_trust_verify.yml`;`release/release_manifest.txt`;`config/deployment_release.yaml`;`README.md`;`00_DEPLOY_BRAIN_TRUST.md`;`DEPLOYMENT_RELEASE.md`;`DEPLOYMENT_CHANGELOG.md` | 保证新增能力可发布、可验收、可复现。 | 已完成（版本推进 `v1.6.9`） | 2026-03-07 |

## 45. 下一阶段继续：运行态管理层单页摘要落地留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 日报新增管理层单页摘要 | `scripts/runtime_health_audit.sh` | 现有日报信息分散，人类不登录系统时难以一眼判断健康状态与行动项。 | 已完成（新增 `runtime_executive_summary-*.md`，包含健康级别、关键指标、行动清单） | 2026-03-07 |
| 审计测试覆盖摘要产物 | `scripts/tests/test_runtime_health_audit.sh` | 防止摘要产物或结构化章节在后续迭代中丢失。 | 已完成（断言产物存在且含 `Overall health/Key Metrics/Lifecycle Audits/Action List`） | 2026-03-07 |
| 发布契约与文档同步 | `README.md`;`00_DEPLOY_BRAIN_TRUST.md`;`DEPLOYMENT_RELEASE.md`;`config/deployment_release.yaml`;`DEPLOYMENT_CHANGELOG.md` | 保证新增产物对外可感知、可验收、可复现。 | 已完成（版本推进 `v1.6.10`） | 2026-03-07 |

## 46. 下一阶段继续：运行态趋势对比日报落地留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 日报新增趋势对比产物 | `scripts/runtime_health_audit.sh` | 现有日报是静态快照，缺少“相比昨日变好/变坏”视角，难以做连续治理。 | 已完成（新增 `runtime_trend_report-*.json/.md`，自动对比上一份日报） | 2026-03-07 |
| 运行态报告新增 trend 字段 | `scripts/runtime_health_audit.sh` | 让下游脚本和人类都能消费统一趋势状态。 | 已完成（新增 `runtime_health_report.trend.status` 与 delta 元信息） | 2026-03-07 |
| 管理层摘要接入趋势结论 | `scripts/runtime_health_audit.sh` | 让“单页摘要”直接体现趋势，不用手工交叉比对多份报告。 | 已完成（新增 `Runtime trend` 行） | 2026-03-07 |
| 回归测试补齐趋势产物与结构断言 | `scripts/tests/test_runtime_health_audit.sh` | 防止趋势功能回归丢失。 | 已完成（断言 trend 状态和趋势报告文件） | 2026-03-07 |
| 文档/发布契约同步 | `README.md`;`00_DEPLOY_BRAIN_TRUST.md`;`DEPLOYMENT_RELEASE.md`;`config/deployment_release.yaml`;`DEPLOYMENT_CHANGELOG.md` | 保证新产物可见、可验收、可发布。 | 已完成（版本推进 `v1.6.11`） | 2026-03-07 |

## 47. 巡检后修复收口留痕（2026-03-07）

| 变更项 | 文件/对象 | 原因 | 验证结果 | 时间 |
| --- | --- | --- | --- | --- |
| 公开发布校验流程纠偏 | `README.md`;`DEPLOYMENT_RELEASE.md`;`docs/AI_RELEASE_PROTOCOL.md`;`docs/HUMAN_RELEASE_RUNBOOK.md`;`docs/RELEASE_OVERVIEW.md`;`scripts/check_release_docs_consistency.sh` | 巡检发现把 `--enforce-manifest` 误写成 main 也可执行，实际会在开发分支产生误报。 | 已完成（文档明确 main 只跑非严格校验，strict 只在 release） | 2026-03-07 |
| 公共发布校验误报收敛 | `scripts/verify_public_release.sh`;`scripts/tests/test_verify_public_release.sh` | 巡检发现凭证正则对命令替换/变量展开误报，影响可用性。 | 已完成（逐文件扫描 + 收窄字面量凭证匹配；单测通过） | 2026-03-07 |
| 验收门禁收紧 | `scripts/run_brain_trust_review.sh`;`scripts/test_run_brain_trust_review_regression.sh` | 巡检发现意图偏差和编辑层 P0 条件未必阻断最终验收，存在“假通过”风险。 | 已完成（新增 misalignment/P0 条件/建议重审三类阻断；回归通过） | 2026-03-07 |
| QMD 同步健康纳入日报 | `scripts/runtime_health_audit.sh`;`scripts/tests/test_runtime_health_audit.sh` | 巡检发现知识链路可能退化，但日报未显式暴露。 | 已完成（新增 `qmd_sync` 字段，退化时写入 P1） | 2026-03-07 |
| CI/发布契约补齐新测试 | `.github/workflows/brain_trust_verify.yml`;`.github/workflows/public_release_verify.yml`;`release/release_manifest.txt`;`config/deployment_release.yaml` | 防止本轮修复只停留在本地，后续发布回归。 | 已完成（版本推进 `v1.6.12`） | 2026-03-07 |
