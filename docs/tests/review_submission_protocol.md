# Review Submission Protocol

## Purpose

This file defines how each reviewer should move completed review work into GitHub, and how the human owner closes the review loop.

It exists to prevent three failure modes:

1. Multiple reviewers pushing directly to the same branch and overwriting each other
2. Reviews being written but never merged into the canonical review branch
3. Review collection ending without a clear freeze and close step

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

## Freeze Phase

When reviewer collection is complete, `review_owner` changes:

- `phase: OPEN` -> `phase: FROZEN`

At this point:

- normal reviewers stop editing
- no more reviewer PRs should be opened
- `summary_owner` consolidates accepted review results

Only summary work should continue.

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
7. human switches phase to `CLOSED`
8. review is complete

If any of these steps is missing, the review is not operationally closed.
