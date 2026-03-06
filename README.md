# Technical Brain Trust

Technical Brain Trust is a four-stage review-execution orchestration system for OpenClaw:

- `architect`: architecture feasibility and tradeoffs
- `critic`: failure/risk stress testing
- `innovator`: simplification and alternatives
- `luban`: chief architect for team/interface-agent design artifacts
- `pangu`: Stage4 execution handoff (plan + implementation trace)

It produces a structured summary, recommendation, and Stage4 execution trace with explicit routing and diagnostics.

Team creation is contract-driven:
- `team_blueprint.md`
- `team_agent_contract.json`
- `team_model_assignment.json`

## Canonical Deployment Entry

Use [DEPLOYMENT_RELEASE.md](./DEPLOYMENT_RELEASE.md) as the only deployment entry for cross-Claw replication.

`00_DEPLOY_BRAIN_TRUST.md` is the detailed handbook; release-grade execution and acceptance criteria are maintained in `DEPLOYMENT_RELEASE.md`.

## Quick Start

1. Clone the repo.
2. Prepare env file:
   - `cp config/brain_trust.env.example config/brain_trust.env`
   - edit provider credentials/model IDs as required by release policy
3. Run bootstrap:
   - `./scripts/bootstrap_brain_trust.sh --root "$(pwd)" --env-file "$(pwd)/config/brain_trust.env" --record-dir /Volumes/TB512/3_ClawDocs/team-brain-trust/deploy/$(date +%Y%m) --non-interactive --local`

E2E output includes:
- Stage1/2/3 review artifacts
- Stage4 artifacts: `pangu_execution_plan.md`, `pangu_execution_report.md`, `pangu_execution_raw.json`
- Acceptance artifact: `acceptance_report.json` (`reviewer=braintrust_compliance`)
- Business artifacts default to `/Volumes/TB512/3_ClawDocs/<team>/<artifact>/<yyyymm>/`

## Release Policy

- Current release metadata: [config/deployment_release.yaml](./config/deployment_release.yaml)
- Deployment changes: [DEPLOYMENT_CHANGELOG.md](./DEPLOYMENT_CHANGELOG.md)
- Internal review trace (optional): `review_records/`

## Public Release Branch

This repository uses a split model:
- `main`: full internal iteration branch
- `release`: public reproducible package branch

Build/update `release` from `main`:

```bash
./scripts/build_release_branch.sh --version v1.6.1
```

Pre-publish safety gate:

```bash
git switch release
./scripts/verify_public_release.sh --root . --manifest release/release_manifest.txt --enforce-manifest
```

## 发布机制文档

- [Release Overview](./docs/RELEASE_OVERVIEW.md)
- [AI Release Protocol](./docs/AI_RELEASE_PROTOCOL.md)
- [Human Release Runbook](./docs/HUMAN_RELEASE_RUNBOOK.md)
- [Team Storage Policy](./docs/TEAM_STORAGE_POLICY.md)

## Repository Layout

- `config/`: runtime configuration, env example, release metadata
- `roles/`: role instructions/contracts
- `scripts/`: validation, orchestration, sync, regression, bootstrap
- `review_records/`: immutable review trace
- `.agents/workflows/`: workflow entry definitions

## Phase2 Runtime Convergence

```bash
./scripts/phase2_runtime_convergence.sh \
  --docs-root /Volumes/TB512/3_ClawDocs \
  --team team-brain-trust \
  --install-cron true
```

Daily 05:00 runtime audit outputs:
- `runtime_health_report-YYYYMMDD-050000.json`
- `agent_model_inventory-YYYYMMDD-050000.md`
- `team_topology-YYYYMMDD-050000.md`
- `improvement_backlog-YYYYMMDD-050000.md`

MVP closure smoke (knowledge + rd teams):

```bash
./scripts/run_mvp_team_closure.sh \
  --docs-root /Volumes/TB512/3_ClawDocs \
  --teams team-knowledge,team-rd \
  --tasks-per-team 3
```

## Governance Rule

Any deployment-related change must update all of:

1. `config/deployment_release.yaml`
2. `DEPLOYMENT_RELEASE.md`
3. `DEPLOYMENT_CHANGELOG.md`
4. `review_records/` latest trace chapter (optional, for internal audit)
