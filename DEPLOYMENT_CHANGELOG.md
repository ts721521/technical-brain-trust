# Deployment Changelog

## v1.6.2 (2026-03-07)

### Changes
- Extended MVP closure runner to support multi-team owner mapping:
  - `team-knowledge -> scholar`
  - `team-rd -> rd_lead`
  - `team-smart3d -> smart3d_lead`
  - `team-proposal -> proposal_lead`
- Updated `scripts/tests/test_mvp_team_closure.sh` to validate Smart3D closure and owner mapping.
- Added Stage4 expansion docs for Smart3D team closure in deployment/README guides.
- Updated release metadata and consistency docs to `v1.6.2`.

### Compatibility Impact
- Backward compatible with existing `run_mvp_team_closure.sh` usage.
- Adds new recommended expansion scenario for `team-smart3d`.

### Migration Actions
- Run:
  - `scripts/run_mvp_team_closure.sh --docs-root /Volumes/TB512/3_ClawDocs --teams team-smart3d --tasks-per-team 3`
- Verify summary contains `team-smart3d` and `owner=smart3d_lead`.

### Verification Evidence
- `bash -n scripts/run_mvp_team_closure.sh`
- `bash -n scripts/tests/test_mvp_team_closure.sh`
- `scripts/tests/test_mvp_team_closure.sh`

## v1.6.1 (2026-03-07)

### Changes
- Added MVP team closure runner: `scripts/run_mvp_team_closure.sh`.
- Added MVP closure regression test: `scripts/tests/test_mvp_team_closure.sh`.
- Updated runtime audit to:
  - separate `failed_total` and `failed_recent` queue metrics
  - avoid cron false positives for `delivery=none`/`not-requested`
- Updated phase2 convergence to pre-create cross-team ledgers before daily audit.
- Added deployment/docs/CI/release-manifest coverage for MVP closure checks.

### Compatibility Impact
- No breaking changes to existing Stage1-Stage5 contracts.
- Adds new optional MVP evidence artifact:
  - `mvp_team_closure_report-YYYYMMDD-HHMMSS.json`

### Migration Actions
- Run `scripts/run_mvp_team_closure.sh --docs-root /Volumes/TB512/3_ClawDocs --teams team-knowledge,team-rd --tasks-per-team 3`.
- Verify acceptance evidence is generated under each team `evidence/<yyyymm>/`.

### Verification Evidence
- `bash -n scripts/run_mvp_team_closure.sh`
- `bash -n scripts/tests/test_mvp_team_closure.sh`
- `scripts/tests/test_mvp_team_closure.sh`

## v1.6.0 (2026-03-07)

### Changes
- Added Phase2 runtime convergence script: `scripts/phase2_runtime_convergence.sh`.
- Added daily runtime audit script: `scripts/runtime_health_audit.sh`.
- Added cron installer script for 05:00 daily audit: `scripts/install_runtime_audit_cron.sh`.
- Added runtime audit regression test: `scripts/tests/test_runtime_health_audit.sh`.
- Extended release metadata/manifest/CI checks with Phase2 scripts and audit checks.
- Added runtime audit outputs contract:
  - `runtime_health_report-YYYYMMDD-050000.json`
  - `agent_model_inventory-YYYYMMDD-050000.md`
  - `team_topology-YYYYMMDD-050000.md`
  - `improvement_backlog-YYYYMMDD-050000.md`

### Compatibility Impact
- Adds new runtime auditing workflow and expected ops artifacts under docs root.
- Introduces daily cron management requirement for runtime audit in production-like environments.

### Migration Actions
- Run `scripts/phase2_runtime_convergence.sh` once per environment.
- Ensure daily audit cron entry exists (`crontab -l | rg BT_RUNTIME_AUDIT`).
- Verify runtime audit outputs are generated under `/Volumes/TB512/3_ClawDocs/team-brain-trust/ops/<yyyymm>/`.

### Verification Evidence
- `bash -n scripts/runtime_health_audit.sh`
- `bash -n scripts/install_runtime_audit_cron.sh`
- `bash -n scripts/phase2_runtime_convergence.sh`
- `scripts/tests/test_runtime_health_audit.sh`

## v1.5.0 (2026-03-06)

### Changes
- Enforced business artifact path policy under `/Volumes/TB512/3_ClawDocs/<team>/<artifact>/<yyyymm>/`.
- Added docs path validator script: `scripts/validate_docs_path_policy.sh`.
- Added artifact ledger registration script: `scripts/register_artifact_index.sh`.
- Updated `run_brain_trust_review.sh` default output to docs root path and integrated path-policy validation.
- Added acceptance artifact generation `acceptance_report.json` (`reviewer=braintrust_compliance`).
- Added lifecycle task ledger script `scripts/task_ledger.sh` with strict state machine and reopen flow.
- Added lifecycle tests:
  - `scripts/tests/test_task_ledger.sh`
  - `scripts/tests/test_acceptance_gate.sh`
