#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/audit_task_ledger_sla.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

docs_root="${tmp_dir}/docs"
yyyymm="$(date +%Y%m)"
mkdir -p "${docs_root}/team-a/ops/${yyyymm}" "${docs_root}/team-b/ops/${yyyymm}"

cat >"${docs_root}/team-a/ops/${yyyymm}/task_ledger.jsonl" <<'JSON'
{"timestamp":"2020-01-01T00:00:00+00:00","action":"create","task_id":"a-1","team":"team-a","title":"A1","owner":"alice","state":"published","previous_state":"","reason":"","error_code":"","reopen_actions":[]}
{"timestamp":"2020-01-01T01:00:00+00:00","action":"transition","task_id":"a-1","team":"team-a","title":"A1","owner":"alice","state":"in_progress","previous_state":"published","reason":"start","error_code":"","reopen_actions":[]}
{"timestamp":"2020-01-01T01:00:00+00:00","action":"create","task_id":"a-2","team":"team-a","title":"A2","owner":"alice","state":"done","previous_state":"","reason":"","error_code":"","reopen_actions":[]}
JSON

cat >"${docs_root}/team-b/ops/${yyyymm}/task_ledger.jsonl" <<'JSON'
{"timestamp":"2020-01-01T00:00:00+00:00","action":"create","task_id":"b-1","team":"team-b","title":"B1","owner":"bob","state":"review","previous_state":"in_progress","reason":"pending","error_code":"","reopen_actions":[]}
JSON

out_report="${tmp_dir}/ledger_audit_report.json"
"${SCRIPT}" \
  --docs-root "${docs_root}" \
  --teams "team-a,team-b,team-missing" \
  --yyyymm "${yyyymm}" \
  --stale-hours 1 \
  --out-report "${out_report}" >/dev/null

python3 - "${out_report}" <<'PY'
import json
import sys
from pathlib import Path

obj = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert obj["summary"]["teams_count"] == 3
assert obj["summary"]["open_total"] >= 2
assert obj["summary"]["stale_total"] >= 2
assert "team-missing" in obj["summary"]["missing_ledgers"]
teams = {x["team"]: x for x in obj["teams"]}
assert teams["team-a"]["open_count"] >= 1
assert teams["team-b"]["stale_count"] >= 1
PY

echo "audit_task_ledger_sla tests passed"
