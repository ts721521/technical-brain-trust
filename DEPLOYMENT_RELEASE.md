# Brain Trust Deployment Release v1.6.5

## Scope

This document is the canonical, release-grade deployment entry for replicating the same Brain Trust system on another OpenClaw environment.

## Release Baseline

- Release version: `v1.6.5`
- OpenClaw compatibility: `2026.3.2`
- OpenAI policy: only `openai-codex/gpt-5.3-codex`
- Stage1 execution mode: serial (to avoid global model override races in OpenClaw)
- Standard chain: Stage1 review -> Stage2 cross review -> Stage3 editor synthesis -> Stage4 pangu execution -> Stage5 quality gate & improvement writeback (design contract)
- Runtime topology: `main` mixed router -> `luban` architecture orchestration -> `pangu` execution queue scheduler -> `scheduler-*` independent dispatchers
- Acceptance owner: `braintrust_compliance`
- Persona owner split: `wenquxing`(主写入) + `knowledge_manager`(治理审计)
- Learning interface agent: `scholar` (single external entry for knowledge learning tasks)
- Notification agent: `feige_notifier` (Telegram/Email delivery with receipt)
- Team model assignment policy: dynamic artifact output (not static deployment matrix)

Source of truth: `config/deployment_release.yaml`

## Prerequisites

1. `openclaw` CLI installed and configured.
2. `gh` CLI installed and authenticated (for GitHub publishing steps).
3. Provider credentials configured in your local OpenClaw profile.
4. Local env file prepared:
   - `cp config/brain_trust.env.example config/brain_trust.env`
   - edit values if needed (must satisfy policy and validation script).
5. Business docs root available and writable:
   - default: `/Volumes/TB512/3_ClawDocs`
   - or set `BT_DOCS_ROOT` to a writable mounted path.

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
- Stage4 deploy verification is included in deploy report: `execution_chain.status` and `e2e.stage4_status`

## Runtime Permission Contract (Locked)

1. Keep global `tools.profile=messaging`.
2. Set agent override for `main` and `pangu`: `tools.profile=full`.
3. Keep approval mode as ask (no blanket auto-allow).
4. Maintain minimal allowlist for operational binaries on `main` and `pangu`.
5. New `scheduler-*` agents should follow the same policy as `pangu`:
   - `tools_profile=full`
   - `approval_mode=ask`
   - independent workspace and routing
6. Pangu direct write to main is allowed only in whitelist paths with mandatory audit logs.

## Team Interface Agent Contract (Locked)

1. Team creation/restructure must output:
- `team_blueprint.md`
- `team_agent_contract.json`
- `team_model_assignment.json`
2. Each team must define a unique `interface_agent_id`.
3. User interacts only with `interface_agent_id`; internal agents do not reply to user directly.
4. `main` routes to `interface_agent_id` or `luban`, never direct to team internal agents.
5. Model assignment must include `selection_rationale` per agent.

## Memory Governance Contract (Layered)

1. Main shared routing memory:
   - `~/.openclaw/workspace/memory/ROUTING_MEMORY.md`
   - `~/.openclaw/workspace/memory/ROUTING_DECISIONS.jsonl`
   - `~/.openclaw/workspace/memory/PROMOTION_LOG.jsonl`
2. Pangu private execution memory:
   - `~/.openclaw/workspaces/pangu/memory/EXECUTION_LEARNINGS.md`
   - `~/.openclaw/workspaces/pangu/memory/MAIN_PATCH_LOG.jsonl`
3. Initialize/maintain with:
   - `scripts/bootstrap_agent_memory_layers.sh`
   - `scripts/route_learning_compact.sh`
   - `scripts/promote_skill_from_pangu_to_main.sh`

## Quality Closed-Loop Contract (Design-Level)

This release also locks a design-layer quality loop for all teams:

1. Quality Self-Gate Protocol (QSGP), mandatory 3 gates per delivery:
- precheck gate
- execution gate
- release gate
2. If any gate fails, delivery status must be `blocked`.
3. Quality Evolution Loop (QEL), periodic cycle:
- aggregate failures
- identify top root causes
- run targeted improvements
- promote or rollback
- refresh baseline metrics

Design artifacts required by this contract:
- `quality_gate_report.json`
- `quality_improvement_log.jsonl`
- `quality_baseline.yaml`