- Added channel-binding visibility checker `scripts/check_interface_bindings.sh` (default warn, `--strict` to block).
- Integrated task lifecycle writeback into `run_brain_trust_review.sh`:
  - Stage1 bootstrap: `published -> assigned -> in_progress`
  - Stage3 completion: `review`
  - Stage5 acceptance: `acceptance -> done` (pass) or `acceptance -> in_progress` (blocked + reopen actions)
- Added artifact index append for key outputs (`summary/structured/editor/acceptance/stage4 report`).
- Updated bootstrap defaults to docs-root deploy path and added `storage_status` in deploy report.
- Updated release metadata/runtime topology with acceptance owner and persona governance split (`wenquxing` / `knowledge_manager`).

### Compatibility Impact
- Default output path changed from repo-local `reviews/` to external docs root.
- Running with non-compliant `--out` now fails unless `BT_SKIP_DOCS_POLICY=true` is explicitly set.
- Regression script sets `BT_SKIP_DOCS_POLICY=true` for isolated temp-path tests.

### Migration Actions
- Ensure `/Volumes/TB512/3_ClawDocs` is mounted and writable, or set `BT_DOCS_ROOT` to a writable equivalent.
- Update environment file with `BT_DOCS_ROOT` and `BT_TEAM_ID`.
- Re-run validation and bootstrap after updating path policy.

### Verification Evidence
- `bash -n scripts/validate_docs_path_policy.sh`
- `bash -n scripts/register_artifact_index.sh`
- `bash -n scripts/run_brain_trust_review.sh`
- `bash -n scripts/task_ledger.sh`
- `bash -n scripts/tests/test_task_ledger.sh`
- `bash -n scripts/tests/test_acceptance_gate.sh`
- `bash -n scripts/check_interface_bindings.sh`
- `scripts/tests/test_task_ledger.sh`
- `scripts/tests/test_acceptance_gate.sh`
- `scripts/test_run_brain_trust_review_regression.sh`

## v1.4.3 (2026-03-05)

### Changes
- Removed static team model matrix as deployment-time fixed content.
- Added LuBan team-output contract: `team_blueprint.md`, `team_agent_contract.json`, `team_model_assignment.json`.
- Added LuBan role templates under `roles/luban/` (identity/soul/agents/tools + templates).
- Added new scripts:
  - `scripts/bootstrap_luban_role.sh`
  - `scripts/validate_team_contract.sh`
- Updated bootstrap pipeline to initialize LuBan role and enforce team-contract validation.
- Updated deployment metadata and release manifest to include LuBan contract artifacts.

### Compatibility Impact
- Team creation now requires contract artifacts before implementation handoff.
- `bootstrap_brain_trust.sh` deploy report includes LuBan/bootstrap + contract validation status.

### Migration Actions
- Bootstrap LuBan role once per environment.
- Validate team contract outputs with `scripts/validate_team_contract.sh --dir <team_dir>`.
- Route user interaction to team `interface_agent_id` only.

### Verification Evidence
- `bash -n scripts/bootstrap_luban_role.sh`
- `bash -n scripts/validate_team_contract.sh`
- `scripts/validate_team_contract.sh --dir roles/luban/templates`

## v1.4.2 (2026-03-05)

### Changes
- Added AI-facing release protocol document: `docs/AI_RELEASE_PROTOCOL.md`.
- Added human release runbook: `docs/HUMAN_RELEASE_RUNBOOK.md`.
- Added release navigation page: `docs/RELEASE_OVERVIEW.md`.
- Added docs consistency checker: `scripts/check_release_docs_consistency.sh`.
- Extended release verification workflow with docs consistency gate.
- Updated release manifest to include docs and docs-check script.

### Compatibility Impact
- No changes to runtime orchestration behavior.
- Release process now requires docs consistency check to pass.

### Migration Actions
- Follow `docs/AI_RELEASE_PROTOCOL.md` for AI-driven publishing.
- Follow `docs/HUMAN_RELEASE_RUNBOOK.md` for manual/incident publishing.
- Run `./scripts/check_release_docs_consistency.sh` before pushing `release`.

### Verification Evidence
- `bash -n scripts/check_release_docs_consistency.sh`
- `./scripts/check_release_docs_consistency.sh`
- `.github/workflows/public_release_verify.yml` includes docs consistency step

## v1.4.1 (2026-03-05)

### Changes
- Added public release isolation model: `main` (internal) + `release` (public reproducible package).
- Added whitelist manifest `release/release_manifest.txt` for release branch composition.
- Added `scripts/verify_public_release.sh` for leakage/pollution checks.
- Added `scripts/build_release_branch.sh` to generate and sync release branch from manifest.
- Added CI workflow `.github/workflows/public_release_verify.yml` for release branch safety gate.

### Compatibility Impact
- No runtime behavior change for review/execution pipeline.
- Publishing process now requires release safety verification before push.

### Migration Actions
- Use `scripts/build_release_branch.sh --version vX.Y.Z` to update `release` branch.
- Run `scripts/verify_public_release.sh --root . --manifest release/release_manifest.txt --enforce-manifest` before publish.

