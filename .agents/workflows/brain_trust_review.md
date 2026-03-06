# Brain Trust Review Workflow

## Purpose
Run a full Brain Trust four-stage closure for a proposal:
Stage1 independent reviews (serial) -> Stage2 cross reviews -> Stage3 editor synthesis -> Stage4 pangu execution.

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
- `architect_cross_review.md`
- `critic_cross_review.md`
- `innovator_cross_review.md`
- `editor_review.md`
- `pangu_execution_plan.md`
- `pangu_execution_report.md`
- `pangu_execution_raw.json`
- `summary_report.md`
- `structured_summary.json`
- `acceptance_report.json`
- `quality_gate_report.json`

## Execution Rules
1. Validate env/config using `scripts/validate_brain_trust_env.sh`.
2. Stage1 runs in serial order `architect -> critic -> innovator` to avoid OpenClaw global model override conflicts.
3. Stage2 cross review runs only when corresponding Stage1 role output exists.
4. Stage3 editor synthesis merges consensus/divergence and outputs recommendation language only.
5. Stage4 triggers `pangu` execution by default (auto, autonomous scope), consumes Stage3 outputs, and writes execution artifacts.
6. If one role fails in Stage1, follow config degradation strategy:
- if completed roles >= `runtime.degradation.min_roles_required`: mark as `degraded` and continue
- else: fail the whole run
7. If Stage4 fails:
- apply `runtime.execution.on_failure`
- default behavior is `degraded_continue` (full run continues with retryable items)
8. Synthesize summary report with:
- score overview
- consensus/divergence notes
- intent alignment summary
- open-source validation evidence summary
- complexity reduction summary
- Stage4 execution summary
9. Write acceptance result (`acceptance_report.json`) with reviewer `braintrust_compliance`.

## Non-goals
- No external adjudication or external routing.
- No blocking verdict semantics; output is recommendation only.
