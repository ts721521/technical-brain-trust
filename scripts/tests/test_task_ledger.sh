#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LEDGER_SCRIPT="${ROOT_DIR}/scripts/task_ledger.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

export BT_DOCS_ROOT="${tmp_dir}/docs"
export BT_TEAM_ID="team-brain-trust"
yyyymm="$(date +%Y%m)"
ledger_file="${BT_DOCS_ROOT}/${BT_TEAM_ID}/ops/${yyyymm}/task_ledger.jsonl"

"${LEDGER_SCRIPT}" create --task-id t1 --team proposal --title "方案A" --owner proposal_lead >/dev/null
"${LEDGER_SCRIPT}" transition --task-id t1 --to assigned >/dev/null
"${LEDGER_SCRIPT}" transition --task-id t1 --to in_progress >/dev/null
"${LEDGER_SCRIPT}" transition --task-id t1 --to review >/dev/null
"${LEDGER_SCRIPT}" transition --task-id t1 --to acceptance >/dev/null
"${LEDGER_SCRIPT}" transition --task-id t1 --to done >/dev/null

python3 - "${ledger_file}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
rows = [json.loads(line) for line in path.read_text(encoding='utf-8').splitlines() if line.strip()]
assert rows[-1]["task_id"] == "t1"
assert rows[-1]["state"] == "done"
PY

"${LEDGER_SCRIPT}" create --task-id t2 --team rd --title "实现B" --owner rd_lead >/dev/null
"${LEDGER_SCRIPT}" transition --task-id t2 --to assigned >/dev/null
"${LEDGER_SCRIPT}" transition --task-id t2 --to in_progress >/dev/null
"${LEDGER_SCRIPT}" transition --task-id t2 --to review >/dev/null
"${LEDGER_SCRIPT}" transition --task-id t2 --to acceptance >/dev/null
"${LEDGER_SCRIPT}" transition --task-id t2 --to in_progress --reason "acceptance blocked" --error-code "acceptance_blocked" --reopen-actions '["补齐测试","补齐证据"]' >/dev/null

python3 - "${LEDGER_SCRIPT}" <<'PY'
import json
import subprocess
import sys

script = sys.argv[1]
out = subprocess.check_output([script, "get", "--task-id", "t2"], text=True)
obj = json.loads(out)
assert obj["state"] == "in_progress"
assert obj["previous_state"] == "acceptance"
assert obj["error_code"] == "acceptance_blocked"
assert len(obj.get("reopen_actions", [])) == 2
PY

if "${LEDGER_SCRIPT}" transition --task-id t2 --to done >/dev/null 2>&1; then
  echo "expected invalid transition to fail (in_progress -> done)" >&2
  exit 1
fi

python3 - "${LEDGER_SCRIPT}" <<'PY'
import json
import subprocess
import sys

script = sys.argv[1]
out = subprocess.check_output([script, "list"], text=True)
arr = json.loads(out)
assert len(arr) == 2
states = {item["task_id"]: item["state"] for item in arr}
assert states["t1"] == "done"
assert states["t2"] == "in_progress"
PY

echo "task_ledger tests passed"
