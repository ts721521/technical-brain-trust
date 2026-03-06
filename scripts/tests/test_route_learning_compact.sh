#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/route_learning_compact.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

memory_dir="${tmp_dir}/memory"
mkdir -p "${memory_dir}"

cat >"${memory_dir}/ROUTING_DECISIONS.jsonl" <<'JSON'
{"intent_class":"execution_heavy","selected_agent":"pangu","result_status":"success","delivery_mode":"delegate","recovered":false,"error_code":"","queued":true,"queue_wait_ms":120,"scale_action":"none","dispatch_target":"pangu"}
{"intent_class":"execution_heavy","selected_agent":"pangu","result_status":"success","delivery_mode":"delegate","recovered":true,"error_code":"delegate_recovered","queued":true,"queue_wait_ms":80,"scale_action":"route_to_scheduler","dispatch_target":"scheduler-dev"}
{"intent_class":"install_or_check","selected_agent":"main","result_status":"success","delivery_mode":"direct","recovered":false,"error_code":"","queued":false,"queue_wait_ms":0,"scale_action":"none","dispatch_target":"main"}
JSON

json_out="${tmp_dir}/route_report.json"
md_out="${tmp_dir}/route_report.md"

"${SCRIPT}" \
  --memory-dir "${memory_dir}" \
  --window 50 \
  --report-json "${json_out}" \
  --report-md "${md_out}" >/dev/null

test -f "${memory_dir}/ROUTING_MEMORY.md"
test -f "${json_out}"
test -f "${md_out}"

python3 - "${json_out}" <<'PY'
import json
import sys
from pathlib import Path

obj = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert obj["records_used"] == 3
assert obj["delegate_metrics"]["delegate_total"] == 2
assert obj["scheduler_metrics"]["scheduler_routed_count"] >= 1
PY

echo "route_learning_compact tests passed"
