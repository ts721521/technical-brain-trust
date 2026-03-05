# 📊 综合审查报告模板 (Review Report Template)

> **用途**：主 Agent 收集三角色审查意见后，按此模板合成综合报告。
> **评分口径**：`final_score` 由脚本自动计算，人工复核可选。

---

## 报告头

| 字段 | 内容 |
|---|---|
| **方案名称** | [方案名] |
| **审查轮次** | [第 N 轮] |
| **审查深度** | [quick / standard / deep] |
| **审查时间** | [ISO-8601] |
| **执行状态** | [正常执行 / 降级执行] |
| **综合评分** | [加权平均分 / 10] |

---

## 综合评分

| 维度 | 架构师 | 批判者 | 创新者 | 平均 |
|---|:---:|:---:|:---:|:---:|
| 可行性 | /10 | /10 | /10 | /10 |
| 健壮性 | /10 | /10 | — | /10 |
| 可扩展性 | /10 | — | /10 | /10 |
| 简洁性 | /10 | — | /10 | /10 |
| 创新性 | — | — | /10 | /10 |
| 风险度 | — | /10 | — | /10 |
| **加权总分** | | | | **/10** |

### 非加权共识检查项（强制）

| 维度 | 架构师 | 批判者 | 创新者 | 共识结论 |
|---|:---:|:---:|:---:|---|
| 目标清晰度(0-5) | /5 | /5 | /5 | [结论] |
| 收益与可验证性(0-5) | /5 | /5 | /5 | [结论] |
| 可运营/可观测性(0-5) | /5 | /5 | /5 | [结论] |
| 总体建议语义 | 建议采纳/优化后采纳/重审 | 同左 | 同左 | [总编整合结论] |

### 评分计算规则（固定）

```text
risk_normalized = 11 - raw_risk_score
final_score = feasibility*0.25 + robustness*0.20 + scalability*0.15
            + simplicity*0.15 + innovation*0.10 + risk_normalized*0.15
```

### 降级重归一化规则（固定）

当某维度因角色缺失而不可计算时：
1. 仅使用可计算维度参与加权。
2. 将可计算维度权重按比例重归一化，确保权重和为 1.0。
3. 输出 `score_summary.missing_dimensions` 与 `score_summary.used_weights` 供审计。

### 评分异常处理规则（固定）

1. 若某角色分数为非数值：忽略该值，不参与均值，并记录到 `score_summary.anomalies`。
2. 若分数越界（<1 或 >10）：自动钳制到 [1,10]，并记录原值与归一化值到 `score_summary.anomalies`。
3. `risk_raw` 按同样规则处理后再计算 `risk_normalized = 11 - risk_raw`。

---

## 共识项（三角色一致认同）

1. [共识 1]
2. [共识 2]

---

## 分歧项（三角色有不同看法）

| 议题 | 架构师看法 | 批判者看法 | 创新者看法 |
|---|---|---|---|
| [议题 1] | ... | ... | ... |

---

## 交叉复核摘要（Stage 2）

| 角色 | 同意点(+) | 不同意点(-)与理由 | 补充遗漏项 |
|---|---|---|---|
| 架构师 | ... | ... | ... |
| 批判者 | ... | ... | ... |
| 创新者 | ... | ... | ... |

---

## 意图纠偏汇总（天条三）

| 角色 | 是否发现偏差 | 证据 | 纠偏建议 |
|---|---|---|---|
| 架构师 | [是/否] | ... | ... |
| 批判者 | [是/否] | ... | ... |
| 创新者 | [是/否] | ... | ... |

---

## 开源推荐验证证据（天条四）

> 仅当报告中出现开源推荐时必填。

| 项目 | Stars | 最近活跃天数 | Open Issues | License | 证据链接 |
|---|---:|---:|---:|---|---|
| [项目名] | [数字] | [数字] | [数字] | [许可证] | [URL] |

---

## 复杂度削减结论（天条六）

- **来源字段**：优先使用三角色结构化摘要中的 `complexity_reduction`，缺失时才使用关键词回退提取。
- **可削减项**：
1. ...
2. ...
- **无需削减说明（如无可削减项）**：...

---

## 关键发现

### 架构层面
1. [发现]

### 风险/漏洞
1. [发现]

### 优化机会
1. [发现]

---

## 优化建议清单（按优先级）

