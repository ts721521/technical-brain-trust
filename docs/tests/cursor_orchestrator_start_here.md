# Cursor Orchestrator Start Here

## Role

`Cursor` is the primary operator console in V1.

The human operator works here and manually switches reviewer models.
`Cursor` is not the merge operator and not the final-review authority.

Its job is to orchestrate the flow:

1. run reviewer models
2. hand reviewer output into GitHub PR flow
3. hand reviewer PRs to `Codex`
4. hand frozen review packages to `Claw`

---

## V1 Workflow

1. Read [../../00_REVIEW_START_HERE.md](../../00_REVIEW_START_HERE.md)
2. Read [review_status.yaml](./review_status.yaml)
3. Use [review_prompts/reviewer_prompt.md](./review_prompts/reviewer_prompt.md) with the chosen reviewer model
4. Let the reviewer submit a PR with the required labels and [reviewer_pr_template.md](./reviewer_pr_template.md)
5. Hand that PR to `Codex`
6. When review collection is complete and `phase=FROZEN`, trigger `Claw` using [review_prompts/final_review_prompt.md](./review_prompts/final_review_prompt.md)

---

## Boundaries

`Cursor` should not directly:

- merge reviewer PRs
- update `review_status.yaml`
- write final dispositions on behalf of `Claw`
- bypass the GitHub PR flow

---

## Related Files

- [cursor_reviewer_start_here.md](./cursor_reviewer_start_here.md)
- [codex_maintainer_start_here.md](./codex_maintainer_start_here.md)
- [claw_final_review_start_here.md](./claw_final_review_start_here.md)
