#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_ID="luban"
WORKSPACE="${HOME}/.openclaw/workspaces/luban"
REPORT_PATH="/tmp/luban_bootstrap_report.json"
DRY_RUN="false"
NON_INTERACTIVE="false"

usage() {
  cat <<'EOF'
Usage: bootstrap_luban_role.sh [options]

Options:
  --root <abs_path>         Project root (default: script parent root)
  --workspace <abs_path>    LuBan workspace path (default: ~/.openclaw/workspaces/luban)
  --report <abs_path>       Output report json (default: <docs_root>/team-brain-trust/ops/<yyyymm>/luban-bootstrap-<ts>.json)
  --dry-run                 Print intended actions only
  --non-interactive         Pass --non-interactive when adding agent
  -h, --help                Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT_DIR="${2:-}"
      shift 2
      ;;
    --workspace)
      WORKSPACE="${2:-}"
      shift 2
      ;;
    --report)
      REPORT_PATH="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "${REPORT_PATH}" == "/tmp/luban_bootstrap_report.json" ]]; then
  docs_root="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
  team_id="${BT_TEAM_ID:-team-brain-trust}"
  yyyymm="$(date +%Y%m)"
  ts="$(date +%Y%m%d-%H%M%S)"
  REPORT_PATH="${docs_root}/${team_id}/ops/${yyyymm}/luban-bootstrap-${ts}.json"
fi

mkdir -p "$(dirname "${REPORT_PATH}")"

ROLE_DIR="${ROOT_DIR}/roles/luban"
for f in IDENTITY.md SOUL.md AGENTS.md TOOLS.md templates/team_blueprint.md templates/team_agent_contract.json templates/team_model_assignment.json; do
  if [[ ! -f "${ROLE_DIR}/${f}" ]]; then
    echo "missing template file: ${ROLE_DIR}/${f}" >&2
    exit 1
  fi
done

status_agent="pending"
status_workspace="pending"
status_identity="pending"
status_templates="pending"
failures=()

add_failure() {
  failures+=("$1")
}

copy_file() {
  local src="$1"
  local dst="$2"
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] cp -f ${src} ${dst}"
    return 0
  fi
  cp -f "${src}" "${dst}"
}

mkdir_safe() {
  local d="$1"
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] mkdir -p ${d}"
  else
    mkdir -p "${d}"
  fi
}

if [[ "${DRY_RUN}" == "true" ]]; then
  status_workspace="dry_run"
else
  status_workspace="complete"
fi

mkdir_safe "${WORKSPACE}"
mkdir_safe "${WORKSPACE}/memory"
mkdir_safe "${WORKSPACE}/templates"

copy_file "${ROLE_DIR}/IDENTITY.md" "${WORKSPACE}/IDENTITY.md"
copy_file "${ROLE_DIR}/SOUL.md" "${WORKSPACE}/SOUL.md"
copy_file "${ROLE_DIR}/AGENTS.md" "${WORKSPACE}/AGENTS.md"
copy_file "${ROLE_DIR}/TOOLS.md" "${WORKSPACE}/TOOLS.md"

copy_file "${ROLE_DIR}/templates/team_blueprint.md" "${WORKSPACE}/templates/team_blueprint.md"
copy_file "${ROLE_DIR}/templates/team_agent_contract.json" "${WORKSPACE}/templates/team_agent_contract.json"
copy_file "${ROLE_DIR}/templates/team_model_assignment.json" "${WORKSPACE}/templates/team_model_assignment.json"

if [[ "${DRY_RUN}" != "true" ]]; then
  [[ -f "${WORKSPACE}/memory/TEAM_BLUEPRINTS.jsonl" ]] || : > "${WORKSPACE}/memory/TEAM_BLUEPRINTS.jsonl"
  [[ -f "${WORKSPACE}/memory/ARCH_DECISIONS.jsonl" ]] || : > "${WORKSPACE}/memory/ARCH_DECISIONS.jsonl"
  if [[ ! -f "${WORKSPACE}/memory/SYSTEM_MAP.md" ]]; then
    cat > "${WORKSPACE}/memory/SYSTEM_MAP.md" <<'EOF'
# SYSTEM_MAP

LuBan 维护系统架构与团队映射摘要。
EOF
  fi
fi

if [[ "${DRY_RUN}" == "true" ]]; then
  status_templates="dry_run"
else
  status_templates="complete"
fi

agents_output="$(openclaw agents list 2>/dev/null || true)"
if printf '%s\n' "${agents_output}" | rg -q -- "- ${AGENT_ID}(\\s|$)"; then
  status_agent="exists"
else
  if [[ "${DRY_RUN}" == "true" ]]; then
    status_agent="dry_run"
  else
    cmd=(openclaw agents add "${AGENT_ID}" --workspace "${WORKSPACE}")
    if [[ "${NON_INTERACTIVE}" == "true" ]]; then
      cmd+=(--non-interactive)
    fi
    if "${cmd[@]}" >/dev/null 2>&1; then
      status_agent="created"
    else
      status_agent="failed"
      add_failure "failed to add luban agent"
    fi
  fi
fi

if [[ "${DRY_RUN}" == "true" ]]; then
  status_identity="dry_run"
elif [[ "${status_agent}" == "failed" ]]; then
  status_identity="skipped"
else
  if openclaw agents set-identity --agent "${AGENT_ID}" --from-identity --workspace "${WORKSPACE}" >/dev/null 2>&1; then
    status_identity="complete"
  else
    status_identity="failed"
    add_failure "set-identity failed for luban"
  fi
fi

python3 - "${REPORT_PATH}" "${status_agent}" "${status_workspace}" "${status_identity}" "${status_templates}" "${WORKSPACE}" <<'PY'
import json
import sys
from datetime import datetime

report, status_agent, status_workspace, status_identity, status_templates, workspace = sys.argv[1:]
payload = {
    "generated_at": datetime.utcnow().isoformat() + "Z",
    "agent_id": "luban",
    "workspace": workspace,
    "status": {
        "agent": status_agent,
        "workspace": status_workspace,
        "identity": status_identity,
        "templates": status_templates,
    }
}
with open(report, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
print(json.dumps(payload, ensure_ascii=False, indent=2))
PY

if (( ${#failures[@]} > 0 )); then
  printf 'bootstrap_luban_role failed:\n' >&2
  printf '  - %s\n' "${failures[@]}" >&2
  exit 1
fi

echo "bootstrap_luban_role completed: ${REPORT_PATH}"
