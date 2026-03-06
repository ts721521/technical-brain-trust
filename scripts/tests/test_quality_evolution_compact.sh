#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/quality_evolution_compact.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

export BT_DOCS_ROOT="${tmp_dir}/docs"
mkdir -p "${BT_DOCS_ROOT}/team-knowledge/review/202603" "${BT_DOCS_ROOT}/team-rd/review/202603"

cat >"${BT_DOCS_ROOT}/team-knowledge/review/202603/quality_improvement_log.jsonl" <<'JSON'
{"period":"2026-03","team_id":"team-knowledge","baseline_metrics":{"final_score":8.2},"issues_topn":["stage4 execution proof not passed"],"improvement_actions":["补齐证据"],"experiment_result":"blocked","timestamp":"2026-03-07T01:00:00+00:00"}
{"period":"2026-03","team_id":"team-knowledge","baseline_metrics":{"final_score":9.1},"issues_topn":[],"improvement_actions":[],"experiment_result":"pass","timestamp":"2026-03-07T02:00:00+00:00"}
JSON

cat >"${BT_DOCS_ROOT}/team-rd/review/202603/quality_improvement_log.jsonl" <<'JSON'
{"period":"2026-03","team_id":"team-rd","baseline_metrics":{"final_score":8.8},"issues_topn":[],"improvement_actions":[],"experiment_result":"pass","timestamp":"2026-03-07T03:00:00+00:00"}
JSON

"${SCRIPT}" \
  --docs-root "${BT_DOCS_ROOT}" \
  --team "team-brain-trust" \
  --teams "team-knowledge,team-rd" \
  --window-days 365 \
  --slot-time 050000 >/dev/null

yyyymm="$(date +%Y%m)"
run_date="$(date +%Y%m%d)"
json_file="${BT_DOCS_ROOT}/team-brain-trust/ops/${yyyymm}/quality_evolution_report-${run_date}-050000.json"
md_file="${BT_DOCS_ROOT}/team-brain-trust/ops/${yyyymm}/quality_evolution_report-${run_date}-050000.md"
test -f "${json_file}"
test -f "${md_file}"

python3 - "${json_file}" <<'PY'
import json
import sys
from pathlib import Path

obj = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert obj["global"]["entries"] == 3
assert obj["global"]["blocked"] == 1
teams = {x["team"]: x for x in obj["teams"]}
assert teams["team-knowledge"]["blocked_rate"] == 0.5
assert teams["team-rd"]["blocked_rate"] == 0.0
PY

echo "quality_evolution_compact tests passed"