| 优先级 | 建议 | 来源 | 预期改进 |
|:---:|---|---|---|
| P0 | [建议] | [角色名] | [效果] |
| P1 | [建议] | [角色名] | [效果] |
| P2 | [建议] | [角色名] | [效果] |

---

## P0 条件清单（总编整合，<=5）

1. [必须完成项：问题 -> 影响 -> 建议 -> 验证方式]

## P1 改进清单（总编整合，<=8）

1. [重要改进项：问题 -> 影响 -> 建议 -> 验证方式]

## 行动项表（可执行）

| 事项 | 负责人 | 截止时间 | 验收口径 |
|---|---|---|---|
| [事项] | [人类/方案作者/评审者] | [YYYY-MM-DD] | [可验证标准] |

## 未决问题（需补充数据/实验）

1. [问题 + 需要的数据或实验]

---

## 替代方案（如有）

### 替代方案 1：[方案名]
- **描述**：...
- **优势**：...
- **劣势**：...
- **创新者决策矩阵得分**：/10

---

## 结论与建议

**总体评价**：[优秀 / 良好 / 需改进 / 需重大修改]

**建议动作（仅建议语义）**：
- [ ] 原方案可执行，建议采纳 P0/P1 优化项
- [ ] 建议采用替代方案 [编号]
- [ ] 建议重大修改后再次审查
- [ ] 其他建议：[说明]

> 注意：智囊团和总编整合角色均不做最终裁决；最终拍板在人类。

---

## 结构化综合摘要（机读）

```json
{
  "execution_status": "normal|degraded",
  "final_score": 0.0,
  "final_recommendation": "建议采纳|建议优化后采纳|建议重审",
  "orchestration": {
    "stage1_status": "normal|degraded",
    "stage1_mode": "serial",
    "stage2_status": "complete|degraded|insufficient",
    "stage3_status": "complete|degraded|insufficient",
    "stage2_completed_roles": [],
    "stage2_failed_roles": [],
    "stage2_skipped_roles": [],
    "stage3_editor": "script_editor|agent_editor"
  },
  "score_summary": {
    "status": "complete|degraded|insufficient",
    "dimension_values": {
      "feasibility": 0.0,
      "robustness": 0.0,
      "scalability": 0.0,
      "simplicity": 0.0,
      "innovation": 0.0,
      "risk": 0.0,
      "risk_raw": 0.0
    },
    "used_weights": {
      "feasibility": 0.25
    },
    "missing_dimensions": [],
    "anomalies": [
      {
        "role": "critic",
        "dimension": "risk_raw",
        "raw": 11.2,
        "normalized": 10.0,
        "reason": "out_of_range_clamped"
      }
    ]
  },
  "intent_alignment_summary": {
    "misalignment_found": false,
    "notes": []
  },
  "complexity_reduction_summary": {
    "reduction_required": false,
    "items": [],
    "source_breakdown": {
      "structured_field_roles": 0,
      "fallback_extracted_roles": 0
    }
  },
  "opensource_validation": [],
  "parse_diagnostics": {
    "parsed_roles": [],
    "failed_roles": [],
    "errors": []
  },
  "cross_review_summary": {
    "architect": [],
    "critic": [],
    "innovator": []
  },
  "model_routing_summary": {
    "architect": {
      "attempts": [],
      "models_tried": [],
      "final_success_model": "",
      "switch_reasons": []
    },
    "critic": {
      "attempts": [],
      "models_tried": [],
      "final_success_model": "",
      "switch_reasons": []
    },
    "innovator": {
      "attempts": [],
      "models_tried": [],
      "final_success_model": "",
      "switch_reasons": []
    }
  },
  "editor_summary": {
    "p0_conditions": [],
    "p1_items": [],
    "unresolved_questions": []
  },
  "input_guard": {
    "original_chars": 0,
    "effective_chars": 0,
    "truncated": false,
    "max_tokens_per_role": 16000,
    "estimated_tokens_per_role": 1200,
    "token_budget_mode": "advisory",
    "token_budget_exceeded": false
  }
}
```

---

## 各角色原始审查意见

### 架构师审查
[嵌入或链接原始意见]

### 批判者审查
[嵌入或链接原始意见]

### 创新者审查
[嵌入或链接原始意见]

---

*End of Review Report*
