# Brain Trust Deployment Release v1.0.0

## Scope

This document is the canonical, release-grade deployment entry for replicating the same Brain Trust system on another OpenClaw environment.

## Release Baseline

- Release version: `v1.0.0`
- OpenClaw compatibility: `2026.3.2`
- OpenAI policy: only `openai-codex/gpt-5.3-codex`
- Stage1 execution mode: serial (to avoid global model override races in OpenClaw)

Source of truth: `config/deployment_release.yaml`

## Prerequisites

1. `openclaw` CLI installed and configured.
2. `gh` CLI installed and authenticated (for GitHub publishing steps).
3. Provider credentials configured in your local OpenClaw profile.
4. Local env file prepared:
   - `cp config/brain_trust.env.example config/brain_trust.env`
   - edit values if needed (must satisfy policy and validation script).

## One-Command Deployment

```bash
cd /path/to/Technical_Brain_Trust
./scripts/bootstrap_brain_trust.sh \
  --root "$(pwd)" \
  --env-file "$(pwd)/config/brain_trust.env" \
  --record-dir /tmp/brain_trust_bootstrap \
  --non-interactive \
  --local
```

Main output:

- `/tmp/brain_trust_bootstrap/brain_trust_deploy_report.json`
- `/tmp/brain_trust_bootstrap/model_assignment_record.json`
- `/tmp/brain_trust_bootstrap/model_inventory/available_models.json`
- `/tmp/brain_trust_bootstrap/e2e_output/*` (if E2E not skipped)

## GitHub First Publish (private repo)

```bash
cd /path/to/Technical_Brain_Trust

# if no remote exists
if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create technical-brain-trust --private --source . --remote origin --push
else
  git push -u origin main
fi
```

## Recommended Branch Protection

1. Require pull request before merging into `main`.
2. Require status checks to pass:
   - `brain_trust_verify / verify`
3. Disable force-push on `main`.

## Acceptance Matrix

1. Syntax checks
- `bash -n scripts/run_brain_trust_review.sh`
- `bash -n scripts/validate_brain_trust_env.sh`
- `bash -n scripts/sync_brain_trust_models.sh`
- `bash -n scripts/test_run_brain_trust_review_regression.sh`
- `bash -n scripts/bootstrap_brain_trust.sh`

2. Policy and env validation
- `source config/brain_trust.env.example && scripts/validate_brain_trust_env.sh`

3. Regression
- `scripts/test_run_brain_trust_review_regression.sh`

4. E2E smoke
- `scripts/run_brain_trust_review.sh --proposal 02_Proposal_Submission_Template.md --depth quick --out /tmp/brain_trust_e2e --local`

5. Contract checks
- `structured_summary.json` includes: `stage1_mode`, `model_routing_summary`, `parse_diagnostics`, `score_summary`.
- Routing/output must not contain `spark` or unsupported OpenAI variants.

## Failure Recovery

1. Env validation failed
- Fix `config/brain_trust.env` values.
- Re-run bootstrap.

2. Model sync mismatch
- Run `scripts/sync_brain_trust_models.sh --apply --record /tmp/bt_model_assignment.json`.

3. Regression failed
- Fix script/config issue first; do not publish before regression passes.

4. E2E failed due provider timeout/quota
- Keep regression as hard gate.
- Re-run E2E with available quota and check routing/fallback logs.

## Why Stage1 is Serial

OpenClaw model defaults are globally shared at runtime. Running Stage1 in parallel can cause per-role model overrides to race. Serial execution preserves per-role routing correctness and traceability.

## Detailed Handbook

See `00_DEPLOY_BRAIN_TRUST.md` for expanded manual steps and troubleshooting context.
