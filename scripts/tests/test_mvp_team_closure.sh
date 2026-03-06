#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/run_mvp_team_closure.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

export BT_DOCS_ROOT="${tmp_dir}/docs"
mkdir -p "${BT_DOCS_ROOT}"

"${SCRIPT}" --docs-root "${BT_DOCS_ROOT}" --teams "team-knowledge,team-rd,team-smart3d" --tasks-per-team 2 >/dev/null

yyyymm="$(date +%Y%m)"
summary_file="$(ls -1 "${BT_DOCS_ROOT}/team-brain-trust/ops/${yyyymm}"/mvp_team_closure_report-*.json | tail -n 1)"
test -f "${summary_file}"

for t in team-knowledge team-rd team-smart3d; do
  test -f "${BT_DOCS_ROOT}/${t}/ops/${yyyymm}/task_ledger.jsonl"
  count="$(ls -1 "${BT_DOCS_ROOT}/${t}/evidence/${yyyymm}"/acceptance_report-mvp-${t}-*.json | wc -l | tr -d ' ')"
  [[ "${count}" == "2" ]]
done

python3 - "${summary_file}" <<'PY'
import json
import sys
from pathlib import Path

obj = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
assert obj['all_closure_ok'] is True
assert len(obj['teams']) == 3
expected_owners = {
    "team-knowledge": "scholar",
    "team-rd": "rd_lead",
    "team-smart3d": "smart3d_lead",
}
for team in obj['teams']:
    assert team['target_tasks'] == 2
    assert team['done_tasks'] == 2
    assert team['closure_ok'] is True
    assert team['owner'] == expected_owners[team['team']]
PY

echo "mvp_team_closure tests passed"
