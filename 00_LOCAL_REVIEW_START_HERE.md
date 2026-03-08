# Local Review Start Here

## 当前用途

如果你参与的是当前系统设计评审，但你**不能访问 GitHub**，请从本文件开始。

本文件是 `00_REVIEW_START_HERE.md` 的本地工作区版本。

它适用于：

- 只能读取本地仓库文件的模型
- 不能打开 GitHub 链接的模型
- 通过共享工作区或本地副本参与评审的模型

---

## 你在评什么

你要评审的不是某个零散脚本，也不是单个提示词，而是一套面向真实业务交付的 AI 组织治理系统。

重点评审：

1. 系统设计是否自洽
2. 是否能阻断假完成、越权和绕过业务真相源
3. 角色、门禁、契约和学习闭环是否清晰
4. 是否存在高压场景下的失效点
5. 是否存在值得优先修订的理论或治理缺口

---

## 本地评审对象

- `review_branch`: `codex/system-design-review-20260308`
- `review_commit`: `d7032fcc5cf1f14cd19ddc112a8b4d4b16c3f7e0`

如果你无法访问 GitHub，请以当前本地工作区中这些文件为准。

---

## 必读文件

1. [00_REVIEW_START_HERE.md](./00_REVIEW_START_HERE.md)
2. [docs/tests/review_status.yaml](./docs/tests/review_status.yaml)
3. [docs/tests/review_submission_protocol.md](./docs/tests/review_submission_protocol.md)
4. [docs/tests/cursor_reviewer_start_here.md](./docs/tests/cursor_reviewer_start_here.md)
5. [docs/tests/theory_change_review_index.md](./docs/tests/theory_change_review_index.md)
6. [docs/tests/peer_review_matrix.md](./docs/tests/peer_review_matrix.md)
7. [review_records/system_design_review_summary.md](./review_records/system_design_review_summary.md)

---

## 输出要求

如果你能直接写本地仓库：

- 只改白名单评审文件
- 保持与 `review_status.yaml` 一致
- 保持证据锚点

如果你不能直接写文件：

- 输出结构化评审内容
- 标明 proposal id / priority / evidence anchor / reason
- 由外部操作位代为写入或提 PR

---

## 注意

如果你**能用 GitHub**，仍然优先使用 [00_REVIEW_START_HERE.md](./00_REVIEW_START_HERE.md)。

本文件只是给无法访问 GitHub 的模型留的本地入口。
