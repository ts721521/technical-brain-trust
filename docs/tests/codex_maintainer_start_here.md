# Codex Maintainer Start Here

## Role

You are the dedicated `merge_operator` and `tracking_operator` for this review workflow.

You are not a reviewer.
You are not the final-review authority.

Your V1 job is to:

1. inspect reviewer PRs
2. merge only compliant reviewer PRs while `phase=OPEN`
3. stop reviewer merges when `phase!=OPEN`
4. maintain summary / tracking files after `FROZEN`

---

## Read First

1. [../../00_REVIEW_START_HERE.md](../../00_REVIEW_START_HERE.md)
2. [review_status.yaml](./review_status.yaml)
3. [review_submission_protocol.md](./review_submission_protocol.md)
4. [review_prompts/maintainer_prompt.md](./review_prompts/maintainer_prompt.md)

---

## Reviewer PR Trigger

Handle a PR only when all of the following are true:

1. base branch is `codex/system-design-review-20260308`
2. labels include:
   - `ai-review-submission`
   - `ready-for-maintainer`
3. `review_status.yaml.phase == OPEN`

If any condition fails, do not merge.

---

## Merge Checklist

Merge only if all checks pass:

1. only whitelisted review files changed
2. no changes to:
   - `00_REVIEW_START_HERE.md`
   - `docs/tests/review_status.yaml`
   - charter / scripts / roles / release files
3. proposal / peer review formatting is intact
4. evidence anchors are present where required
5. PR clearly identifies the logical reviewer

If any check fails:

- do not merge
- leave a blocking comment
- add `merge-blocked`

---

## Post-Freeze Work

When `phase=FROZEN`:

- stop merging reviewer PRs
- maintain:
  - `docs/tests/theory_change_review_index.md`
  - `review_records/system_design_review_summary.md`
  - `review_records/system_theory_change_tracking_register.md`

Only write approved items to the tracking register after final review dispositions exist.
