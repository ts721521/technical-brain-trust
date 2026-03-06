#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_SCRIPT="${ROOT_DIR}/scripts/run_brain_trust_review.sh"
ENV_EXAMPLE="${ROOT_DIR}/config/brain_trust.env.example"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

source "${ENV_EXAMPLE}"
mkdir -p "${tmp_dir}/docs_root"
export BT_DOCS_ROOT="${tmp_dir}/docs_root"
export BT_TEAM_ID="team-brain-trust"

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

list_fallbacks() {
  local role="$1"
  local file="${state_dir}/${role}.fallbacks"
  if [[ -f "${file}" ]]; then
    cat "${file}"
  fi
}

save_fallbacks() {
  local role="$1"
  shift
  local file="${state_dir}/${role}.fallbacks"
  : >"${file}"
  local item
  for item in "$@"; do
    printf "%s\n" "${item}" >>"${file}"
  done
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
      shift || true
      case "${action}" in
        clear)
          save_fallbacks "${agent}"
          ;;
        add)
          current=()
          while IFS= read -r line; do
            [[ -n "${line}" ]] && current+=("${line}")
          done < <(list_fallbacks "${agent}")
          current+=("${1:?fallback required}")
          save_fallbacks "${agent}" "${current[@]}"
          ;;
        list)
          count="$(list_fallbacks "${agent}" | sed '/^$/d' | wc -l | tr -d ' ')"
          echo "Fallbacks (${count}):"
          while IFS= read -r line; do
            [[ -n "${line}" ]] && echo "- ${line}"
          done < <(list_fallbacks "${agent}")
          ;;
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

counter_file="${state_dir}/count_${mode}_${agent}"
count=0
if [[ -f "${counter_file}" ]]; then
  count="$(cat "${counter_file}")"
fi
count=$((count + 1))
printf "%s\n" "${count}" >"${counter_file}"

if [[ "${mode}" == "degraded_fail_innovator" && "${agent}" == "innovator" ]]; then
  echo "simulated innovator failure" >&2
  exit 2
fi

if [[ "${mode}" == "timeout_first_try" && "${agent}" == "architect" && "${count}" -eq 1 ]]; then
  echo "Process timed out after 120 seconds" >&2
  exit 124
fi

if [[ "${mode}" == "quota_first_try" && "${agent}" == "critic" && "${count}" -eq 1 ]]; then
  echo "API rate limit reached. Please try again later." >&2
  exit 2
fi

if [[ "${mode}" == "parse_error_critic" && "${agent}" == "critic" ]]; then
  emit_json_response "This response intentionally contains no JSON block."
  exit 0
fi

if [[ "${mode}" == "pangu_fail" && "${agent}" == "pangu" ]]; then
  echo "simulated pangu execution timeout" >&2
  exit 124
fi

case "${agent}" in
  architect)
    emit_json_response "$(cat <<'MD'
## 架构师审查
```json
{
  "role": "architect",
  "scores": {"feasibility": 9, "robustness": 8, "scalability": 7, "simplicity": 8},
  "top_findings": ["f1"],
  "top_suggestions": ["s1"],
  "intent_alignment": {"misalignment_found": false, "evidence": "ok", "correction": ""},
  "complexity_reduction": {"reduction_required": false, "items": [], "rationale": ""},
  "opensource_validation": []
}
```
MD
)"
    ;;
  critic)
    emit_json_response "$(cat <<'MD'
## 批判者审查
```json
{
  "role": "critic",
  "scores": {"feasibility": 8, "robustness": 7, "risk": 4},
  "top_findings": ["f2"],
  "top_suggestions": ["s2"],
  "intent_alignment": {"misalignment_found": false, "evidence": "ok", "correction": ""},
  "complexity_reduction": {"reduction_required": true, "items": ["简化A"], "rationale": ""},
  "opensource_validation": []
}
```
MD
)"
    ;;
  innovator)
    emit_json_response "$(cat <<'MD'
