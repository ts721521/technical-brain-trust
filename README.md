# Technical Brain Trust

Technical Brain Trust is a three-role review orchestration system for OpenClaw:

- `architect`: architecture feasibility and tradeoffs
- `critic`: failure/risk stress testing
- `innovator`: simplification and alternatives

It produces a structured summary and recommendation with explicit routing, diagnostics, and traceability.

## Canonical Deployment Entry

Use [DEPLOYMENT_RELEASE.md](./DEPLOYMENT_RELEASE.md) as the only deployment entry for cross-Claw replication.

`00_DEPLOY_BRAIN_TRUST.md` is the detailed handbook; release-grade execution and acceptance criteria are maintained in `DEPLOYMENT_RELEASE.md`.

## Quick Start

1. Clone the repo.
2. Prepare env file:
   - `cp config/brain_trust.env.example config/brain_trust.env`
   - edit provider credentials/model IDs as required by release policy
3. Run bootstrap:
   - `./scripts/bootstrap_brain_trust.sh --root "$(pwd)" --env-file "$(pwd)/config/brain_trust.env" --record-dir /tmp/brain_trust_bootstrap --non-interactive --local`

## Release Policy

- Current release metadata: [config/deployment_release.yaml](./config/deployment_release.yaml)
- Deployment changes: [DEPLOYMENT_CHANGELOG.md](./DEPLOYMENT_CHANGELOG.md)
- Review trace record: [review_records/20260304_102620_Technical-Brain-Trust-部署到-Claw-可落地性评审.md](./review_records/20260304_102620_Technical-Brain-Trust-部署到-Claw-可落地性评审.md)

## Repository Layout

- `config/`: runtime configuration, env example, release metadata
- `roles/`: role instructions/contracts
- `scripts/`: validation, orchestration, sync, regression, bootstrap
- `review_records/`: immutable review trace
- `.agents/workflows/`: workflow entry definitions

## Governance Rule

Any deployment-related change must update all of:

1. `config/deployment_release.yaml`
2. `DEPLOYMENT_RELEASE.md`
3. `DEPLOYMENT_CHANGELOG.md`
4. review record latest trace chapter
