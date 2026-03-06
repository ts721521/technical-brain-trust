#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_ROOT="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
TEAM_ID="${BT_TEAM_ID:-team-brain-trust}"
INSTALL_CRON="true"
AUDIT_TEAMS_CSV="${BT_AUDIT_TEAMS_CSV:-team-brain-trust,team-knowledge,team-rd,team-smart3d,team-proposal}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--docs-root <path>] [--team <team-id>] [--install-cron true|false]

Phase2 convergence actions:
1) Calibrate role model chains (architect/critic/innovator + pangu/scholar/feige_notifier)
2) Apply minimum security baseline (telegram group allowlist + gateway auth token)
3) Restart gateway and run runtime audit
4) Optionally install daily 05:00 runtime audit cron
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --docs-root)
      DOCS_ROOT="${2:-}"
      shift 2
      ;;
    --team)
      TEAM_ID="${2:-}"
      shift 2
      ;;
    --install-cron)
      INSTALL_CRON="${2:-}"
      shift 2
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

if [[ ! -d "${DOCS_ROOT}" || ! -w "${DOCS_ROOT}" ]]; then
  echo "docs root unavailable or not writable: ${DOCS_ROOT}" >&2
  exit 1
fi

if [[ -f "${ROOT_DIR}/config/brain_trust.env" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/config/brain_trust.env"
else
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/config/brain_trust.env.example"
fi

require_model() {
  local model="$1"
  openclaw models list | awk '{print $1}' | grep -qx "${model}" || {
    echo "Unavailable model: ${model}" >&2
    exit 1
  }
}

set_global_baseline_chain() {
  local primary="$1"
  shift
  local fallbacks=("$@")

  openclaw models set "${primary}" >/dev/null
  openclaw models fallbacks clear >/dev/null
  local fb
  for fb in "${fallbacks[@]}"; do
    [[ -n "${fb}" ]] || continue
    openclaw models fallbacks add "${fb}" >/dev/null
  done
}

summary_before="$(openclaw security audit --json)"

architect_primary="${BT_ARCHITECT_MODEL}"
architect_fallbacks=(
  "${BT_ARCHITECT_FALLBACK_1}"
  "${BT_ARCHITECT_FALLBACK_2}"
  "${BT_ARCHITECT_FALLBACK_3}"
)
critic_primary="${BT_CRITIC_MODEL}"
critic_fallbacks=(
  "${BT_CRITIC_FALLBACK_1}"
  "${BT_CRITIC_FALLBACK_2}"
  "${BT_CRITIC_FALLBACK_3}"
)
innovator_primary="${BT_INNOVATOR_MODEL}"
innovator_fallbacks=(
  "${BT_INNOVATOR_FALLBACK_1}"
  "${BT_INNOVATOR_FALLBACK_2}"
  "${BT_INNOVATOR_FALLBACK_3}"
)
pangu_primary="${BT_PANGU_MODEL:-bailian/qwen3-coder-plus}"
pangu_fallbacks=(
  "${BT_PANGU_FALLBACK_1:-openai-codex/gpt-5.3-codex}"
  "${BT_PANGU_FALLBACK_2:-zai/glm-5}"
  "${BT_PANGU_FALLBACK_3:-bailian/qwen3.5-plus}"
)
scholar_primary="${BT_SCHOLAR_MODEL:-zai/glm-5}"
scholar_fallbacks=(
  "${BT_SCHOLAR_FALLBACK_1:-openai-codex/gpt-5.3-codex}"
  "${BT_SCHOLAR_FALLBACK_2:-google-gemini-cli/gemini-3.1-pro-preview}"
  "${BT_SCHOLAR_FALLBACK_3:-bailian/qwen3.5-plus}"
)
feige_primary="${BT_FEIGE_MODEL:-google-gemini-cli/gemini-2.0-flash}"
feige_fallbacks=(
  "${BT_FEIGE_FALLBACK_1:-bailian/qwen3.5-plus}"
  "${BT_FEIGE_FALLBACK_2:-openai-codex/gpt-5.3-codex}"
  "${BT_FEIGE_FALLBACK_3:-zai/glm-5}"
)

for m in \
  "${architect_primary}" "${architect_fallbacks[@]}" \
  "${critic_primary}" "${critic_fallbacks[@]}" \
  "${innovator_primary}" "${innovator_fallbacks[@]}" \
  "${pangu_primary}" "${pangu_fallbacks[@]}" \
  "${scholar_primary}" "${scholar_fallbacks[@]}" \
  "${feige_primary}" "${feige_fallbacks[@]}"; do
  require_model "${m}"
done

# OpenClaw defaults are global. Calibrate baseline to architect chain;
# per-role switching is applied at execution time by run_brain_trust_review.sh.
set_global_baseline_chain "${architect_primary}" "${architect_fallbacks[@]}"

# Security baseline
allow_from_json="$(openclaw config get channels.telegram.allowFrom --json 2>/dev/null || echo '[]')"
openclaw config set channels.telegram.groupPolicy '"allowlist"' --strict-json >/dev/null
openclaw config set channels.telegram.groupAllowFrom "${allow_from_json}" --strict-json >/dev/null

if ! openclaw config get gateway.auth.token --json >/dev/null 2>&1; then
  gateway_token="$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(32))
PY
)"
  openclaw config set gateway.auth.token "\"${gateway_token}\"" --strict-json >/dev/null
fi

openclaw gateway restart >/dev/null

summary_after="$(openclaw security audit --json)"

if [[ "${INSTALL_CRON}" == "true" ]]; then
  "${ROOT_DIR}/scripts/install_runtime_audit_cron.sh" --docs-root "${DOCS_ROOT}" --team "${TEAM_ID}" --notify true >/dev/null
fi

yyyymm="$(date +%Y%m)"
ts="$(date +%Y%m%d-%H%M%S)"
out_dir="${DOCS_ROOT}/${TEAM_ID}/ops/${yyyymm}"
mkdir -p "${out_dir}"
record_file="${out_dir}/runtime_convergence_record-${ts}.json"

# Ensure cross-team task ledgers exist for runtime audit contract.
IFS=',' read -r -a audit_teams <<< "${AUDIT_TEAMS_CSV}"
for t in "${audit_teams[@]}"; do
  t="$(echo "${t}" | xargs)"
  [[ -n "${t}" ]] || continue
  ledger_dir="${DOCS_ROOT}/${t}/ops/${yyyymm}"
  mkdir -p "${ledger_dir}"
  touch "${ledger_dir}/task_ledger.jsonl"
done

"${ROOT_DIR}/scripts/runtime_health_audit.sh" --docs-root "${DOCS_ROOT}" --team "${TEAM_ID}" --slot-time 050000 --notify true >/dev/null

python3 - "${record_file}" "${summary_before}" "${summary_after}" \
  "${architect_primary}" "$(printf "%s\n" "${architect_fallbacks[@]}")" \
  "${critic_primary}" "$(printf "%s\n" "${critic_fallbacks[@]}")" \
  "${innovator_primary}" "$(printf "%s\n" "${innovator_fallbacks[@]}")" \
  "${pangu_primary}" "$(printf "%s\n" "${pangu_fallbacks[@]}")" \
  "${scholar_primary}" "$(printf "%s\n" "${scholar_fallbacks[@]}")" \
  "${feige_primary}" "$(printf "%s\n" "${feige_fallbacks[@]}")" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

record_file = Path(sys.argv[1])
before = json.loads(sys.argv[2])
after = json.loads(sys.argv[3])
architect_primary = sys.argv[4]
architect_fallbacks = [x for x in sys.argv[5].splitlines() if x.strip()]
critic_primary = sys.argv[6]
critic_fallbacks = [x for x in sys.argv[7].splitlines() if x.strip()]
innovator_primary = sys.argv[8]
innovator_fallbacks = [x for x in sys.argv[9].splitlines() if x.strip()]
pangu_primary = sys.argv[10]
pangu_fallbacks = [x for x in sys.argv[11].splitlines() if x.strip()]
scholar_primary = sys.argv[12]
scholar_fallbacks = [x for x in sys.argv[13].splitlines() if x.strip()]
feige_primary = sys.argv[14]
feige_fallbacks = [x for x in sys.argv[15].splitlines() if x.strip()]

payload = {
    "timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "phase": "phase2_runtime_convergence",
    "model_semantics": {
        "default_scope": "global",
        "runtime_switching": "role-specific chain is applied by run_brain_trust_review.sh",
    },
    "target_role_chains": {
        "architect": {"primary": architect_primary, "fallbacks": architect_fallbacks},
        "critic": {"primary": critic_primary, "fallbacks": critic_fallbacks},
        "innovator": {"primary": innovator_primary, "fallbacks": innovator_fallbacks},
        "pangu": {"primary": pangu_primary, "fallbacks": pangu_fallbacks},
        "scholar": {"primary": scholar_primary, "fallbacks": scholar_fallbacks},
        "feige_notifier": {"primary": feige_primary, "fallbacks": feige_fallbacks},
    },
    "security_before": before.get("summary", {}),
    "security_after": after.get("summary", {}),
    "notes": [
        "global baseline calibrated to architect chain",
        "role target chains recorded for runtime switching",
        "telegram groupPolicy switched to allowlist",
        "gateway auth token ensured",
        "daily 05:00 runtime audit cron installed",
    ],
}
record_file.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

if [[ -x "${ROOT_DIR}/scripts/register_artifact_index.sh" ]]; then
  "${ROOT_DIR}/scripts/register_artifact_index.sh" \
    --docs-root "${DOCS_ROOT}" \
    --team "${TEAM_ID}" \
    --artifact "ops" \
    --topic "phase2-runtime-convergence" \
    --path "${record_file}" \
    --producer-script "phase2_runtime_convergence.sh" \
    --status "generated" >/dev/null || true
fi

echo "phase2 runtime convergence completed"
echo "record: ${record_file}"
