#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/config/brain_trust.env"
RECORD_DIR="/tmp/brain_trust_bootstrap_$(date +%Y%m%d_%H%M%S)"
NON_INTERACTIVE="false"
DRY_RUN="false"
SKIP_E2E="false"
USE_LOCAL="false"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --root <abs_path>       Project root path (default: script parent root)
  --env-file <abs_path>   Env file path (default: <root>/config/brain_trust.env)
  --record-dir <abs_path> Output record directory
  --non-interactive       Use non-interactive OpenClaw commands where supported
  --dry-run               Validate and simulate mutating actions without applying changes
  --skip-e2e              Skip E2E smoke run
  --local                 Pass --local to run_brain_trust_review.sh during E2E
  -h, --help              Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT_DIR="${2:-}"
      shift 2
      ;;
    --env-file)
      ENV_FILE="${2:-}"
      shift 2
      ;;
    --record-dir)
      RECORD_DIR="${2:-}"
      shift 2
      ;;
    --non-interactive)
      NON_INTERACTIVE="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --skip-e2e)
      SKIP_E2E="true"
      shift
      ;;
    --local)
      USE_LOCAL="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -d "${ROOT_DIR}" ]]; then
  echo "Root directory not found: ${ROOT_DIR}" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Env file not found: ${ENV_FILE}" >&2
  exit 1
fi

mkdir -p "${RECORD_DIR}"

REPORT_FILE="${RECORD_DIR}/brain_trust_deploy_report.json"
FAILURES_FILE="${RECORD_DIR}/failures.log"
ARTIFACTS_FILE="${RECORD_DIR}/artifacts.log"
: >"${FAILURES_FILE}"
: >"${ARTIFACTS_FILE}"

log() {
  printf '[bootstrap] %s\n' "$*"
}

record_failure() {
  local step="$1"
  local msg="$2"
  printf '%s|%s\n' "${step}" "${msg}" >>"${FAILURES_FILE}"
}

record_artifact() {
  local path="$1"
  printf '%s\n' "${path}" >>"${ARTIFACTS_FILE}"
}

status_preflight="pending"
status_agents="pending"
status_validation="pending"
status_luban_role="pending"
status_team_contract="pending"
status_model_sync="pending"
status_regression="pending"
status_execution_chain="pending"
status_e2e="pending"
e2e_stage4_status="unknown"

read_release_value() {
  local key="$1"
  local default_value="$2"
  python3 - "${ROOT_DIR}/config/deployment_release.yaml" "${key}" "${default_value}" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
default = sys.argv[3]
if not path.exists():
    print(default)
    raise SystemExit(0)

for raw in path.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    if line.startswith(f"{key}:"):
        value = line.split(":", 1)[1].strip().strip('"').strip("'")
        print(value if value else default)
        raise SystemExit(0)

print(default)
PY
}

release_version="$(read_release_value "release_version" "unknown")"
release_openclaw_compat="$(read_release_value "openclaw_compatibility" "unknown")"

run_cmd_log() {
  local step="$1"
  local logfile="$2"
  shift 2
  if "$@" >"${logfile}" 2>&1; then
    return 0
  fi
  local rc=$?
  return "${rc}"
}

log "Starting Brain Trust bootstrap"
log "Root: ${ROOT_DIR}"
log "Env: ${ENV_FILE}"
log "Record dir: ${RECORD_DIR}"
log "Mode: dry_run=${DRY_RUN}, non_interactive=${NON_INTERACTIVE}, skip_e2e=${SKIP_E2E}, local=${USE_LOCAL}"

# Load env
set +u
# shellcheck disable=SC1090
source "${ENV_FILE}"
set -u

# 1) preflight
preflight_log="${RECORD_DIR}/preflight.log"
if run_cmd_log "preflight" "${preflight_log}" openclaw --version; then
  status_preflight="complete"
else
  status_preflight="failed"
  record_failure "preflight" "openclaw --version failed"
fi

if [[ "${status_preflight}" == "complete" ]]; then
  for req in \
    "${ROOT_DIR}/scripts/validate_brain_trust_env.sh" \
    "${ROOT_DIR}/scripts/bootstrap_luban_role.sh" \
    "${ROOT_DIR}/scripts/validate_team_contract.sh" \
    "${ROOT_DIR}/scripts/sync_brain_trust_models.sh" \
    "${ROOT_DIR}/scripts/export_available_models.sh" \
    "${ROOT_DIR}/scripts/test_run_brain_trust_review_regression.sh" \
    "${ROOT_DIR}/scripts/run_brain_trust_review.sh"; do
    if [[ ! -f "${req}" ]]; then
      status_preflight="failed"
      record_failure "preflight" "missing required script: ${req}"
    fi
  done
