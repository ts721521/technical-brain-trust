# 📋 审查工作流 (Review Workflow)

> **用途**：定义主 Agent 如何将方案发送给智囊团审查，并通过“先独立、后对齐、再整合、再执行”的编排机制稳定产出闭环结果。

---

## 触发方式

### 方式 1：人类直接触发
```
人类："审查这个方案" 或 "让智囊团看看这个"
  → 主 Agent 收集方案内容
  → 填写 02_Proposal_Submission_Template.md
  → 启动五段式闭环
```

### 方式 2：Agent 主动提交
```
任何 Agent 填写 02_Proposal_Submission_Template.md
  → 提交到智囊团审查
```

---

## 角色与分工（不重叠）

- `Architect`：可行性、关键路径、复杂度与扩展性。
- `Critic`：技术风险、失败模式、可观测性/灰度/回滚建议（建议语义，不做裁决）。
- `Innovator`：替代方案、简化路径、收益与代价权衡。
- `Editor`（总编整合角色）：默认由主 Agent 担任，也可由人类指定。

> `Editor` 只做合并、消重、冲突解释，不做通过/拒绝裁决；最终拍板永远是人类。

---

## 统一评审量表（所有角色共用）

### A. 加权评分维度（进入 final_score）

| 维度 | 评分角色 | 说明 |
|---|---|---|
| 可行性 | 三角色 | 能否按描述落地 |
| 健壮性 | 架构师 + 批判者 | 故障/降级/恢复能力 |
| 可扩展性 | 架构师 + 创新者 | 增长与演进能力 |
| 简洁性 | 架构师 + 创新者 | 复杂度是否可控 |
| 创新性 | 创新者 | 替代方案价值 |
| 风险度(反向) | 批判者 | 失败概率 × 影响 |

### B. 非加权共识检查项（强制输出）

- 目标清晰度（0-5）
- 收益与可验证性（0-5）
- 可运营/可观测性（0-5）
- 总体建议语义：`建议采纳 / 建议优化后采纳 / 建议重审`

---

## 五段式编排

### Stage 1：独立评审（防互相带偏）

```
串行发送同一方案 + 同一量表给三角色（architect -> critic -> innovator）
  → 角色独立输出，不看其他角色结果
```

每角色必须输出：
1. 评分（加权维度 + 非加权检查项）
2. `Top 3 P0`（必须改）
3. `Top 3 P1`（重要改）
4. `至少 1 个替代方案`
5. 每条意见采用固定结构：`问题 -> 影响 -> 建议 -> 验证方式`

### Stage 2：交叉复核（只做对齐）

```
将三份独立评审互相分发
  → 每角色只做：同意(+)、不同意(-)、补充遗漏
```

每角色在本阶段只允许输出：
- `+` 我同意的点（可附证据）
- `-` 我不同意的点（必须给理由）
- `补充` 对方漏掉的关键风险/指标

### Stage 3：总编整合（可合并交付）

`Editor` 合并三方意见，产出一份最终报告：
1. 共识项（去重）
2. 分歧项（含裁剪理由）
3. P0 条件清单（<=5 条）
4. P1 改进清单（<=8 条）
5. 行动项表（事项/负责人/截止时间/验收口径）
6. 未决问题（需要补充数据/实验）

### Stage 4：盘古执行（默认自动触发）

```
将 Stage 3 产物提交给 pangu
  → pangu 自主判断执行范围（必须说明范围与理由）
  → 输出执行计划 + 执行结果 + 结构化执行摘要
```

Stage 4 产物：
- `pangu_execution_plan.md`
- `pangu_execution_report.md`
- `pangu_execution_raw.json`
- `pangu_execution_raw.json.stderr`（失败留痕）

### Stage 5：质量门禁与改进回写（QSGP + QEL）

```
在 Stage 4 产物基础上执行质量自把关与持续改进回写
  → 产出 quality_gate_report.json（本次交付质量门禁）
  → 更新 quality_improvement_log.jsonl（周期改进台账）
  → 更新 quality_baseline.yaml（质量基线）
```

Stage 5 强制规则：
1. 任一质量关失败，交付状态必须为 `blocked`。
2. 交付必须包含验证证据与回滚计划。
3. 周期改进必须含量化指标变化，不允许空转。

---

## 主 Agent 操作指南

### Step 1: 准备方案材料
```
收集以下内容：
  ✅ 方案名称和目标
  ✅ 方案详细描述（或文件路径）
  ✅ 期望审查深度（quick / standard / deep）
  ✅ 特别关注点（如有）
```

