#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUN_SCRIPT="${ROOT_DIR}/scripts/run_brain_trust_review.sh"
ENV_EXAMPLE="${ROOT_DIR}/config/brain_trust.env.example"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

source "${ENV_EXAMPLE}"
mkdir -p "${tmp_dir}/docs_root"
export BT_DOCS_ROOT="${tmp_dir}/docs_root"
export BT_TEAM_ID="team-brain-trust"

yyyymm="$(date +%Y%m)"
ledger_file="${BT_DOCS_ROOT}/${BT_TEAM_ID}/ops/${yyyymm}/task_ledger.jsonl"

mkdir -p "${tmp_dir}/bin"
export PATH="${tmp_dir}/bin:${PATH}"

cat >"${tmp_dir}/bin/openclaw" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail

mode="${BT_TEST_MODE:-normal}"
state_dir="$(cd "$(dirname "$0")" && pwd)/.state"
mkdir -p "${state_dir}"

default_model_for_role() {
  local role="$1"
  case "${role}" in
    architect) echo "${BT_ARCHITECT_MODEL}" ;;
    critic) echo "${BT_CRITIC_MODEL}" ;;
    innovator) echo "${BT_INNOVATOR_MODEL}" ;;
    *) echo "zai/glm-5" ;;
  esac
}

get_current_model() {
  local role="$1"
  local file="${state_dir}/${role}.model"
  if [[ -f "${file}" ]]; then
    cat "${file}"
  else
    default_model_for_role "${role}"
  fi
}

set_current_model() {
  local role="$1"
  local model="$2"
  printf "%s\n" "${model}" >"${state_dir}/${role}.model"
}

emit_json_response() {
  local payload="$1"
  python3 - "$payload" <<'PY'
import json
import sys
print(json.dumps({"response": sys.argv[1]}, ensure_ascii=False))
PY
}

if [[ "${1:-}" == "agents" && "${2:-}" == "list" ]]; then
  cat <<'TXT'
Agents:
- architect
- critic
- innovator
- pangu
- luban
- braintrust_compliance
- wenquxing
- knowledge_manager
- rd_lead
- scholar
- feige_notifier
TXT
  exit 0
fi

if [[ "${1:-}" == "models" ]]; then
  shift
  agent="main"
  if [[ "${1:-}" == "--agent" ]]; then
    agent="${2:-}"
    shift 2
  fi
  sub="${1:-}"
  shift || true
  case "${sub}" in
    list)
      cat <<'TXT'
Model                                      Input      Ctx      Local Auth  Tags
openai-codex/gpt-5.3-codex                 text+image 266k     no    yes   configured
google-gemini-cli/gemini-3-pro-preview     text+image 1024k    no    yes   configured
google-gemini-cli/gemini-3.1-pro-preview   text+image 1024k    no    yes   configured
zai/glm-5                                  text       200k     no    yes   configured
zai/glm-4.7                                text       200k     no    yes   configured
bailian/qwen3.5-plus                       text+image 977k     no    yes   configured
bailian/qwen3-max-2026-01-23               text       256k     no    yes   configured
bailian/kimi-k2.5                          text+image 256k     no    yes   configured
TXT
      ;;
    status)
      if [[ "${1:-}" == "--plain" ]]; then
        get_current_model "${agent}"
      else
        echo "{\"resolvedDefault\":\"$(get_current_model "${agent}")\"}"
      fi
      ;;
    set)
      set_current_model "${agent}" "${1:?model required}"
      ;;
    fallbacks)
      action="${1:-}"
      case "${action}" in
        clear|add|list) exit 0 ;;
      esac
      ;;
  esac
  exit 0
fi

if [[ "${1:-}" != "agent" ]]; then
  echo "unknown command: $*" >&2
  exit 2
fi
shift

agent=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      agent="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ "${mode}" == "pangu_fail" && "${agent}" == "pangu" ]]; then
  echo "simulated pangu execution timeout" >&2
  exit 124
fi

case "${agent}" in
  architect)
    emit_json_response "$(cat <<'MD'
