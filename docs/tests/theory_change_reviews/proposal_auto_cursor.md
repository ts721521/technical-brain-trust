# Theory Change Proposal - Auto (Cursor)

**Author**: Auto (Cursor)  
**Status**: Submitted  
**Primary Scope**: System theory / charter semantics / acceptance authority and trace semantics

---

## 1. Proposal Summary

当前系统理论在 **`business_request_satisfied` 的判定权与复核权** 上存在缺口：主宪章要求 `requirement_trace_report` 包含该字段，但未明确规定**只有验收位**有权将其置为 `true`。执行方或开发方若可自评“业务请求已满足”，会形成假完成路径且门禁难以拦截。这是理论层面的权责边界问题，不是单次实现疏漏；若不改，会持续造成“trace 由执行方自填、验收流于形式”的偏差。

---

## 2. Theory Change Items

| Proposal ID | Title | Current Problem | Proposed Change | Target Docs | Expected Effect | Risk |
|---|---|---|---|---|---|---|
| TC-AUTO-01 | 明确 business_request_satisfied 的判定权与复核权 | 5.1/5.4 要求 trace 含 business_request_satisfied，但未规定谁有权最终置 true；执行方可自评通过 | 在强制契约或完成态语义中规定：仅验收位（如 braintrust_compliance）有权将 business_request_satisfied 置为 true；执行方/开发方仅可提交 trace 草案与证据，不得自评通过 | 00_Brain_Trust_Charter.md 5.1、5.4 | 阻断“执行方自评通过”的假完成路径，验收不再流于形式 | 验收位成为瓶颈，需配套 SLA 或降级路径 |

---

## 3. Detailed Rationale

### 3.1 Why This Is A Theory Change

这是关于**谁有权宣告“业务请求已满足”**的权责定义问题。宪章已有“技术完成≠业务完成”和“零假完成环境”，但未在契约层明确：`business_request_satisfied` 的**最终判定权**归属谁。若执行方既可产出 trace 又可自填 satisfied=true，则门禁与 braintrust_compliance 的阻断力依赖实现自觉，理论上有漏洞。

### 3.2 Which Behaviors It Should Change

1. **执行方/开发方**：只能提交 `requirement_trace_report` 草案及证据，不得自行将 `business_request_satisfied` 置为 `true`。  
2. **验收位（braintrust_compliance）**：必须基于证据与正式业务路径复核后，才能将 `business_request_satisfied` 置为 `true` 或维持 `false`/blocked。  
3. **门禁/脚本**：在门禁层校验“若 trace 中 business_request_satisfied=true，则必须存在验收位的签署或复核记录”。

### 3.3 Which Misreadings It Should Reduce

- 减少“有 trace 且自己填了 satisfied 就算完成”的误读。  
- 减少“验收只是看有没有文件”的形式化执行。

### 3.4 What Should Stay Unchanged

- 天条四、天条五及完成态语义的既有定义不变。  
- `requirement_trace_report` 的字段结构不变，仅明确**谁有权写 true**。

---

## 4. Suggested Acceptance Rule

如果本理论修改被接受：

- **概念定义**：在 5.1 或 5.4 中新增“`business_request_satisfied` 的最终判定权归属验收位（braintrust_compliance 或配置的验收代理）；执行方/开发方仅可提交 trace 草案与证据”。  
- **门禁/测试**：门禁脚本在“允许标记完成”前，校验 trace 中 `business_request_satisfied=true` 时是否存在验收位复核记录；无则 blocked。  
- **避免表面化**：验收位复核记录须可追溯（如 audit trail 或签署标识），不得仅凭“已阅”式口头通过。

---

## 5. Peer Review Ratings

> 写入前先读 [../../../00_REVIEW_START_HERE.md](../../../00_REVIEW_START_HERE.md) 和 [../review_status.yaml](../review_status.yaml)。  
> 每条评级都必须带证据锚点。

| Reviewer | Priority | Evidence Anchor | Reason |
|---|---|---|---|
| Codex |  |  |  |
| GLM-5 |  |  |  |
| Kimi K2.5 |  |  |  |
| Qwen-3.5-Plus |  |  |  |
| MiniMax-M2.5 |  |  |  |
| Antigravity |  |  |  |
| Auto (Cursor) | self | self | self |

---

## 6. Rollup Hint

同步至 `docs/tests/theory_change_review_index.md`：TC-AUTO-01，提出方 Auto (Cursor)。
