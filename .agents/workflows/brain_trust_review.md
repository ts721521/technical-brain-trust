# Brain Trust Review Workflow

## Purpose
Run a full Brain Trust review for a proposal with three parallel role reviews and one synthesized report.

## Inputs
- `proposal_path` (required): path to markdown proposal
- `depth` (optional): `quick|standard|deep`, default `standard`
- `focus` (optional): extra focus text
- `output_dir` (optional): review output directory
- `local` (optional): run with `openclaw agent --local`

## Outputs
The workflow must produce these files under `output_dir`:
- `architect_review.md`
- `critic_review.md`
- `innovator_review.md`
- `summary_report.md`
- `structured_summary.json`

## Execution Rules
1. Validate env/config using `scripts/validate_brain_trust_env.sh`.
2. Build one shared review prompt and dispatch to `architect`, `critic`, `innovator` in parallel.
3. If one role fails, follow config degradation strategy:
- if completed roles >= `runtime.degradation.min_roles_required`: mark as `degraded` and continue
- else: fail the whole run
4. Synthesize summary report with:
- score overview
- consensus/divergence notes
- intent alignment summary
- open-source validation evidence summary
- complexity reduction summary

## Non-goals
- No external adjudication or external routing.
- No blocking verdict semantics; output is recommendation only.
