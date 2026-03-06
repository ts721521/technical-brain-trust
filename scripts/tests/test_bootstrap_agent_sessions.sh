#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/bootstrap_agent_sessions.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/bin" "${tmp_dir}/docs"
export PATH="${tmp_dir}/bin:${PATH}"

cat >"${tmp_dir}/bin/openclaw" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "agents" && "${2:-}" == "list" && "${3:-}" == "--json" ]]; then
  cat <<'JSON'
[
  {"id":"main"},
  {"id":"pangu"},
  {"id":"braintrust"}
]
JSON
  exit 0
fi

if [[ "${1:-}" == "agent" ]]; then
  agent_id=""
  while [[ $# -gt 0 ]]; do
    if [[ "${1}" == "--agent" ]]; then
      agent_id="${2:-}"
      shift 2
      continue
    fi
    shift
  done
  if [[ "${agent_id}" == "main" ]]; then
    echo '{"ok":true,"agent":"main"}'
    exit 0
  fi
  if [[ "${agent_id}" == "pangu" ]]; then
    echo "simulated failure for pangu" >&2
    exit 1
  fi
  echo '{"ok":true}'
  exit 0
fi

echo "unsupported: $*" >&2
exit 1
FAKE
chmod +x "${tmp_dir}/bin/openclaw"

report_file="${tmp_dir}/docs/bootstrap_report.json"
"${SCRIPT}" \
  --docs-root "${tmp_dir}/docs" \
  --team "team-brain-trust" \
  --agents "main,pangu,missing" \
  --timeout-seconds 10 \
  --report-file "${report_file}" \
  --strict false >/dev/null

python3 - "${report_file}" <<'PY'
import json
import sys
from pathlib import Path

obj = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert obj["summary"]["success_count"] == 1
assert obj["summary"]["failed_count"] == 1
assert obj["summary"]["skipped_count"] == 1
statuses = {x["agent_id"]: x["status"] for x in obj["results"]}
assert statuses["main"] == "ok"
assert statuses["pangu"] == "failed"
assert statuses["missing"] == "skipped_missing_agent"
PY

if "${SCRIPT}" \
  --docs-root "${tmp_dir}/docs" \
  --team "team-brain-trust" \
  --agents "pangu" \
  --timeout-seconds 10 \
  --report-file "${tmp_dir}/docs/bootstrap_report_strict.json" \
  --strict true >/dev/null 2>&1; then
  echo "strict mode should fail when target agent run fails" >&2
  exit 1
fi

echo "bootstrap_agent_sessions tests passed"