## 架构师审查
```json
{"role":"architect","scores":{"feasibility":9,"robustness":8,"scalability":7,"simplicity":8},"top_findings":["f1"],"top_suggestions":["s1"],"intent_alignment":{"misalignment_found":false,"evidence":"ok","correction":""},"complexity_reduction":{"reduction_required":false,"items":[],"rationale":""},"opensource_validation":[]}
```
MD
)"
    ;;
  critic)
    emit_json_response "$(cat <<'MD'
## 批判者审查
```json
{"role":"critic","scores":{"feasibility":8,"robustness":7,"risk":4},"top_findings":["f2"],"top_suggestions":["s2"],"intent_alignment":{"misalignment_found":false,"evidence":"ok","correction":""},"complexity_reduction":{"reduction_required":true,"items":["简化A"],"rationale":""},"opensource_validation":[]}
```
MD
)"
    ;;
  innovator)
    emit_json_response "$(cat <<'MD'
## 创新者审查
```json
{"role":"innovator","scores":{"feasibility":9,"scalability":8,"simplicity":7,"innovation":8},"top_findings":["f3"],"top_suggestions":["s3"],"intent_alignment":{"misalignment_found":false,"evidence":"ok","correction":""},"complexity_reduction":{"reduction_required":false,"items":[],"rationale":""},"opensource_validation":[]}
```
MD
)"
    ;;
  pangu)
    emit_json_response "$(cat <<'MD'
## 执行计划
1. 落实P0

## 执行结果
- 已完成：P0-1

```json
{"trigger_mode":"auto","scope_mode":"autonomous","implemented_items":["P0-1"],"deferred_items":[],"retryable_items":[],"failure_reason":""}
```
MD
)"
    ;;
  *)
    echo "unknown agent: ${agent}" >&2
    exit 2
    ;;
esac
FAKE
chmod +x "${tmp_dir}/bin/openclaw"

proposal_file="${tmp_dir}/proposal.md"
cat >"${proposal_file}" <<'EOF_PROPOSAL'
# Proposal
Test acceptance lifecycle writeback.
EOF_PROPOSAL

run_case() {
  local mode="$1"
  local out_dir="$2"
  local task_id="$3"

  BT_TEST_MODE="${mode}" \
  BT_SKIP_MODEL_SYNC="true" \
  BT_SKIP_DOCS_POLICY="true" \
  BT_SCHEDULER_MEMORY_DIR="${tmp_dir}/scheduler_memory" \
  BT_ROUTING_LOG_PATH="${tmp_dir}/routing_decisions.jsonl" \
  BT_TASK_ID="${task_id}" \
  "${RUN_SCRIPT}" --proposal "${proposal_file}" --out "${out_dir}" >/dev/null
}

out_ok="${tmp_dir}/out_ok"
out_fail="${tmp_dir}/out_fail"

run_case "normal" "${out_ok}" "task-accept-pass"
run_case "pangu_fail" "${out_fail}" "task-accept-blocked"

python3 - "${ledger_file}" "${out_ok}/acceptance_report.json" "${out_fail}/acceptance_report.json" <<'PY'
import json
import sys
from pathlib import Path

ledger_path = Path(sys.argv[1])
accept_ok = json.loads(Path(sys.argv[2]).read_text(encoding='utf-8'))
accept_fail = json.loads(Path(sys.argv[3]).read_text(encoding='utf-8'))

rows = [json.loads(line) for line in ledger_path.read_text(encoding='utf-8').splitlines() if line.strip()]
latest = {}
for row in rows:
    latest[row['task_id']] = row

ok = latest['task-accept-pass']
blocked = latest['task-accept-blocked']

assert ok['state'] == 'done', ok
assert blocked['state'] == 'in_progress', blocked
assert blocked['error_code'] == 'acceptance_blocked', blocked
assert blocked.get('reopen_actions'), blocked

assert accept_ok['status'] == 'pass', accept_ok
assert accept_fail['status'] == 'blocked', accept_fail
PY

echo "acceptance gate tests passed"
