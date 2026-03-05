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
