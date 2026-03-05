# Deployment Changelog

## v1.0.0 (2026-03-05)

### Changes
- Added release-grade deployment entry document `DEPLOYMENT_RELEASE.md`.
- Added release metadata source `config/deployment_release.yaml`.
- Added unified bootstrap runner `scripts/bootstrap_brain_trust.sh`.
- Added CI workflow `.github/workflows/brain_trust_verify.yml` for syntax + regression checks.
- Added repository baseline files `README.md` and `.gitignore`.

### Compatibility Impact
- Baseline OpenClaw version: `2026.3.2`.
- OpenAI policy fixed to `openai-codex/gpt-5.3-codex`.

### Migration Actions
- Prepare `config/brain_trust.env` from example.
- Run bootstrap command from `DEPLOYMENT_RELEASE.md`.
- Keep release docs and review trace in sync for future changes.

### Verification Evidence
- `bash -n` checks for core scripts.
- `scripts/test_run_brain_trust_review_regression.sh`.
- Bootstrap dry-run / apply report (`brain_trust_deploy_report.json`).