fi

# 2) agent check/create
agents_log="${RECORD_DIR}/agents.log"
roles=(architect critic innovator pangu luban)
if [[ "${status_preflight}" != "failed" ]]; then
  if ! openclaw agents list >"${agents_log}" 2>&1; then
    status_agents="failed"
    record_failure "agents" "openclaw agents list failed"
  else
    status_agents="complete"
    agents_output="$(cat "${agents_log}")"
    for role in "${roles[@]}"; do
      workspace="${ROOT_DIR}/roles/${role}"
      if [[ "${role}" == "pangu" || "${role}" == "luban" ]]; then
        workspace="${HOME}/.openclaw/workspaces/pangu"
        if [[ "${role}" == "luban" ]]; then
          workspace="${HOME}/.openclaw/workspaces/luban"
        fi
      fi
      if [[ ! -d "${workspace}" ]]; then
        if [[ "${role}" == "pangu" || "${role}" == "luban" ]]; then
          mkdir -p "${workspace}"
          printf '[agents] created workspace: %s (%s)\n' "${role}" "${workspace}" >>"${agents_log}"
        else
          status_agents="failed"
          record_failure "agents" "missing role workspace: ${workspace}"
          continue
        fi
      fi

      if printf '%s\n' "${agents_output}" | rg -q -- "- ${role}(\s|$)"; then
        printf '[agents] exists: %s\n' "${role}" >>"${agents_log}"
      else
        if [[ "${DRY_RUN}" == "true" ]]; then
          printf '[agents] dry-run would add: %s (%s)\n' "${role}" "${workspace}" >>"${agents_log}"
          status_agents="dry_run"
        else
          add_cmd=(openclaw agents add "${role}" --workspace "${workspace}")
          if [[ "${NON_INTERACTIVE}" == "true" ]]; then
            add_cmd+=(--non-interactive)
          fi
          if "${add_cmd[@]}" >>"${agents_log}" 2>&1; then
            printf '[agents] added: %s\n' "${role}" >>"${agents_log}"
          else
            status_agents="failed"
            record_failure "agents" "failed to add role: ${role}"
          fi
        fi
      fi

      identity_file="${workspace}/IDENTITY.md"
      if [[ -f "${identity_file}" && "${DRY_RUN}" != "true" ]]; then
        if ! openclaw agents set-identity --agent "${role}" --from-identity --workspace "${workspace}" >>"${agents_log}" 2>&1; then
          record_failure "agents" "set-identity failed for role: ${role}"
          status_agents="failed"
        fi
      fi
    done
  fi
fi

# 3) env validation
validation_log="${RECORD_DIR}/validation.log"
if [[ "${status_preflight}" == "failed" ]]; then
  status_validation="failed"
  record_failure "validation" "skipped because preflight failed"
elif run_cmd_log "validation" "${validation_log}" "${ROOT_DIR}/scripts/validate_brain_trust_env.sh"; then
  status_validation="complete"
else
  status_validation="failed"
  record_failure "validation" "validate_brain_trust_env.sh failed"
fi

# 3.5) execution chain availability (Stage4)
if [[ "${status_validation}" != "complete" ]]; then
  status_execution_chain="failed"
  record_failure "execution_chain" "skipped because validation failed"
elif rg -q "run_pangu_execution" "${ROOT_DIR}/scripts/run_brain_trust_review.sh" && \
     rg -q "stage4_status" "${ROOT_DIR}/scripts/run_brain_trust_review.sh"; then
  status_execution_chain="complete"
else
  status_execution_chain="failed"
  record_failure "execution_chain" "run_brain_trust_review.sh missing Stage4 execution markers"
fi

# 3.6) luban role bootstrap
luban_bootstrap_log="${RECORD_DIR}/luban_bootstrap.log"
luban_report="${RECORD_DIR}/luban_bootstrap_report.json"
if [[ "${status_validation}" != "complete" ]]; then
  status_luban_role="failed"
  record_failure "luban" "skipped because validation failed"
