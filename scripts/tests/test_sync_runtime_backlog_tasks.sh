#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/sync_runtime_backlog_tasks.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

docs_root="${tmp_dir}/docs"
team_id="team-brain-trust"
yyyymm="$(date +%Y%m)"
ops_dir="${docs_root}/${team_id}/ops/${yyyymm}"
mkdir -p "${ops_dir}"

runtime_json="${ops_dir}/runtime_health_report.json"
cat >"${runtime_json}" <<'JSON'
{
  "improvement_backlog": {
    "p0": ["修复执行超时重试链路"],
    "p1": ["补齐路由报告可视化"]
  }
}
JSON

ledger="${ops_dir}/task_ledger.jsonl"
report="${ops_dir}/backlog_sync_report.json"

"${SCRIPT}" \
  --runtime-report "${runtime_json}" \
  --docs-root "${docs_root}" \
  --team "${team_id}" \
  --yyyymm "${yyyymm}" \
  --owner "pangu" \
  --ledger "${ledger}" \
  --out-report "${report}" >/dev/null

python3 - "${report}" "${ledger}" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
rows = [json.loads(x) for x in Path(sys.argv[2]).read_text(encoding="utf-8").splitlines() if x.strip()]

assert report["summary"]["created_count"] == 2
assert report["summary"]["failed_count"] == 0
assert len(rows) == 2
assert all(r["state"] == "published" for r in rows)
PY

"${SCRIPT}" \
  --runtime-report "${runtime_json}" \
  --docs-root "${docs_root}" \
  --team "${team_id}" \
  --yyyymm "${yyyymm}" \
  --owner "pangu" \
  --ledger "${ledger}" \
  --out-report "${report}" >/dev/null

python3 - "${report}" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["summary"]["created_count"] == 0
assert report["summary"]["skipped_count"] == 2
PY

echo "sync_runtime_backlog_tasks tests passed"
