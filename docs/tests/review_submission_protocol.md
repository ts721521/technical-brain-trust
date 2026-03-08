# Review Submission Protocol

## Purpose

This file defines how each reviewer should move completed review work into GitHub, and how the human owner closes the review loop.

It exists to prevent three failure modes:

1. Multiple reviewers pushing directly to the same branch and overwriting each other
2. Reviews being written but never merged into the canonical review branch
3. Review collection ending without a clear freeze and close step
4. AI peer review ending without a final braintrust approval step
5. Accepted changes never entering a formal tracking register

---

## Canonical Roles

- `review_branch`: `codex/system-design-review-20260308`
- `review_commit`: `d7032fcc5cf1f14cd19ddc112a8b4d4b16c3f7e0`
- `review_owner`: `human`
- `summary_owner`: `codex`

Role meanings:

- `review_owner` decides when review opens, freezes, closes, and what gets merged
- each reviewer submits only their own review changes
- `summary_owner` maintains the final rollup after review collection is frozen

---

## Allowed Write Scope

Reviewers may only change these paths while `phase=OPEN`:

- `docs/tests/theory_change_reviews/`
- `docs/tests/theory_change_review_index.md`
- `docs/tests/peer_review_matrix.md`
- `review_records/system_design_review_summary.md`

Reviewers must not modify:

- `00_Brain_Trust_Charter.md`
- `00_NEXT_AI_START_HERE.md`
- `00_REVIEW_START_HERE.md`
- `docs/tests/review_status.yaml`
- scripts, roles, release files, or any non-whitelisted path

---

## Reviewer GitHub Flow

Each reviewer should use a dedicated submission branch derived from `review_branch`.

Recommended branch naming:

- `codex/review-<reviewer>-20260308`

Examples:

- `codex/review-glm5-20260308`
- `codex/review-kimi-20260308`
- `codex/review-qwen-20260308`

Required steps:

1. Checkout from `codex/system-design-review-20260308`
2. Create a reviewer-specific branch
3. Make only whitelisted review edits
4. Commit with a reviewer-specific message
5. Push the reviewer branch to GitHub
6. Open a PR targeting `codex/system-design-review-20260308`

Reviewers should not push directly to `codex/system-design-review-20260308`.

---

## Minimal Reviewer Checklist

Before submission, each reviewer should confirm:

1. I reviewed the system based on `review_commit`
2. I only changed whitelisted review files
3. I added evidence anchors where possible
4. I did not change review stage control files
5. My PR target is `codex/system-design-review-20260308`

---

## Peer Review Completion Rule

AI review is not considered complete merely because proposals exist.

For each proposal, peer review is considered complete only when:

1. the proposal body is filled
2. the proposal has reviewer ratings from every other active reviewer
3. each rating includes:
   - `Priority`
   - `Evidence Anchor`
   - `Reason`
4. the rollup in `docs/tests/theory_change_review_index.md` has been updated

If one or more reviewers are unavailable, `review_owner` may explicitly waive missing reviewers.
That waiver should be recorded in:

- `review_records/system_design_review_summary.md`

Until then, the proposal remains peer-review-incomplete.

---

## PR Title Convention

Recommended PR title:

- `review: <reviewer> system design assessment`

Examples:

- `review: glm5 system design assessment`
- `review: kimi system design assessment`

Recommended commit message:

- `review: <reviewer> submit system design assessment`

---

## Human Merge Flow

The human owner or designated maintainer should:

1. Review each reviewer PR
2. Reject changes that modify non-whitelisted files
3. Merge accepted reviewer PRs into `codex/system-design-review-20260308`
4. Keep `phase=OPEN` while still collecting reviewer input

This is the collection phase.

---

## Mutual Review Semantics

Each reviewer is expected to judge whether another AI's proposal is:

- theoretically sound
- consistent with the charter's red lines
- operationally enforceable
- likely to reduce real system risk
- likely to create new friction or loopholes

This means reviewers are not only scoring "is it interesting", but also:

1. is the proposal internally coherent
2. does it conflict with business truth source rules
3. does it weaken gate semantics or accountability
4. does it create implementation ambiguity
5. does it deserve escalation into formal change tracking

---

## Freeze Phase

When reviewer collection is complete, `review_owner` changes:

- `phase: OPEN` -> `phase: FROZEN`

At this point:

- normal reviewers stop editing
- no more reviewer PRs should be opened
- `summary_owner` consolidates accepted review results
- only files listed in `post_freeze_write_paths` should continue to change

Only summary work should continue.

---

## Braintrust Final Approval

After peer review is complete and the review is frozen, the next step is not immediate adoption.

The human owner should submit the consolidated review package to braintrust for final judgment.

Minimum braintrust input package:

1. `docs/tests/theory_change_review_index.md`
2. `review_records/system_design_review_summary.md`
3. all accepted reviewer PRs already merged into `review_branch`
4. candidate proposal files in `docs/tests/theory_change_reviews/`

Braintrust should issue one of the following dispositions per proposal:

- `Approved for tracking`
- `Deferred`
- `Rejected`
- `Needs rewrite`

Only proposals that receive `Approved for tracking` are allowed to enter the formal change register.

---

## Formal Change Tracking

Accepted items must be recorded in:

- `review_records/system_theory_change_tracking_register.md`

This register should be updated only by `summary_owner` or `review_owner` after braintrust final approval.

Minimum fields to record:

1. Proposal ID
2. Title
3. Source Author
4. Peer Review Outcome
5. Braintrust Final Disposition
6. Target Docs / Systems
7. Owner
8. Tracking Status
9. Evidence / Decision Links

If a proposal has not been recorded there, it has not entered formal follow-up.

---

## Close Phase

When summary is complete, `review_owner` changes:

- `phase: FROZEN` -> `phase: CLOSED`

And fills:

- `closed_at`
- `closure_note`

At this point:

- all review files become read-only for normal reviewers
- final human-facing conclusion is read from `review_records/system_design_review_summary.md`
- formal follow-up begins from `review_records/system_theory_change_tracking_register.md`

This is the closure phase.

---

## End-to-End Closure Loop

The complete review loop is:

1. publish `review_branch`
2. invite reviewers
3. reviewers submit PRs to `review_branch`
4. human merges accepted review PRs
5. human switches phase to `FROZEN`
6. `summary_owner` updates final rollup
7. human submits consolidated package to braintrust
8. braintrust issues final dispositions
9. approved items enter `system_theory_change_tracking_register.md`
10. human switches phase to `CLOSED`
11. review is complete

If any of these steps is missing, the review is not operationally closed.
