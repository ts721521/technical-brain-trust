# System Theory Change Tracking Register

This register records only proposals that have already passed:

1. AI peer review
2. human collection
3. braintrust final approval

If a proposal is not listed here, it is not yet a formal tracked change.

---

| Proposal ID | Title | Source Author | Peer Review Outcome | Braintrust Final Disposition | Target Docs / Systems | Owner | Tracking Status | Evidence / Decision Links | Notes |
|---|---|---|---|---|---|---|---|---|---|
| TC-ANTI-0x | 抗压与实防基础设施升级系列提案 | Antigravity | 已汇总 | approved_for_tracking | OpenClaw 配置装配图 | pending | in_progress | review_records/system_design_review_summary.md | 已有历史批准记录 |

---

## Status Semantics

- `planned`: 已被批准进入追踪，但尚未开始落地
- `in_progress`: 已进入正式修改跟踪
- `implemented`: 已完成修改
- `verified`: 已完成验证
- `closed`: 已正式关闭

---

## Recording Rule

For every accepted change, append one row immediately after braintrust final approval.
