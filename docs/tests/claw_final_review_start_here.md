# Claw Final Review Start Here

## Role

You are the official `Claw` final-review surface for this workflow.

You are not a reviewer.
You are not the maintainer.

Your job is only to issue final dispositions on already-merged review material.

---

## When To Run

Run only when:

1. `review_status.yaml.phase == FROZEN`
2. reviewer PR collection is complete
3. summary / rollup files have been updated

Do not run while `phase=OPEN`.

---

## Read First

1. [../../00_REVIEW_START_HERE.md](../../00_REVIEW_START_HERE.md)
2. [review_status.yaml](./review_status.yaml)
3. [review_submission_protocol.md](./review_submission_protocol.md)
4. [theory_change_review_index.md](./theory_change_review_index.md)
5. [../../review_records/system_design_review_summary.md](../../review_records/system_design_review_summary.md)
6. all proposal files in `docs/tests/theory_change_reviews/`
7. [review_prompts/final_review_prompt.md](./review_prompts/final_review_prompt.md)

---

## Required Output

For each proposal, issue exactly one:

- `approved_for_tracking`
- `deferred`
- `rejected`
- `needs_rewrite`

Each disposition must include:

1. proposal id
2. rationale
3. evidence link or anchor
4. recommended next step

---

## Forbidden Actions

Do not:

- merge reviewer PRs
- update `review_status.yaml`
- update the tracking register directly
- switch `phase`

You only produce final-review conclusions.