### Verification Evidence
- `bash -n scripts/verify_public_release.sh`
- `bash -n scripts/build_release_branch.sh`
- `scripts/verify_public_release.sh --root . --manifest release/release_manifest.txt`

## v1.4.0 (2026-03-05)

### Changes
- Added burst scheduling layer for execution-heavy tasks: single queue + `max_inflight=2`.
- Added auto scaling hook for backlog overflow via `scripts/ensure_scheduler_capacity.sh`.
- Added queue scheduler script `scripts/pangu_task_scheduler.sh` with `enqueue/dispatch-once/complete/drain/stats`.
- Integrated Stage4 queue scheduling into `scripts/run_brain_trust_review.sh`.
- Added `scheduling_summary` contract in `structured_summary.json` and summary report Stage4 block.
- Extended routing compaction metrics with queue indicators (`queued_ratio`, `avg_queue_wait_ms`, scale counts).

### Compatibility Impact
- Existing Stage1/2/3/4 outputs remain compatible; `scheduling_summary` is additive.
- Runtime now expects `runtime.scheduler.*` keys in config.

### Migration Actions
- Update runtime config with scheduler keys.
- Run syntax checks for new scripts.
- Run regression and verify `scheduling_summary` field appears in output.

### Verification Evidence
- `bash -n scripts/pangu_task_scheduler.sh`
- `bash -n scripts/ensure_scheduler_capacity.sh`
- `scripts/pangu_task_scheduler.sh stats --queue-file /tmp/bt_queue.jsonl --state-file /tmp/bt_queue_state.json`
- `scripts/test_run_brain_trust_review_regression.sh`

## v1.3.1 (2026-03-05)

### Changes
- Added main delegation delivery reliability patch (`delegate_preflight` + `send->spawn->resend` policy).
- Extended routing log contract with `delivery_mode`, `delegate_attempts`, `error_code`, and `recovered`.
- Updated `scripts/route_learning_compact.sh` to aggregate delegate success/recovery/unreachable diagnostics.
- Added `scripts/verify_main_delegate_reliability.sh` for three-scenario reliability checks and report output.
- Updated deployment docs and release metadata for delegate reliability acceptance.

### Compatibility Impact
- No breaking changes to existing stage outputs.
- Routing decision records now support additional optional fields for diagnostics.

### Migration Actions
- Update main workspace rules (`AGENTS.md`, `TOOLS.md`) with delivery contract.
- Run `scripts/verify_main_delegate_reliability.sh` and archive report.

### Verification Evidence
- `bash -n scripts/verify_main_delegate_reliability.sh`
- `scripts/verify_main_delegate_reliability.sh` (mock mode)
- `scripts/route_learning_compact.sh` output includes delegate metrics

## v1.3.0 (2026-03-05)

### Changes
- Promoted `main` to mixed-router mode with agent-level execution capability (`tools.profile=full`) while keeping global profile as `messaging`.
- Added layered memory governance contract for main/pangu/scheduler template.
- Added pangu direct-write governance to main (whitelist + mandatory audit logs).
- Added governance scripts:
  - `scripts/bootstrap_agent_memory_layers.sh`
  - `scripts/route_learning_compact.sh`
  - `scripts/promote_skill_from_pangu_to_main.sh`
- Updated deploy docs and release metadata to reflect main routing learning + skill gray promotion flow.

### Compatibility Impact
- Existing Stage1/2/3/4 review outputs are unchanged.
- Runtime policy now expects `main` allowlist entries for light execution paths.
- New memory files are additive and do not break old consumers.

### Migration Actions
- Re-run runtime permission setup to include `main` allowlist.
- Run `scripts/bootstrap_agent_memory_layers.sh` once per environment.
- Use promotion script for skill rollout instead of direct copy.

### Verification Evidence
- `openclaw config validate --json`
- `openclaw approvals get --json` confirms `main` and `pangu` allowlists
- `bash -n` checks for new governance scripts
- Local run of `route_learning_compact.sh` against routing decisions file

## v1.1.0 (2026-03-05)

### Changes
- Added Stage4 execution closure (`pangu`) to run pipeline and output contracts.
- Extended bootstrap deploy report with `agents.required`, `execution_chain.status`, and `e2e.stage4_status`.
- Updated workflow/charter/report/deploy docs to four-stage semantics and Stage1 serial wording alignment.
- Added Stage4 acceptance checks to `config/deployment_release.yaml`.

### Compatibility Impact
- No breaking change for existing Stage1/2/3 consumers; Stage4 fields are additive.
- `validate_brain_trust_env.sh` now requires `pangu` agent and `runtime.execution.*` config keys.

### Migration Actions
- Ensure `pangu` agent exists (bootstrap handles creation).
- Re-run bootstrap and confirm deploy report contains Stage4 fields.
- Verify E2E outputs include Stage4 artifacts.

### Verification Evidence
- `bash -n` checks for updated scripts.
- `scripts/test_run_brain_trust_review_regression.sh` (includes `pangu_fail` degraded path).
- Bootstrap report with Stage4 status fields.

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