## 创新者审查
```json
{
  "role": "innovator",
  "scores": {"feasibility": 9, "scalability": 8, "simplicity": 7, "innovation": 8},
  "top_findings": ["f3"],
  "top_suggestions": ["s3"],
  "intent_alignment": {"misalignment_found": false, "evidence": "ok", "correction": ""},
  "complexity_reduction": {"reduction_required": false, "items": [], "rationale": ""},
  "opensource_validation": []
}
```
MD
)"
    ;;
  pangu)
    emit_json_response "$(cat <<'MD'
## 执行计划
1. 先落实全部 P0
2. 按收益/风险排序推进 P1

## 执行结果
- 已完成：P0-1
- 延后：P1-2

```json
{
  "trigger_mode": "auto",
  "scope_mode": "autonomous",
  "implemented_items": ["P0-1"],
  "deferred_items": ["P1-2"],
  "retryable_items": [],
  "failure_reason": ""
}
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

short_proposal="${tmp_dir}/proposal_short.md"
cat >"${short_proposal}" <<'EOF_PROPOSAL'
# Proposal
Build a resilient review pipeline.
EOF_PROPOSAL

long_proposal="${tmp_dir}/proposal_long.md"
python3 - "${long_proposal}" <<'PY'
from pathlib import Path
import sys
Path(sys.argv[1]).write_text("A" * 25050, encoding="utf-8")
PY

run_case() {
  local mode="$1"
  local proposal="$2"
  local out_dir="$3"

  BT_TEST_MODE="${mode}" \
  BT_SKIP_MODEL_SYNC="true" \
  BT_SKIP_DOCS_POLICY="true" \
  BT_SCHEDULER_MEMORY_DIR="${tmp_dir}/scheduler_memory" \
  BT_ROUTING_LOG_PATH="${tmp_dir}/routing_decisions.jsonl" \
  "${RUN_SCRIPT}" --proposal "${proposal}" --out "${out_dir}" >/dev/null
}

assert_json() {
  local file="$1"
  local code="$2"
  python3 - "${file}" "${code}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
code = sys.argv[2]
data = json.loads(path.read_text(encoding="utf-8"))
ns = {"data": data}
result = eval(code, {}, ns)
if not result:
    raise SystemExit(f"assertion failed: {code}")
PY
}

out_normal="${tmp_dir}/out_normal"
run_case "normal" "${short_proposal}" "${out_normal}"
assert_json "${out_normal}/structured_summary.json" "data['score_summary']['status'] == 'complete'"
assert_json "${out_normal}/structured_summary.json" "data['final_score'] > 0"
assert_json "${out_normal}/structured_summary.json" "data['orchestration']['stage2_status'] in ('complete', 'degraded')"
assert_json "${out_normal}/structured_summary.json" "data['orchestration']['stage3_status'] == 'complete'"
assert_json "${out_normal}/structured_summary.json" "data['orchestration']['stage4_status'] == 'complete'"
assert_json "${out_normal}/structured_summary.json" "data['orchestration']['stage4_executor'] == 'pangu'"
assert_json "${out_normal}/structured_summary.json" "'execution_summary' in data"
assert_json "${out_normal}/structured_summary.json" "'scheduling_summary' in data"
assert_json "${out_normal}/structured_summary.json" "'model_routing_summary' in data"
assert_json "${out_normal}/structured_summary.json" "all('spark' not in item['model'] for role in data['model_routing_summary'].values() for item in role['attempts'])"
[[ -f "${out_normal}/architect_cross_review.md" ]]
[[ -f "${out_normal}/critic_cross_review.md" ]]
[[ -f "${out_normal}/innovator_cross_review.md" ]]
[[ -f "${out_normal}/editor_review.md" ]]
[[ -f "${out_normal}/pangu_execution_plan.md" ]]
[[ -f "${out_normal}/pangu_execution_report.md" ]]
[[ -f "${out_normal}/pangu_execution_raw.json" ]]
[[ -f "${out_normal}/acceptance_report.json" ]]
[[ -f "${out_normal}/quality_gate_report.json" ]]
[[ -f "${out_normal}/quality_improvement_log.jsonl" ]]
[[ -f "${out_normal}/quality_baseline.yaml" ]]
assert_json "${out_normal}/acceptance_report.json" "data['reviewer'] == 'braintrust_compliance'"
assert_json "${out_normal}/acceptance_report.json" "data['status'] == 'pass'"
assert_json "${out_normal}/quality_gate_report.json" "data['final_quality_status'] == 'pass'"
python3 - "${out_normal}/quality_improvement_log.jsonl" <<'PY'
import json
import sys
from pathlib import Path

lines = [x.strip() for x in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines() if x.strip()]
assert lines, "quality_improvement_log.jsonl is empty"
row = json.loads(lines[-1])
assert row["experiment_result"] == "pass"
PY

out_degraded="${tmp_dir}/out_degraded"
run_case "degraded_fail_innovator" "${short_proposal}" "${out_degraded}"
assert_json "${out_degraded}/structured_summary.json" "data['execution_status'] == 'degraded'"
assert_json "${out_degraded}/structured_summary.json" "data['score_summary']['status'] == 'degraded'"
assert_json "${out_degraded}/structured_summary.json" "data['final_score'] > 0"
assert_json "${out_degraded}/structured_summary.json" "'innovator' in data['orchestration']['stage2_skipped_roles']"
assert_json "${out_degraded}/structured_summary.json" "data['orchestration']['stage3_status'] == 'complete'"

out_parse="${tmp_dir}/out_parse"
run_case "parse_error_critic" "${short_proposal}" "${out_parse}"
assert_json "${out_parse}/structured_summary.json" "len(data['parse_diagnostics']['errors']) >= 1"
assert_json "${out_parse}/structured_summary.json" "'critic' in data['parse_diagnostics']['failed_roles']"
assert_json "${out_parse}/structured_summary.json" "data['final_score'] > 0"

out_long="${tmp_dir}/out_long"
run_case "normal" "${long_proposal}" "${out_long}"
assert_json "${out_long}/structured_summary.json" "data['input_guard']['truncated'] is True"
assert_json "${out_long}/structured_summary.json" "data['input_guard']['effective_chars'] == 24000"

out_timeout="${tmp_dir}/out_timeout"
run_case "timeout_first_try" "${short_proposal}" "${out_timeout}"
assert_json "${out_timeout}/structured_summary.json" "len(data['model_routing_summary']['architect']['attempts']) >= 2"
assert_json "${out_timeout}/structured_summary.json" "'timeout' in data['model_routing_summary']['architect']['switch_reasons']"

out_quota="${tmp_dir}/out_quota"
run_case "quota_first_try" "${short_proposal}" "${out_quota}"
assert_json "${out_quota}/structured_summary.json" "len(data['model_routing_summary']['critic']['attempts']) >= 2"
assert_json "${out_quota}/structured_summary.json" "'rate_or_quota' in data['model_routing_summary']['critic']['switch_reasons']"

out_pangu_fail="${tmp_dir}/out_pangu_fail"
run_case "pangu_fail" "${short_proposal}" "${out_pangu_fail}"
assert_json "${out_pangu_fail}/structured_summary.json" "data['orchestration']['stage4_status'] == 'degraded'"
assert_json "${out_pangu_fail}/structured_summary.json" "len(data['execution_summary']['retryable_items']) >= 1"
assert_json "${out_pangu_fail}/structured_summary.json" "data['scheduling_summary']['status'] in ('dispatched','timeout','rejected','failed','skipped')"
assert_json "${out_pangu_fail}/structured_summary.json" "data['execution_status'] in ('normal','degraded')"
[[ -f "${out_pangu_fail}/pangu_execution_raw.json.stderr" ]]
[[ -f "${out_pangu_fail}/acceptance_report.json" ]]
[[ -f "${out_pangu_fail}/quality_gate_report.json" ]]
[[ -f "${out_pangu_fail}/quality_improvement_log.jsonl" ]]
assert_json "${out_pangu_fail}/acceptance_report.json" "data['status'] == 'blocked'"
assert_json "${out_pangu_fail}/quality_gate_report.json" "data['final_quality_status'] == 'blocked'"
python3 - "${out_pangu_fail}/quality_improvement_log.jsonl" <<'PY'
import json
import sys
from pathlib import Path

lines = [x.strip() for x in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines() if x.strip()]
assert lines, "quality_improvement_log.jsonl is empty"
row = json.loads(lines[-1])
assert row["experiment_result"] == "blocked"
PY

echo "All regression checks passed."
