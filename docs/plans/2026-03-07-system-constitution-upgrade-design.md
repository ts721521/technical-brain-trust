# 2026-03-07 系统主宪章升级设计说明

## 目标

将 `00_Brain_Trust_Charter.md` 升级为整个 Claw 组织系统的唯一顶层真相源，并把同一套语义贯彻到：

- 运行态 Agent 规则
- 项目门禁
- 巡检与学习闭环
- 发布与部署文档

本次升级的目标不是“再补几条规则”，而是把系统从“工具集合”推进到“组织化代理系统”。

## 背景问题

旧系统已经能拦住一部分明显技术失败，但仍允许一类更深层的错误：

1. 团队完成了表面动作；
2. 生成了文件；
3. 通过了狭义技术门禁；
4. 却仍然违背了用户真实意图和正式业务路径。

这说明旧系统虽然有智囊团原则，但还没有真正的“主宪章层”：

- 智囊团有规则；
- 但规则没有治理所有团队、门禁、验收和学习闭环；
- 团队仍然可能围绕局部目标做局部最优。

## 理论框架

本系统顶层设计采用四层组合：

### 1. VSM（Viable System Model）

用于定义：

- 系统为什么是一个可生存组织，而不是一堆工具；
- 团队如何递归组织；
- 局部自治如何服从全局治理。

### 2. BDI（Belief / Desire / Intention）

用于定义单个 Agent 的行为基础：

- `Identity`：我是谁
- `Beliefs`：我知道什么、不知道什么
- `Desires`：我要达成什么
- `Intentions`：我承诺按什么路径推进

这让 Agent 不再只按提示词反射，而是按“身份 + 认知 + 目标 + 承诺”工作。

### 3. Learning Organization + Double-Loop Learning

用于定义学习闭环：

- 不只修一次动作错误；
- 还要修导致错误的规则、假设、成功定义。

也就是：

- `single-loop`：修执行
- `double-loop`：修规则、修模板、修门禁、修默认思维

### 4. Shared Mental Models

用于定义团队为什么必须“先建立共同认知，再分工行动”。

如果团队成员对同一系统的正式业务链、前置条件、成功标准理解不一致，
那团队只是表面分工，实际上仍然是在各自猜测。

## 为什么“人设”不够

仅靠角色设定，只能回答：

- 我是谁
- 我负责什么

但不能稳定回答：

- 我为什么这样做
- 什么不能绕过
- 什么才算真正完成
- 做错后怎么不再重复犯

所以系统必须同时定义两层：

### 个体层

- 身份
- 职责
- 世界观
- 认知义务
- 学习义务

### 环境层

- 没有认知包不得进入开发/验收
- 没有能力沉淀不得完成
- 技术链完成不等于业务完成
- 同类错误必须进入规则候选和巡检

只有“人格 + 世界观 + 环境反馈”同时存在，Agent 的自主性才会稳定地服务正确目标。

## 工程映射

### 1. Agent 身份

关键 Agent 都必须显式写清：

- `Identity`
- `Duty`
- `Worldview`
- `Beliefs`
- `Boundaries`
- `Learning`

其中：

- `Identity/Duty` 定义“我是谁、我负责什么”
- `Worldview/Beliefs` 定义“我怎么理解任务和系统”
- `Boundaries/Learning` 定义“我不能怎么做、我如何从错误中变强”

### 2. 任务认知

系统型任务必须先产出：

- `system_cognition_packet`
- `requirement_packet`
- `requirement_trace_report`

它们共同回答：

- 这个系统真正做什么
- 正式业务主链是什么
- 哪些前置条件不能绕过
- 当前任务真正要什么
- 这次结果是否真的满足原始需求

### 3. 门禁

项目门禁负责把世界观落成“行为轨道”：

- 缺 `system_cognition_packet` 不得继续
- 缺 `capability_delta` 不得完成
- trio 跑通只能算 `technical_chain_validated`
- 只有 `business_request_satisfied=true` 才允许真实完成
- `requirement_mismatch` / `business_truth_not_used` / `artifact_inconsistency` 直接 blocked

### 4. 学习闭环

学习闭环不再只是汇总，而要驱动规则晋升：

- `error_review`
- `capability_gap`
- `rule_promotion_candidate`

这些对象默认只进入学习库，不自动改系统。只有经过：

- `rd_lead`
- `braintrust`
- 必要时 `braintrust_compliance`

审核通过后，才允许晋升为长期规则、门禁、模板或测试项。

### 5. 验收语义

验收位不再验“文件存在没”，而是验：

- 是否满足原始需求
- 是否保留业务真相源
- 是否走正式业务路径
- 结构化结果、最终报告、用户可见产物是否一致
- 是否带来了长期能力沉淀

## 本轮影响范围

### 主文档

- `00_Brain_Trust_Charter.md`

### 门禁与巡检

- `scripts/project_delivery_gate.sh`
- `scripts/constitution_deviation_scan.sh`
- `scripts/runtime_health_audit.sh`
- `scripts/tests/test_project_delivery_gate.sh`
- `scripts/tests/test_qsplus_delivery_gate.sh`
- `scripts/tests/test_constitution_deviation_scan.sh`

### 关键运行态 Agent

- `~/.openclaw/workspace/AGENTS.md`
- `~/.openclaw/workspace/TOOLS.md`
- `~/.openclaw/workspaces/rd_lead/*`
- `~/.openclaw/workspaces/developer/*`
- `~/.openclaw/workspaces/rd_developer/*`
- `~/.openclaw/workspaces/tester/*`
- `~/.openclaw/workspaces/braintrust/*`
- `~/.openclaw/workspaces/braintrust_compliance/*`
- `~/.openclaw/workspaces/rd_manager/*`
- `~/.openclaw/workspaces/pangu/*`
- `~/.openclaw/workspaces/luban/*`
- `~/.openclaw/workspaces/scholar/*`

### 发布与部署文档

- `README.md`
- `DEPLOYMENT_RELEASE.md`
- `00_DEPLOY_BRAIN_TRUST.md`
- `config/deployment_release.yaml`
- `DEPLOYMENT_CHANGELOG.md`

## 验证要求

1. 主宪章必须成为唯一总真相源，不得再出现第二份并列总基本法。
2. 关键 Agent 文件必须显式体现：
   - 身份
   - 职责
   - 世界观
   - 认知义务
   - 边界
   - 学习职责
3. 门禁和巡检必须能真正识别：
   - 缺认知包
   - 缺能力沉淀
   - 假完成
   - 绕过业务真相源
4. 这轮通过后，才允许回到 `QSPLUS` 做正式业务路径回归。

## 延后事项

这次升级并不等于已经修完 `QSPLUS` 正式业务路径问题。

`QSPLUS` 仍然是后续验证对象，而不是本轮主目标。
本轮完成后，下一阶段才进入：

- `system_cognition_packet-QSPLUS`
- 正式业务链与联调链分离
- 接口边界纠偏
- 真实业务回归验证