else
  luban_cmd=("${ROOT_DIR}/scripts/bootstrap_luban_role.sh" --root "${ROOT_DIR}" --workspace "${HOME}/.openclaw/workspaces/luban" --report "${luban_report}")
  if [[ "${DRY_RUN}" == "true" ]]; then
    luban_cmd+=(--dry-run)
  fi
  if [[ "${NON_INTERACTIVE}" == "true" ]]; then
    luban_cmd+=(--non-interactive)
  fi
  if run_cmd_log "luban" "${luban_bootstrap_log}" "${luban_cmd[@]}"; then
    if [[ "${DRY_RUN}" == "true" ]]; then
      status_luban_role="dry_run"
    else
      status_luban_role="complete"
    fi
  else
    status_luban_role="failed"
    record_failure "luban" "bootstrap_luban_role.sh failed"
  fi
  [[ -f "${luban_report}" ]] && record_artifact "${luban_report}"
fi

# 3.7) team contract schema validation
team_contract_log="${RECORD_DIR}/team_contract_validation.log"
team_contract_dir="${HOME}/.openclaw/workspaces/luban/templates"
if [[ ! -d "${team_contract_dir}" ]]; then
  team_contract_dir="${ROOT_DIR}/roles/luban/templates"
fi
if [[ "${status_luban_role}" == "failed" ]]; then
  status_team_contract="failed"
  record_failure "team_contract" "skipped because luban bootstrap failed"
elif run_cmd_log "team_contract" "${team_contract_log}" "${ROOT_DIR}/scripts/validate_team_contract.sh" --dir "${team_contract_dir}"; then
  if [[ "${DRY_RUN}" == "true" ]]; then
    status_team_contract="dry_run"
  else
    status_team_contract="complete"
  fi
else
  status_team_contract="failed"
  record_failure "team_contract" "validate_team_contract.sh failed"
fi

# 4) model sync + inventory
sync_log="${RECORD_DIR}/model_sync.log"
model_record="${RECORD_DIR}/model_assignment_record.json"
inventory_dir="${RECORD_DIR}/model_inventory"
mkdir -p "${inventory_dir}"
if [[ "${status_validation}" != "complete" ]]; then
  status_model_sync="failed"
  record_failure "model_sync" "skipped because validation failed"
else
  if [[ "${DRY_RUN}" == "true" ]]; then
    if run_cmd_log "model_sync" "${sync_log}" "${ROOT_DIR}/scripts/sync_brain_trust_models.sh" --check-only --record "${model_record}"; then
      status_model_sync="dry_run"
    else
      sync_rc="$?"
      if [[ "${sync_rc}" -eq 2 ]]; then
        status_model_sync="dry_run"
        printf '[model_sync] dry-run mismatch detected (expected), apply is required to enforce baseline.\n' >>"${sync_log}"
      else
        status_model_sync="failed"
        record_failure "model_sync" "sync check-only failed with rc=${sync_rc}"
      fi
    fi
  else
    if run_cmd_log "model_sync" "${sync_log}" "${ROOT_DIR}/scripts/sync_brain_trust_models.sh" --apply --record "${model_record}"; then
      status_model_sync="complete"
    else
      status_model_sync="failed"
      record_failure "model_sync" "sync apply failed"
    fi
  fi

  if [[ -f "${model_record}" ]]; then
    record_artifact "${model_record}"
  fi

  if [[ "${status_model_sync}" != "failed" ]]; then
    inventory_log="${RECORD_DIR}/model_inventory.log"
    if run_cmd_log "model_inventory" "${inventory_log}" "${ROOT_DIR}/scripts/export_available_models.sh" --out "${inventory_dir}"; then
      record_artifact "${inventory_dir}/available_models.json"
      record_artifact "${inventory_dir}/available_models.md"
    else
      record_failure "model_sync" "export_available_models.sh failed"
      status_model_sync="failed"
    fi
  fi
fi

# 5) regression
regression_log="${RECORD_DIR}/regression.log"
if [[ "${status_model_sync}" == "failed" || "${status_luban_role}" == "failed" || "${status_team_contract}" == "failed" ]]; then
  status_regression="failed"
  record_failure "regression" "skipped because prerequisite failed"
elif run_cmd_log "regression" "${regression_log}" "${ROOT_DIR}/scripts/test_run_brain_trust_review_regression.sh"; then
  status_regression="complete"
else
  status_regression="failed"
  record_failure "regression" "regression script failed"
fi

# 6) e2e
if [[ "${SKIP_E2E}" == "true" ]]; then
  status_e2e="skipped"
elif [[ "${DRY_RUN}" == "true" ]]; then
  status_e2e="dry_run"
