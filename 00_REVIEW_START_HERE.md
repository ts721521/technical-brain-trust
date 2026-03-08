# Review Start Here

## 当前用途

如果你进入本仓库的目的是参与 **当前系统设计评审**，请不要直接从 `00_NEXT_AI_START_HERE.md` 开始执行或改文件。

本轮评审的唯一入口是本文件。

---

## 系统是什么

本仓库不是单一脚本仓库，也不是普通 Prompt 集合。

它描述的是一个以主宪章为核心的组织化 AI 系统，用来约束多个 AI 在真实业务中协作时的行为边界、验收语义和学习闭环。

这个系统重点解决的问题包括：

- AI 把技术跑通误当成业务完成
- AI 绕过业务真相源或正式业务路径
- AI 在信息不足时脑补、越权或假完成
- AI 只做一次性交付，不沉淀长期能力
- 多个 AI 协作时缺少统一门禁、状态语义和责任边界

你应把它理解为一个“面向真实业务交付的 AI 组织治理系统”，而不是单次任务提示词。

---

## 本轮评审的目的

本轮评审不是让你代替系统执行业务，而是请你评审：

1. 这套系统设计是否自洽
2. 它是否真的能阻断假完成、越权和绕过业务真相源
3. 它的角色、门禁、契约和学习闭环是否足够清晰
4. 它在真实高压场景下是否会失效、僵化或产生新的系统性风险
5. 是否存在值得优先修订的理论或治理缺口

请尽量以“公平、严格、可举证”的方式评审，不要把它当成普通文风评价任务。

---

## 你应该重点看什么

重点不是仓库里某一段实现代码，而是以下系统设计能力：

- 是否定义了明确的业务真相源与正式业务路径
- 是否稳定区分 `technical_chain_validated` 和 `business_request_satisfied`
- 是否在认知不足时优先补认知，而不是直接开发
- 是否定义了角色边界、状态语义、阻断机制和验收对象
- 是否要求能力沉淀、错误复盘和规则晋升，而不是只追求当轮完成
- 是否存在容易导致教条化、过度摩擦、执行瘫痪或责任漂移的设计缺口

如果你提出批评或修改建议，必须尽量引用可核对证据，而不是只给抽象态度。

---

## 当前评审状态

先读取：

1. [docs/tests/review_status.yaml](./docs/tests/review_status.yaml)
2. [docs/tests/theory_change_review_index.md](./docs/tests/theory_change_review_index.md)
3. [docs/tests/peer_review_matrix.md](./docs/tests/peer_review_matrix.md)

`docs/tests/review_status.yaml` 是唯一阶段锁：

- `OPEN`：允许按白名单路径写入评审文件
- `FROZEN`：普通 AI 停止写入，仅 `summary_owner` 可做汇总
- `CLOSED`：所有 AI 只读，不再允许修改评审文件

如果你看到 `phase=CLOSED`，你的行为应立即切换为 **只读**。

---

## Canonical Review Target

本轮评审对象固定为：

- `review_branch`: `codex/system-design-review-20260308`
- `review_commit`: `d7032fcc5cf1f14cd19ddc112a8b4d4b16c3f7e0`
- `review_topic`: `system_design_review`
- `review_owner`: `human`

禁止基于本地脏工作区、未声明分支、或 `main` 漂移状态给评审结论。

`review_branch` 承载评审流程文件；`review_commit` 是被评审系统快照。  

如果你通过 GitHub 进入，请先从 `review_branch` 读取入口文件，再以 `review_commit` 为最终评审对象。  
如果你通过本地仓库进入，也必须以 `review_status.yaml` 中记录的 branch/commit 为准。

---

## 必读顺序

1. [00_Brain_Trust_Charter.md](./00_Brain_Trust_Charter.md)
2. [00_NEXT_AI_START_HERE.md](./00_NEXT_AI_START_HERE.md)
3. [docs/tests/review_status.yaml](./docs/tests/review_status.yaml)
4. [docs/tests/theory_change_review_index.md](./docs/tests/theory_change_review_index.md)
5. [docs/tests/peer_review_matrix.md](./docs/tests/peer_review_matrix.md)
6. [review_records/system_design_review_summary.md](./review_records/system_design_review_summary.md)

---

## 可写与不可写

只有在 `phase=OPEN` 时，才允许写入以下路径：

- `docs/tests/theory_change_reviews/`
- `docs/tests/theory_change_review_index.md`
- `docs/tests/peer_review_matrix.md`
- `review_records/system_design_review_summary.md`

以下文件在任何阶段都不应由普通评审 AI 改写：

- `00_Brain_Trust_Charter.md`
- `00_NEXT_AI_START_HERE.md`
- `docs/tests/review_status.yaml`
- 任何不在白名单中的脚本、角色、发布文件

---

## 评审输出要求

1. 每个 AI 只写自己的建议正文。
2. 每个 AI 必须给其他 AI 的建议写 `P0/P1/P2 + 一句话理由`。
3. 每条评审意见必须带 **证据锚点**：
   - 文档章节
   - 脚本路径
   - 角色文件
   - 或 `review_commit` 下的可核对事实
4. 不接受纯态度型评论，例如“同意”“感觉不错”“值得考虑”。

---

## 关闭规则

只有人类有权把评审从 `OPEN/FROZEN` 改到 `CLOSED`。

关闭后：

- 所有 AI 只读
- 不再改 `proposal_*.md`
- 不再改 `peer_review_matrix.md`
- 不再改 `theory_change_review_index.md`
- 人类只看 [review_records/system_design_review_summary.md](./review_records/system_design_review_summary.md)

---

## 总结文件

人类最终只看：

- [review_records/system_design_review_summary.md](./review_records/system_design_review_summary.md)

如果你是普通评审 AI，不要在这个文件里写长篇自由发挥；只按入口与白名单完成结构化评审。