## Scholar Learning Contract (Design-Level)

This release locks a design-layer learning loop for the knowledge team:

1. `scholar` is the only external interface for learning tasks.
2. Internal learning execution is orchestrated through:
   - `km_collector` (source collection)
   - `km_organizer` (classification and synthesis)
   - `km_indexer` (index refresh)
   - `wenquxing` (persona writeback)
3. Governance and acceptance:
   - `knowledge_manager` performs audit/governance only
   - `braintrust` provides review suggestion
   - `braintrust_compliance` produces acceptance result
   - `feige_notifier` sends external notifications and writes receipts
4. Learning cadence:
   - one topic per day
   - continuous learning when idle
   - up to 20 sources/day (default)
   - review-then-notify at `04:00`
5. Open-source scoring gate:
   - `project_score = 0.35*活跃度 + 0.25*维护响应 + 0.20*采用度 + 0.10*安全信号 + 0.10*许可兼容`
   - score >= 70 for candidate knowledge entries
   - score < 70 to observation pool only
6. Required learning artifacts:
   - `learning_topic_plan-YYYYMMDD-HHMMSS.md`
   - `source_candidates-YYYYMMDD-HHMMSS.json`
   - `source_evaluation-YYYYMMDD-HHMMSS.json`
   - `knowledge_digest-YYYYMMDD-HHMMSS.md`
   - `qmd_sync_report-YYYYMMDD-HHMMSS.json`
   - `notification_receipt-YYYYMMDD-HHMMSS.json`

## GitHub First Publish (public repo)

```bash
cd /path/to/Technical_Brain_Trust

# if no remote exists
if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create technical-brain-trust --public --source . --remote origin --push
else
  git push -u origin main
fi
```

## Public Release Publish Flow

Use branch split to avoid contamination:
- `main`: internal evolving branch
- `release`: public reproducible package branch
- `00_DEPLOY_BRAIN_TRUST.md`: internal handbook (main only, not included in release package)

Build and verify `release` from `main`:

```bash
./scripts/build_release_branch.sh --version v1.6.5
git switch release
./scripts/verify_public_release.sh --root . --manifest release/release_manifest.txt --enforce-manifest
./scripts/check_release_docs_consistency.sh
```

Push public branch and tags:

