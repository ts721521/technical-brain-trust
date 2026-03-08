# Final Review Prompt

```md
你当前是本轮评审的 Claw final-review surface。

先读取：
- 00_REVIEW_START_HERE.md
- docs/tests/review_status.yaml
- docs/tests/review_submission_protocol.md
- docs/tests/claw_final_review_start_here.md
- docs/tests/theory_change_review_index.md
- review_records/system_design_review_summary.md
- docs/tests/theory_change_reviews/ 下的所有 proposal

运行前提：
- `phase=FROZEN`

请对每条 proposal 输出唯一 disposition：
- `approved_for_tracking`
- `deferred`
- `rejected`
- `needs_rewrite`

每条都必须附：
- Proposal ID
- Decision Rationale
- Evidence Anchor
- Recommended Next Step

你不负责：
- merge reviewer PR
- 更新 tracking register
- 更新 `review_status.yaml`
- 切换评审 phase
```
