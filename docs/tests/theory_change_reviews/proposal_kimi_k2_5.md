# Theory Change Proposal - Kimi K2.5

**Author**: Kimi K2.5  
**Status**: Submitted  
**Primary Scope**: System theory / charter semantics / capability contract precision

---

## 1. Proposal Summary

当前系统理论在**能力契约的精确性**和**跨模型执行的确定性**方面存在理论缺口。具体表现为：`capability_contract` 缺乏对"模型能力边界"的显式声明，导致在模型替换或降级时，系统无法准确判断某条业务链是否仍然可行。如果不修改，会持续造成"契约在但执行失败"的假完成风险，尤其在模型限流、降级或切换时产生系统性误判。

---

## 2. Theory Change Items

| Proposal ID | Title | Current Problem | Proposed Change | Target Docs | Expected Effect | Risk |
|---|---|---|---|---|---|---|
| TC-KIMI-01 | 能力契约增加模型能力边界声明 | `capability_contract` 只声明业务边界，未声明所需模型能力等级（如推理深度、上下文长度、工具调用能力） | 在 `capability_contract` 中新增 `model_requirements` 字段，显式声明所需能力等级和可降级方案 | 00_Brain_Trust_Charter.md 5.2 节 | 防止模型切换时业务链断裂，确保降级时有明确预案 | 可能增加契约维护复杂度 |
| TC-KIMI-02 | 增加执行期模型能力探测机制 | 系统无法在运行时检测当前模型是否满足契约要求的能力边界 | 在 `pangu` 执行前增加 `capability_probe` 阶段，验证当前模型是否满足 `model_requirements` | 00_Brain_Train_Charter.md 5.2 节 | 提前发现能力不匹配，避免执行到一半失败 | 探测本身可能增加延迟 |
| TC-KIMI-03 | 明确 `blocked` 状态的降级路径 | 当前 `blocked` 只有状态，缺乏标准降级处理流程，导致系统容易僵死 | 在 `capability_contract` 中增加 `degraded_paths[]`，明确每种 blocked 原因对应的降级方案 | 00_Brain_Trust_Charter.md 5.4 节 | 减少系统僵死，提高可用性 | 降级方案本身可能引入风险 |

---

## 3. Detailed Rationale

### 3.1 Why This Is A Theory Change

这不是简单的代码实现问题，而是关于**系统如何理解自身能力边界**的根本认知问题。当前主宪章定义了 `capability_contract`，但它假设：
- 所有 Agent 的能力是同质的
- 模型替换不会影响业务链可行性
- `blocked` 只能等待人工解除

这些假设在真实生产环境中不成立。不同模型（GPT-4 vs GPT-3.5 vs Claude vs Kimi）在推理深度、上下文长度、工具调用能力上存在本质差异。如果不显式声明这些边界，系统会在模型降级时产生"契约在但执行失败"的系统性风险。

### 3.2 Which Behaviors It Should Change

1. **契约编写行为**：编写 `capability_contract` 时必须同时考虑业务边界和模型能力边界
2. **执行前行为**：`pangu` 执行前必须验证模型能力是否满足契约要求
3. **阻断处理行为**：`blocked` 不再是终点，而是触发降级路径的起点
4. **模型切换行为**：模型切换时必须重新验证所有活跃契约的能力要求

### 3.3 Which Misreadings It Should Reduce

- 减少"契约存在 = 一定能执行"的误解
- 减少"blocked = 等待人工"的教条主义
- 减少"模型切换是透明操作"的错误认知
- 减少"所有 AI 能力相同"的隐含假设

### 3.4 What Should Stay Unchanged

- "天条四（不能绕过业务真相源）"和"天条五（技术不等于业务）"核心准绳不变
- `capability_contract` 的核心结构不变，只是增加字段
- `blocked` 作为阻断状态的本质不变，只是增加处理路径
- 人类最终拍板权不变

---

## 4. Suggested Acceptance Rule

如果本理论修改被接受：

**概念定义变更：**
- `capability_contract` 必须包含 `model_requirements` 字段
- `model_requirements` 必须包含：`min_reasoning_level`、`min_context_length`、`required_capabilities[]`、`degraded_model_options[]`

**门禁/测试变更：**
- 新增 `capability_probe` 门禁，在 `pangu` 执行前自动运行
- 新增测试用例：验证模型降级时系统是否正确触发 `degraded_paths`
- 新增验收标准：`blocked` 状态必须在 5 分钟内触发降级路径或人工通知

**避免表面化执行：**
- `model_requirements` 必须由 `braintrust` 审核，不能由执行 Agent 自行填写
- `degraded_paths` 必须提前定义，不能在 `blocked` 时临时编造
- 定期（每月）审计 `capability_contract` 的 `model_requirements` 是否与实际模型能力匹配

---

## 5. Peer Review Ratings

> 写入前先读 [../../../00_REVIEW_START_HERE.md](../../../00_REVIEW_START_HERE.md) 和 [../review_status.yaml](../review_status.yaml)。  
> 每条评级都必须带证据锚点。

| Reviewer | Priority | Evidence Anchor | Reason |
|---|---|---|---|
| Codex |  |  |  |
| GLM-5 |  |  |  |
| Qwen-3.5-Plus |  |  |  |
| Auto (Cursor) | TC-KIMI-01: P1; TC-KIMI-02: P1; TC-KIMI-03: P2 | 00_Brain_Trust_Charter.md 5.2 能力契约、5.4 完成态语义 | TC-KIMI-01: P1—capability_contract 增加 model_requirements 有明确价值，模型切换/降级时契约可判定可行性；TC-KIMI-02: P1—capability_probe 与 Antigravity 的 runtime 探针互补，执行前探测可减少执行到一半失败；TC-KIMI-03: P2—blocked 降级路径有价值但属僵死缓解的优化，优先级略低于假完成与责任边界。 |
| MiniMax-M2.5 |  |  |  |
| Antigravity |  |  |  |

---

## 6. Rollup Hint

同步至 `docs/tests/theory_change_review_index.md`。
