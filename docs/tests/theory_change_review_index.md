# Claw 系统理论修改建议总索引

> 当前文件只负责：候选建议入口、互评完成度、最终优先级汇总。  
> 当前评审是否开放、冻结或关闭，以 [review_status.yaml](./review_status.yaml) 为唯一准则。  
> 所有 AI 必须先读 [../../00_REVIEW_START_HERE.md](../../00_REVIEW_START_HERE.md) 再写入本文件。

> 这是“系统理论修改建议”评审入口文件。  
> 人类优先看这一个文件，即可知道：
> 1. 每个 AI 的建议文件在哪里
> 2. 每个建议由谁评过、被评成 `P0/P1/P2` 的情况
> 3. 最终哪些建议值得进入正式理论修订讨论

---

## 1. 目标

本轮不是评代码实现，而是评 **Claw 组织系统理论本身是否需要修改、补充或收紧**。

所有参与 AI 需要完成两类动作：

1. 在自己的建议文件中提出理论修改建议 (基于你对 00_Brain_Trust_Charter.md 以及实践中遇到的如“限流”、“越权”等痛点的理解)。
2. 阅读其他 AI 的建议文件，并对每个建议给出 `P0/P1/P2` 评级，最终汇总。

> **🤖 AI 裁判员引导话术 (Prompt for AI Reviewers)**：
> "作为 Claw 系统的专家智囊团，你的任务并不是仅仅给个分数。你必须**批判性地**审视其他同僚提出的《理论修改建议》。你需要研判：他们的提议是否会破坏现有宪章的‘业务真相’红线？是否具有物理落地性（如对付真实世界的网络限流、模型幻觉、人类长官强压）？请在目标文件的 `Peer Review Ratings` 表格中留下你严厉且专业的评级 (P0: 致命必须改; P1: 强烈建议改; P2: 锦上添花) 及一句话理由。"

---

## 2. 阅读顺序

建议按以下顺序阅读：

1. [../../00_REVIEW_START_HERE.md](../../00_REVIEW_START_HERE.md)
2. [../../00_Brain_Trust_Charter.md](../../00_Brain_Trust_Charter.md)
3. [review_status.yaml](./review_status.yaml)
4. [peer_review_matrix.md](./peer_review_matrix.md)
5. 本文件
6. 各 AI 的理论建议文件
7. 回到本文件最下方查看“最终汇总表”

---

## 3. 评级规则

`P0`
- 必须优先讨论或修订
- 当前理论若不改，会持续导致误解、假完成或系统性风险

`P1`
- 有明确价值，建议纳入下一轮理论修订
- 不改不会立刻失控，但会持续增加执行偏差或评审成本

`P2`
- 可保留观察
- 更像优化、措辞增强或表达层改良，不是当前主风险

**硬性要求 (Rules of Engagement)**

1. **必须参评**：每个 AI 必须给其他所有 AI 的建议做评级，不能只提交自己的一次性建议就跑路。
2. **拒绝敷衍**：评级必须附上专业且犀利的一行理由（例如："P0: 物理断网确实会导致上层兜底失效，必须外置探针"），不能只写 `P0/P1/P2` 或“同意”。
3. **面向人类输出**：人类最终看结论时，只看本文件下方的“最终汇总表”。因此，所有评审结束后，必须有一名主理 AI 负责将各份文件中的分散结论提炼汇总到此文件底部的表格中。
4. **格式规范**：务必直接使用 markdown 表格格式向他人的 `Peer Review Ratings` 注入结果，不要破坏原文件结构。
5. **证据锚点**：每条评级都必须引用至少一个证据锚点，例如文档章节、脚本路径、角色文件或 `review_commit` 下的可核对事实。

---

## 4. 候选建议文件

| AI | 建议文件 | 状态 |
|---|---|---|
| Codex | [proposal_codex.md](./theory_change_reviews/proposal_codex.md) | 待填写 |
| GLM-5 | [proposal_glm_5.md](./theory_change_reviews/proposal_glm_5.md) | 待填写 |
| Kimi K2.5 | [proposal_kimi_k2_5.md](./theory_change_reviews/proposal_kimi_k2_5.md) | 已提交 |
| Qwen-3.5-Plus | [proposal_qwen_3_5_plus.md](./theory_change_reviews/proposal_qwen_3_5_plus.md) | 待填写 |
| Auto (Cursor) | [proposal_auto_cursor.md](./theory_change_reviews/proposal_auto_cursor.md) | 已提交 |
| MiniMax-M2.5 | [proposal_minimax_m2_5.md](./theory_change_reviews/proposal_minimax_m2_5.md) | 待填写 |
| Antigravity | [proposal_antigravity.md](./theory_change_reviews/proposal_antigravity.md) | 已提交 |

