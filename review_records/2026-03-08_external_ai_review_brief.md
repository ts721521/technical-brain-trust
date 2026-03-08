# External AI Review Brief

## 对外发送说明

这份文稿是发给其他 AI 的统一评审引导，不需要对方做任何“版本选择”。

直接把下面的“对外邀请正文”发给其他 AI 即可。

---

## 对外邀请正文

```md
请参与当前仓库的系统设计评审。

你要评审的不是某个零散脚本，也不是单个提示词，而是一套面向真实业务交付的 AI 组织治理系统。

这个系统试图解决的问题包括：
- AI 把技术跑通误当成业务完成
- AI 绕过业务真相源或正式业务路径
- AI 在信息不足时脑补、越权或假完成
- AI 只做一次性交付，不沉淀长期能力
- 多个 AI 协作时缺少统一门禁、状态语义和责任边界

本轮希望你评审的是：
1. 这套系统设计是否自洽
2. 是否真的能阻断假完成、越权和绕过业务真相源
3. 角色、门禁、契约和学习闭环是否足够清晰
4. 在真实高压场景下是否会失效、僵化或产生新的系统性风险
5. 是否存在值得优先修订的理论或治理缺口

请基于以下固定评审对象进行评审：
- review_branch: `codex/system-design-review-20260308`
- review_commit: `d7032fcc5cf1f14cd19ddc112a8b4d4b16c3f7e0`

唯一入口：
https://github.com/ts721521/technical-brain-trust/blob/codex/system-design-review-20260308/00_REVIEW_START_HERE.md

评审要求：
- 先读取 `00_REVIEW_START_HERE.md`
- 再读取 `docs/tests/review_status.yaml`
- 再读取 `docs/tests/review_submission_protocol.md`
- 再读取 `docs/tests/cursor_reviewer_start_here.md`
- 先从 `review_branch` 读取入口文件，再以指定 `review_commit` 作为最终评审快照
- 不基于 `main` 或其他漂移状态评审
- 只在白名单路径内写入
- 每条评审意见尽量附证据锚点
- 若 `phase=CLOSED`，请停止修改并切换为只读

提交要求：
- 评审完成后，请使用你自己的 reviewer branch 提交
- 通过 PR 合并到 `codex/system-design-review-20260308`
- PR 需要带 `ai-review-submission` 和 `ready-for-maintainer`
- 不要直接 push 到 `codex/system-design-review-20260308`
- peer review 结束后，结论还会进入 braintrust 终审
- 只有被 braintrust 批准的建议，才会进入正式变更追踪表

请以公平、严格、可举证的方式评审当前系统设计，而不是做泛泛点评。
```

---

## GitHub 入口信息

- Repository: [technical-brain-trust](https://github.com/ts721521/technical-brain-trust)
- Review Branch: `codex/system-design-review-20260308`
- Review Commit: `d7032fcc5cf1f14cd19ddc112a8b4d4b16c3f7e0`
- Entry File: [00_REVIEW_START_HERE.md](https://github.com/ts721521/technical-brain-trust/blob/codex/system-design-review-20260308/00_REVIEW_START_HERE.md)
- Reviewer Start: [cursor_reviewer_start_here.md](https://github.com/ts721521/technical-brain-trust/blob/codex/system-design-review-20260308/docs/tests/cursor_reviewer_start_here.md)
- Submission Protocol: [review_submission_protocol.md](https://github.com/ts721521/technical-brain-trust/blob/codex/system-design-review-20260308/docs/tests/review_submission_protocol.md)
- Tracking Register: [system_theory_change_tracking_register.md](https://github.com/ts721521/technical-brain-trust/blob/codex/system-design-review-20260308/review_records/system_theory_change_tracking_register.md)

---

## 使用提醒

1. 对外时，优先只发送“对外邀请正文”。
2. 不要把内部推送策略、收口策略、操作说明一起发给其他 AI。
3. 在 branch 未推送到 GitHub 之前，不要对外发送入口链接。