else
  e2e_dir="${RECORD_DIR}/e2e_output"
  e2e_log="${RECORD_DIR}/e2e.log"
  proposal_file="${ROOT_DIR}/02_Proposal_Submission_Template.md"
  e2e_cmd=("${ROOT_DIR}/scripts/run_brain_trust_review.sh" --proposal "${proposal_file}" --depth quick --focus "Deployment bootstrap smoke test" --out "${e2e_dir}")
  if [[ "${USE_LOCAL}" == "true" ]]; then
    e2e_cmd+=(--local)
  fi

  if run_cmd_log "e2e" "${e2e_log}" "${e2e_cmd[@]}"; then
    if [[ -f "${e2e_dir}/structured_summary.json" ]]; then
      if [[ -f "${e2e_dir}/pangu_execution_plan.md" && -f "${e2e_dir}/pangu_execution_report.md" && -f "${e2e_dir}/pangu_execution_raw.json" ]]; then
        e2e_stage4_status="$(python3 - "${e2e_dir}/structured_summary.json" <<'PY'
import json
import sys
from pathlib import Path
try:
    data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
except Exception:
    print("unknown")
    raise SystemExit(0)
print(str(data.get("orchestration", {}).get("stage4_status", "unknown")))
PY
)"
        status_e2e="complete"
      else
        status_e2e="failed"
        record_failure "e2e" "missing Stage4 output artifacts in e2e output"
      fi
      record_artifact "${e2e_dir}/structured_summary.json"
      record_artifact "${e2e_dir}/summary_report.md"
      [[ -f "${e2e_dir}/pangu_execution_plan.md" ]] && record_artifact "${e2e_dir}/pangu_execution_plan.md"
      [[ -f "${e2e_dir}/pangu_execution_report.md" ]] && record_artifact "${e2e_dir}/pangu_execution_report.md"
      [[ -f "${e2e_dir}/pangu_execution_raw.json" ]] && record_artifact "${e2e_dir}/pangu_execution_raw.json"
    else
      status_e2e="failed"
      record_failure "e2e" "missing structured_summary.json in e2e output"
    fi
  else
    status_e2e="failed"
    record_failure "e2e" "run_brain_trust_review.sh failed in e2e"
  fi
fi

# collect openclaw version for report
openclaw_version="unknown"
if command -v openclaw >/dev/null 2>&1; then
  openclaw_version="$(openclaw --version 2>/dev/null | head -n 1 | tr -d '\r')"
fi

python3 - "${REPORT_FILE}" "${release_version}" "${release_openclaw_compat}" "${openclaw_version}" "${status_preflight}" "${status_agents}" "${status_validation}" "${status_luban_role}" "${status_team_contract}" "${status_model_sync}" "${status_regression}" "${status_execution_chain}" "${status_e2e}" "${e2e_stage4_status}" "${FAILURES_FILE}" "${ARTIFACTS_FILE}" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

(
    report_path,
    release_version,
    openclaw_compat,
    openclaw_version,
    status_preflight,
    status_agents,
    status_validation,
    status_luban_role,
    status_team_contract,
    status_model_sync,
    status_regression,
    status_execution_chain,
    status_e2e,
    e2e_stage4_status,
    failures_file,
    artifacts_file,
) = sys.argv[1:]

failures = []
for line in Path(failures_file).read_text(encoding="utf-8").splitlines():
    if not line.strip() or "|" not in line:
        continue
    step, message = line.split("|", 1)
    failures.append({"step": step, "message": message})

artifacts = [x for x in Path(artifacts_file).read_text(encoding="utf-8").splitlines() if x.strip()]
if report_path not in artifacts:
    artifacts.append(report_path)

payload = {
    "timestamp": datetime.utcnow().isoformat() + "Z",
    "release_version": release_version,
    "openclaw_compatibility": openclaw_compat,
    "openclaw_version": openclaw_version,
    "preflight": {"status": status_preflight},
    "agents": {
        "status": status_agents,
        "required": ["architect", "critic", "innovator", "pangu", "luban"],
    },
    "validation": {"status": status_validation},
    "luban": {"status": status_luban_role},
    "team_contract_validation": {"status": status_team_contract},
    "model_sync": {"status": status_model_sync},
    "regression": {"status": status_regression},
    "execution_chain": {"status": status_execution_chain},
    "e2e": {"status": status_e2e, "stage4_status": e2e_stage4_status},
    "artifacts": artifacts,
    "failures": failures,
}

Path(report_path).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

log "Deployment report generated: ${REPORT_FILE}"

if [[ -s "${FAILURES_FILE}" ]]; then
  log "Bootstrap completed with failures. See report."
  exit 1
fi

log "Bootstrap completed successfully."
