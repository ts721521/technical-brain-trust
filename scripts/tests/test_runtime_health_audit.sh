#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/runtime_health_audit.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/bin"
export PATH="${tmp_dir}/bin:${PATH}"

cat >"${tmp_dir}/bin/openclaw" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "agents" && "${2:-}" == "list" && "${3:-}" == "--json" ]]; then
  cat <<'JSON'
[
  {"id":"main","model":"google-gemini-cli/gemini-3.1-pro-preview"},
  {"id":"architect","model":"google-gemini-cli/gemini-3.1-pro-preview"},
  {"id":"critic","model":"google-gemini-cli/gemini-3.1-pro-preview"},
  {"id":"innovator","model":"google-gemini-cli/gemini-3.1-pro-preview"},
  {"id":"pangu","model":"bailian/qwen3-coder-plus"},
  {"id":"scholar","model":"zai/glm-5"},
  {"id":"feige_notifier","model":"google-gemini-cli/gemini-2.0-flash"}
]
JSON
  exit 0
fi

if [[ "${1:-}" == "status" && "${2:-}" == "--json" ]]; then
  cat <<'JSON'
{
  "ok": true,
  "agents": {
    "bootstrapPendingCount": 2,
    "agents": [
      {"id":"main","bootstrapPending":true},
      {"id":"pangu","bootstrapPending":true},
      {"id":"scholar","bootstrapPending":false}
    ]
  }
}
JSON
  exit 0
fi

if [[ "${1:-}" == "security" && "${2:-}" == "audit" && "${3:-}" == "--json" ]]; then
  cat <<'JSON'
{"summary":{"critical":1,"warn":1,"info":0},"findings":[]}
JSON
  exit 0
fi

if [[ "${1:-}" == "cron" && "${2:-}" == "list" && "${3:-}" == "--json" ]]; then
  cat <<'JSON'
{"jobs":[{"id":"j1","name":"job1","enabled":true,"state":{"lastDeliveryStatus":"not-delivered"}}]}
JSON
  exit 0
fi

if [[ "${1:-}" == "models" && "${2:-}" == "status" ]]; then
  echo "openai-codex/gpt-5.3-codex"
  exit 0
fi

if [[ "${1:-}" == "models" && "${2:-}" == "fallbacks" && "${3:-}" == "list" ]]; then
  cat <<'TXT'
Fallbacks (3):
- zai/glm-5
- google-gemini-cli/gemini-3.1-pro-preview
- bailian/qwen3.5-plus
TXT
  exit 0
fi

if [[ "${1:-}" == "models" && "${2:-}" == "list" ]]; then
  cat <<'TXT'
openai-codex/gpt-5.3-codex
zai/glm-5
google-gemini-cli/gemini-3.1-pro-preview
bailian/qwen3.5-plus
google-gemini-cli/gemini-3-pro-preview
bailian/qwen3-max-2026-01-23
zai/glm-4.7
bailian/kimi-k2.5
bailian/qwen3-coder-plus
google-gemini-cli/gemini-2.0-flash
TXT
  exit 0
fi

if [[ "${1:-}" == "config" && "${2:-}" == "get" && "${3:-}" == "channels.telegram.allowFrom" ]]; then
  echo '["6405799758"]'
  exit 0
fi

if [[ "${1:-}" == "message" && "${2:-}" == "send" ]]; then
  echo '{"ok":true}'
  exit 0
fi

echo "unsupported: $*" >&2
exit 1
FAKE
chmod +x "${tmp_dir}/bin/openclaw"

export BT_DOCS_ROOT="${tmp_dir}/docs"
mkdir -p "${BT_DOCS_ROOT}"
export BT_TEAM_ID="team-brain-trust"
export BT_QUEUE_STATE_FILE="${tmp_dir}/queue_state.json"
export BT_RUN_ROUTE_COMPACT="false"

yyyymm="$(date +%Y%m)"
run_date="$(date +%Y%m%d)"
qmd_dir="${BT_DOCS_ROOT}/${BT_TEAM_ID}/custom-learning/${yyyymm}"
mkdir -p "${qmd_dir}"
cat >"${qmd_dir}/qmd_sync_report-${run_date}-040013.json" <<'JSON'
{
  "generated_at": "2026-03-07T04:00:13+08:00",
  "sync_status": "degraded",
  "degraded_reason": "Learning artifacts path not in QMD collection monitoring"
}
JSON

cat >"${BT_QUEUE_STATE_FILE}" <<'JSON'
{"items":[{"status":"failed"},{"status":"queued"}]}
JSON

"${SCRIPT}" --slot-time 050000 --notify true >/dev/null

base="${BT_DOCS_ROOT}/${BT_TEAM_ID}/ops/${yyyymm}"

for f in \
  "runtime_health_report-${run_date}-050000.json" \
  "agent_model_inventory-${run_date}-050000.md" \
  "team_topology-${run_date}-050000.md" \
  "improvement_backlog-${run_date}-050000.md" \
  "runtime_executive_summary-${run_date}-050000.md" \
  "quality_evolution_report-${run_date}-050000.json" \
  "quality_evolution_report-${run_date}-050000.md" \
  "runtime_trend_report-${run_date}-050000.json" \
  "runtime_trend_report-${run_date}-050000.md" \
  "backlog_sync_report-${run_date}-050000.json" \
  "task_ledger_audit_report-${run_date}-050000.json"; do
  test -f "${base}/${f}"
done

python3 - "${base}/runtime_health_report-${run_date}-050000.json" <<'PY'
import json
import sys
from pathlib import Path

obj = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
assert obj['security_summary']['critical'] == 1
assert obj['queue_summary']['failed_total'] == 1
assert obj['queue_summary']['failed_recent'] in (0, 1)
assert obj['queue_summary']['pending'] == 1
assert obj['agent_bootstrap']['pending_count_raw'] == 2
assert obj['agent_bootstrap']['pending_count_actionable'] == 2
assert 'main' in obj['agent_bootstrap']['pending_agents_raw']
assert obj['quality_evolution']['status'] in ('generated', 'parse_failed')
assert obj['route_learning']['status'] == 'skipped'
assert obj['backlog_sync']['status'] == 'generated'
assert obj['backlog_sync']['summary']['created_count'] >= 1
assert obj['task_ledger_audit']['status'] == 'generated'
assert obj['trend']['status'] in ('no_baseline','stable','improving','worsening','mixed')
assert obj['qmd_sync']['status'] == 'degraded'
assert any("QMD 同步状态=degraded" in x for x in (obj.get('improvement_backlog', {}).get('p1', []) or []))
assert 'improvement_backlog' in obj
PY

rg -n "Overall health|Key Metrics|Lifecycle Audits|Action List|Runtime trend" "${base}/runtime_executive_summary-${run_date}-050000.md" >/dev/null
rg -n "Trend status|Metric|Notes" "${base}/runtime_trend_report-${run_date}-050000.md" >/dev/null

echo "runtime_health_audit tests passed"