### Step 2: 执行五段式流程
```
Stage 1：三角色串行独立评审
Stage 2：三角色交叉复核
Stage 3：Editor 总编整合输出
Stage 4：盘古执行（默认自动）
Stage 5：质量门禁与改进回写
```

### Step 3: 返回给提案方
```
将综合报告返回给提案方/人类
  → 人类决定是否采纳建议
  → 如果修改了方案，可再次提交审查
```

---

## 失败降级规则（无外部转介）

### 角色失败处理
```
若 pangu 超时或失败：
  1) 按 config.runtime.execution 重试
  2) 超过上限后默认标记为 degraded（on_failure=degraded_continue）
  3) 输出 retryable_items，供人类或后续重试
若单角色超时或失败：
  1) 按 config.runtime.retry 重试
  2) 达到重试上限后，按 config.runtime.degradation 执行降级
```

### Stage 4 失败处理（无外部转介）

```
若 pangu 超时或失败：
  1) 按 config.runtime.execution 重试
  2) 超过上限后默认标记为 degraded（on_failure=degraded_continue）
  3) 输出 retryable_items，供人类或后续重试
```

### Stage 5 失败处理（质量门禁）

```
若质量门禁任一关失败：
  1) 强制标记交付为 blocked
  2) 记录 blocked_reasons 并回写 quality_gate_report.json
  3) 不得标记“完成”，必须进入修复或回滚流程
```

### 最低可交付门槛
```
当完成角色数 >= config.runtime.degradation.min_roles_required：
  → 继续生成综合报告
  → 在报告头标记："降级执行"

当完成角色数 < min_roles_required：
  → 本轮审查标记为失败
  → 返回"资料不足，需重试"，不输出伪完整结论
```

---

## 审查深度速查

| 深度 | 架构师用 | 批判者用 | 创新者用 |
|---|---|---|---|
| `quick` | ATAM | Pre-mortem | 第一性原理 |
| `standard` | ATAM + C4 | Pre-mortem + 红队 + FMEA | 第一性原理 + 决策矩阵 |
| `deep` | ATAM + C4 + 选型 | Pre-mortem + 红队 + FMEA + 苏格拉底 | 第一性原理 + 决策矩阵 + TRIZ + 类比 |

---

## 分发 Prompt 骨架（Stage 1）

```markdown
## 审查请求

**方案名称**：[方案名]
**审查深度**：[quick / standard / deep]
**特别关注**：[重点关注的方面，如有]

### 方案内容
[方案描述或文件内容]

### 你的任务
请按你的 SKILL.md 方法论进行独立评审，不参考其他角色意见。
必须输出：
- 评分（加权维度 + 非加权检查项）
- Top 3 P0 / Top 3 P1
- 至少 1 个替代方案
- 每条意见采用“问题 -> 影响 -> 建议 -> 验证方式”
- 结构化 JSON 摘要（含 intent_alignment；推荐开源时含证据）
```

## 交叉复核 Prompt 骨架（Stage 2）

```markdown
你将看到其他角色的独立评审结果。
请只输出：
1) 同意的点（+）
2) 不同意的点（-，附理由）
3) 补充遗漏项（关键风险/指标）

不要重新写整份审查，不新增裁决语义。
```

## 总编整合 Prompt 骨架（Stage 3）

```markdown
你是总编整合角色（Editor），负责合并三方评审与交叉复核。
任务：
1) 消重合并，标注共识/分歧
2) 形成 P0 条件清单（<=5）与 P1 清单（<=8）
3) 输出行动项（事项/负责人/截止时间/验收口径）
4) 给出最终建议语义：建议采纳 / 建议优化后采纳 / 建议重审

注意：你不做最终裁决，最终拍板在人类。
```

## 盘古执行 Prompt 骨架（Stage 4）

```markdown
你是执行者 pangu。基于 Stage 3 的 `editor_review.md`、`summary_report.md`、`structured_summary.json` 执行落地。
必须输出：
1) 执行计划（范围与理由）
2) 执行结果（已完成项、延后项、可重试项）
3) 结构化 JSON：
{
  "trigger_mode": "auto",
  "scope_mode": "autonomous",
  "implemented_items": [],
  "deferred_items": [],
  "retryable_items": [],
  "failure_reason": ""
}
不要输出裁决语义，最终拍板在人类。
```