```bash
git push origin release --tags
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
- `bash -n scripts/bootstrap_luban_role.sh`
- `bash -n scripts/validate_team_contract.sh`
- `bash -n scripts/sync_brain_trust_models.sh`
- `bash -n scripts/test_run_brain_trust_review_regression.sh`
- `bash -n scripts/bootstrap_brain_trust.sh`
- `bash -n scripts/bootstrap_agent_memory_layers.sh`
- `bash -n scripts/route_learning_compact.sh`
- `bash -n scripts/promote_skill_from_pangu_to_main.sh`
- `bash -n scripts/verify_main_delegate_reliability.sh`
- `bash -n scripts/pangu_task_scheduler.sh`
- `bash -n scripts/ensure_scheduler_capacity.sh`
- `bash -n scripts/verify_public_release.sh`
- `bash -n scripts/build_release_branch.sh`
- `bash -n scripts/check_release_docs_consistency.sh`
- `bash -n scripts/validate_docs_path_policy.sh`
- `bash -n scripts/register_artifact_index.sh`
- `bash -n scripts/task_ledger.sh`
- `bash -n scripts/tests/test_task_ledger.sh`
- `bash -n scripts/tests/test_acceptance_gate.sh`
- `bash -n scripts/runtime_health_audit.sh`
- `bash -n scripts/bootstrap_agent_sessions.sh`
- `bash -n scripts/install_runtime_audit_cron.sh`
- `bash -n scripts/phase2_runtime_convergence.sh`
- `bash -n scripts/run_mvp_team_closure.sh`
- `bash -n scripts/tests/test_runtime_health_audit.sh`
- `bash -n scripts/tests/test_bootstrap_agent_sessions.sh`
- `bash -n scripts/tests/test_mvp_team_closure.sh`

2. Policy and env validation
- `source config/brain_trust.env.example && scripts/validate_brain_trust_env.sh`
- `scripts/validate_team_contract.sh --dir roles/luban/templates`
- `scripts/verify_public_release.sh --root . --manifest release/release_manifest.txt --enforce-manifest`
- `scripts/check_release_docs_consistency.sh`
- `scripts/validate_docs_path_policy.sh --docs-root /Volumes/TB512/3_ClawDocs --out /Volumes/TB512/3_ClawDocs/team-brain-trust/review/$(date +%Y%m)`
- `scripts/check_interface_bindings.sh`

3. Regression
- `scripts/test_run_brain_trust_review_regression.sh`
- `scripts/tests/test_task_ledger.sh`
- `scripts/tests/test_acceptance_gate.sh`
- `scripts/tests/test_runtime_health_audit.sh`
- `scripts/tests/test_bootstrap_agent_sessions.sh`
- `scripts/tests/test_mvp_team_closure.sh`
- `scripts/runtime_health_audit.sh --slot-time 050000 --notify false`
- `scripts/bootstrap_agent_sessions.sh --docs-root /Volumes/TB512/3_ClawDocs --team team-brain-trust --strict false`
- `scripts/run_mvp_team_closure.sh --docs-root /Volumes/TB512/3_ClawDocs --teams team-knowledge,team-rd,team-smart3d --tasks-per-team 1 --yyyymm $(date +%Y%m)`
- `scripts/run_mvp_team_closure.sh --docs-root /Volumes/TB512/3_ClawDocs --teams team-proposal --tasks-per-team 1 --yyyymm $(date +%Y%m)`

4. E2E smoke
- `scripts/run_brain_trust_review.sh --proposal 02_Proposal_Submission_Template.md --depth quick --out /Volumes/TB512/3_ClawDocs/team-brain-trust/review/$(date +%Y%m) --local`

5. Contract checks
- `structured_summary.json` includes: `stage1_mode`, `model_routing_summary`, `parse_diagnostics`, `score_summary`, `orchestration.stage4_status`, `execution_summary`, `scheduling_summary`.
- `acceptance_report.json` exists and contains `reviewer=braintrust_compliance` and `status(pass|blocked)`.
- `quality_gate_report.json` exists and contains `final_quality_status=pass|blocked`.
- `quality_improvement_log.jsonl` exists and latest row includes `experiment_result`.
- `quality_baseline.yaml` exists with baseline targets.
- `task_ledger.jsonl` has lifecycle evidence:
  - `published -> assigned -> in_progress -> review -> acceptance`
  - pass path reaches `done`
  - blocked path reopens to `in_progress` with `reopen_actions`
- MVP teams (`team-knowledge`, `team-rd`, `team-smart3d`, `team-proposal`) each produce closure evidence:
  - per-team ledger exists under `/Volumes/TB512/3_ClawDocs/<team>/ops/<yyyymm>/task_ledger.jsonl`
  - acceptance evidence files exist under `/Volumes/TB512/3_ClawDocs/<team>/evidence/<yyyymm>/`
- Daily runtime audit artifacts exist under `/Volumes/TB512/3_ClawDocs/team-brain-trust/ops/<yyyymm>/`:
  - `runtime_health_report-YYYYMMDD-050000.json`
  - `agent_model_inventory-YYYYMMDD-050000.md`
  - `team_topology-YYYYMMDD-050000.md`
  - `improvement_backlog-YYYYMMDD-050000.md`
- `runtime_health_report` includes `agent_bootstrap.pending_count_actionable` and `pending_agents_actionable` for initialization blockage diagnosis.
- Model drift report includes primary/fallback diff for: `architect/critic/innovator/pangu/scholar/feige_notifier`.
- Routing/output must not contain `spark` or unsupported OpenAI variants.
- Stage4 artifacts exist: `pangu_execution_plan.md`, `pangu_execution_report.md`, `pangu_execution_raw.json`.
- Stage4 completion proof gate is enforced:
  - success requires non-empty Stage4 artifacts
  - `pangu_execution_summary.json` is parseable with required fields
  - stderr has no critical failure signal
  - otherwise `error_code=completion_without_artifact` and stage4 degrades/fails

6. Runtime monitor checks
- Cron monitor job must not use `delivery.mode=none`.
- When using `--announce` delivery, `sessionTarget` must be `isolated` (OpenClaw CLI constraint).
- If `sessionTarget=main` is required, use `system-event` instead of `--message`.
- Idle decision must use union check (`openclaw sessions --all-agents --active 30 --json` + queue state + active sub-sessions), not `sessions_list` alone.
- Daily 05:00 runtime audit cron is installed:
  - `scripts/install_runtime_audit_cron.sh --docs-root /Volumes/TB512/3_ClawDocs --team team-brain-trust`

7. Scholar strict test phases (design acceptance)
- K1 role/config consistency:
  - `scholar` and `feige_notifier` exist in agent list
  - `scholar` is the only external entry for learning tasks
  - configured model keys are available
- K2 learning E2E:
  - topic generation -> multi-source collection (>=3, includes non-GitHub) -> QMD refresh -> review -> acceptance -> 04:00 notification with receipt
- K3 failure and recovery:
  - source failure triggers source switch + evidence
  - QMD failure forces blocked/degraded (no pseudo completion)
  - blocked review prevents main knowledge base write
  - notification failure retries and records final status

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

5. Stage4 execution failed
- Confirm `pangu` agent exists and is callable.
- Check `pangu_execution_raw.json.stderr` and `structured_summary.json.execution_summary.retryable_items`.
- Re-run with the same proposal after provider recovery.
6. Pangu cannot execute tool commands
- Check `~/.openclaw/openclaw.json` has `pangu.tools.profile=full`.
- Check `openclaw approvals get --json` includes `agents.pangu.allowlist`.
- Run `openclaw config validate --json && openclaw gateway restart`.
7. ClawHub install returns `Rate limit exceeded` or `Not logged in`
- Run `clawhub login` first.
- Retry `clawhub install --workdir ~/.openclaw/workspaces/pangu self-improving-agent`.
- Verify with `clawhub list --workdir ~/.openclaw/workspaces/pangu`.
- Note: `openclaw skills info` may not list third-party ClawHub skills in current OpenClaw build; do not block deployment on this check.
8. Main routing quality degrades over time
- Ensure dispatch logs are written to `ROUTING_DECISIONS.jsonl`.
- Run `scripts/route_learning_compact.sh` to refresh route memory.
9. Skill promotion needs controlled rollout
- Run `scripts/promote_skill_from_pangu_to_main.sh --skill <slug>`.
- Check both logs: `PROMOTION_LOG.jsonl` and `MAIN_PATCH_LOG.jsonl`.
10. Delegate assigned but not delivered
- Run `scripts/verify_main_delegate_reliability.sh` (mock acceptance).
- Optional live check: `scripts/verify_main_delegate_reliability.sh --mode live`.
- If live shows `delegate_unreachable`, follow retry command and re-check.
11. Burst tasks overload pangu
- Check queue status: `scripts/pangu_task_scheduler.sh stats --queue-file ~/.openclaw/workspaces/pangu/memory/TASK_QUEUE.jsonl --state-file ~/.openclaw/workspaces/pangu/memory/TASK_QUEUE_STATE.json`.
- If backlog persists, run `scripts/ensure_scheduler_capacity.sh --queue-depth <n> --threshold 6 --registry-file ~/.openclaw/workspaces/pangu/memory/SCHEDULER_REGISTRY.json --events-file ~/.openclaw/workspaces/pangu/memory/SCHEDULER_EVENTS.jsonl`.
- Check `structured_summary.json.scheduling_summary` for `queue_full|queue_dispatch_timeout|scheduler_spawn_failed`.
12. Completion says success but no real artifacts
- Check queue record and Stage4 stderr for `completion_without_artifact`.
- Re-run Stage4 after fixing output generation; do not manually force queue item to `completed`.
13. Docs root unavailable
- If `/Volumes/TB512/3_ClawDocs` is unavailable, do not fallback to local disk for business artifacts.
- Set `BT_DOCS_ROOT=<mounted_writable_path>` and rerun validation/deployment.

## Why Stage1 is Serial

OpenClaw model defaults are globally shared at runtime. Running Stage1 in parallel can cause per-role model overrides to race. Serial execution preserves per-role routing correctness and traceability.

## Detailed Handbook

See `00_DEPLOY_BRAIN_TRUST.md` for expanded manual steps and troubleshooting context.

## 发布机制文档

- [Release Overview](./docs/RELEASE_OVERVIEW.md)
- [AI Release Protocol](./docs/AI_RELEASE_PROTOCOL.md)
- [Human Release Runbook](./docs/HUMAN_RELEASE_RUNBOOK.md)
- [Team Storage Policy](./docs/TEAM_STORAGE_POLICY.md)