---

## 5. 快速总览矩阵

> 用来快速看“谁已经评了谁”。  
> 具体理由写在各自 proposal 文件中，这里只放最终优先级结果。  
> 只有在 `phase=OPEN` 时允许普通 AI 更新；`phase=FROZEN` 后仅 `summary_owner` 可继续维护。

| Reviewer \ Proposal | Codex | GLM-5 | Kimi K2.5 | Qwen-3.5-Plus | Auto (Cursor) | MiniMax-M2.5 | Antigravity |
|---|---|---|---|---|---|---|---|
| Codex | self |  |  |  |  |  |  |
| GLM-5 |  | self |  |  |  |  |  |
| Kimi K2.5 |  |  | self |  |  |  | TC-ANTI-01:P1, TC-ANTI-02:P0, TC-ANTI-03:P0, TC-ANTI-04:P1, TC-ANTI-05:P0 |
| Qwen-3.5-Plus |  |  |  | self |  |  |  |
| Auto (Cursor) |  |  | TC-KIMI-01:P1, TC-KIMI-02:P1, TC-KIMI-03:P2 |  | self |  | TC-ANTI-01:P1, TC-ANTI-02:P0, TC-ANTI-03:P0, TC-ANTI-04:P1, TC-ANTI-05:P0 |
| MiniMax-M2.5 |  |  |  |  |  | self |  |
| Antigravity |  |  |  |  |  |  | self |

---

## 6. 最终汇总表

> 人类最终看这里。  
> 当所有 proposal 文件和互评完成后，把建议逐条聚合到这个表里。

| 建议ID | 建议标题 | 提出AI | 被评为P0 | 被评为P1 | 被评为P2 | 当前结论 | 备注 |
|---|---|---|---:|---:|---:|---|---|
| TC-CODEX-01 |  | Codex | 0 | 0 | 0 | 待汇总 |  |
| TC-GLM-01 |  | GLM-5 | 0 | 0 | 0 | 待汇总 |  |
| TC-KIMI-01 | 能力契约增加模型能力边界声明 | Kimi K2.5 | 0 | 0 | 0 | 待汇总 |  |
| TC-QWEN-01 |  | Qwen-3.5-Plus | 0 | 0 | 0 | 待汇总 |  |
| TC-AUTO-01 | 明确 business_request_satisfied 的判定权与复核权 | Auto (Cursor) | 0 | 0 | 0 | 待汇总 |  |
| TC-MINIMAX-01 |  | MiniMax-M2.5 | 0 | 0 | 0 | 待汇总 |  |
| TC-ANTI-01 | 增加流程免审与快速通道 | Antigravity | 0 | 1 | 0 | 待汇总 | Kimi K2.5 评级 P1 |
| TC-ANTI-02 | 引入执行期探针 (Runtime Watchdog) | Antigravity | 1 | 0 | 0 | 待汇总 | Kimi K2.5 评级 P0 |
| TC-ANTI-03 | 增加越权免责留痕簿规则 | Antigravity | 1 | 0 | 0 | 待汇总 | Kimi K2.5 评级 P0 |
| TC-ANTI-04 | 学习闭环的"冷却区"隔离 | Antigravity | 0 | 1 | 0 | 待汇总 | Kimi K2.5 评级 P1 |
| TC-ANTI-05 | 基础设施熔断与动态路由 | Antigravity | 1 | 0 | 0 | 待汇总 | Kimi K2.5 评级 P0 |

---

## 7. 维护约束

1. 每个 AI 只修改自己的建议文件，不修改别人的建议正文。
2. 对别人的评价，写在对方建议文件的 `Peer Review Ratings` 区块中。
3. 本索引文件只做入口、总览矩阵和最终汇总，不承载长篇正文。
4. 如果某个 AI 提出多条建议，继续在最终汇总表中追加 `TC-<AI>-02`、`TC-<AI>-03`。
5. 当 [review_status.yaml](./review_status.yaml) 为 `CLOSED` 时，本文件视为只读。

---

## 8. 建议作者填写顺序

1. 先在自己的 proposal 文件里填“建议摘要”和“理论修改条目”
2. 再去读其他 6 份 proposal 文件
3. 在其他文件中填自己的 `P0/P1/P2` 评级和一行理由
4. 最后回到本文件，更新“快速总览矩阵”和“最终汇总表”
