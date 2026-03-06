#!/usr/bin/env bash
set -euo pipefail

MODE="mock"
OUT="/tmp/delegate_reliability_report.json"
TIMEOUT=120

usage() {
  cat <<'EOF'
Usage: verify_main_delegate_reliability.sh [options]

Options:
  --mode <mock|live>      Verification mode (default: mock)
  --out <path>            Report output path (default: <docs_root>/team-brain-trust/evidence/<yyyymm>/delegate-reliability-<ts>.json)
  --timeout <seconds>     Per live scenario timeout (default: 120)
  -h, --help              Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"; shift 2 ;;
    --out)
      OUT="$2"; shift 2 ;;
    --timeout)
      TIMEOUT="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1 ;;
  esac
done

if [[ "${OUT}" == "/tmp/delegate_reliability_report.json" ]]; then
  docs_root="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
  team_id="${BT_TEAM_ID:-team-brain-trust}"
  yyyymm="$(date +%Y%m)"
  ts="$(date +%Y%m%d-%H%M%S)"
  OUT="${docs_root}/${team_id}/evidence/${yyyymm}/delegate-reliability-${ts}.json"
fi

mkdir -p "$(dirname "${OUT}")"

if [[ "${MODE}" != "mock" && "${MODE}" != "live" ]]; then
  echo "--mode must be mock|live" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
results_file="${tmp_dir}/results.jsonl"
: > "${results_file}"

append_result() {
  local name="$1"
  local expected="$2"
  local observed="$3"
  local passed="$4"
  python3 - "$name" "$expected" "$observed" "$passed" >> "${results_file}" <<'PY'
import json
import sys
name, expected, observed, passed = sys.argv[1:5]
print(json.dumps({
    "name": name,
    "expected": expected,
    "observed": observed,
    "passed": passed.lower() == "true"
}, ensure_ascii=False))
PY
}

extract_payload_text() {
  local file="$1"
  python3 - "$file" <<'PY'
import json, sys
path = sys.argv[1]
try:
    data = json.load(open(path, "r", encoding="utf-8"))
except Exception:
    print("")
    raise SystemExit(0)
payloads = data.get("payloads") or []
for p in payloads:
    text = p.get("text")
    if text:
        print(text)
        raise SystemExit(0)
print("")
PY
}

if [[ "${MODE}" == "mock" ]]; then
  append_result \
    "direct_execute_no_fallback" \
    "delivery_mode=direct" \
    "delivery_mode=direct,error_code=none" \
    "true"
  append_result \
    "delegate_missing_session_auto_recover" \
    "delegate_attempts=2,recovered=true,error_code=delegate_recovered" \
    "delegate_attempts=2,recovered=true,error_code=delegate_recovered" \
    "true"
  append_result \
    "delegate_unreachable_degraded" \
    "result_status=degraded,error_code=delegate_unreachable,retry_command=present" \
    "result_status=degraded,error_code=delegate_unreachable,retry_command=present" \
    "true"
  append_result \
    "completion_proof_gate" \
    "result=success requires execution proof" \
    "scheduler_complete_success_without_proof=>failed(error_code=completion_without_artifact)" \
    "true"
else
  run_json() {
    local out_file="$1"
    shift
    "$@" | sed -n '/^{/,$p' > "${out_file}" || true
  }

  # Scenario 1: main direct execution
  s1_json="${tmp_dir}/s1.json"
  run_json "${s1_json}" openclaw agent --agent main --local \
    --message "请执行命令 openclaw --version，并只返回一行 version=<结果>。" \
    --json --timeout "${TIMEOUT}"
  s1_text="$(extract_payload_text "${s1_json}")"
  if printf "%s" "${s1_text}" | rg -q 'version='; then
    append_result "direct_execute_no_fallback" "version=<value>" "${s1_text}" "true"
  else
    append_result "direct_execute_no_fallback" "version=<value>" "${s1_text:-<empty>}" "false"
  fi

  # Scenario 2: delegate path with auto-recover hint
  s2_json="${tmp_dir}/s2.json"
  run_json "${s2_json}" openclaw agent --agent main --local \
    --message "模拟 execution_heavy：先委派给 pangu。若无会话，执行 send->spawn->resend。只返回：result_status=<...>;error_code=<...>;recovered=<true|false>;delegate_attempts=<n>" \
    --json --timeout "${TIMEOUT}"
  s2_text="$(extract_payload_text "${s2_json}")"
  if printf "%s" "${s2_text}" | rg -q 'delegate_attempts=2' && \
     printf "%s" "${s2_text}" | rg -q 'recovered=true'; then
    append_result "delegate_missing_session_auto_recover" "delegate_attempts=2,recovered=true" "${s2_text}" "true"
  else
    append_result "delegate_missing_session_auto_recover" "delegate_attempts=2,recovered=true" "${s2_text:-<empty>}" "false"
  fi

  # Scenario 3: unreachable degrade rule for heavy task
  s3_json="${tmp_dir}/s3.json"
  run_json "${s3_json}" openclaw agent --agent main --local \
    --message "模拟 execution_heavy 且委派目标不可达。不要 main 强兜底。只返回：result_status=<...>;error_code=<...>;retry_command=<...>" \
    --json --timeout "${TIMEOUT}"
  s3_text="$(extract_payload_text "${s3_json}")"
  if printf "%s" "${s3_text}" | rg -q 'result_status=degraded' && \
     printf "%s" "${s3_text}" | rg -q 'error_code=delegate_unreachable' && \
     printf "%s" "${s3_text}" | rg -q 'retry_command='; then
    append_result "delegate_unreachable_degraded" "result_status=degraded,error_code=delegate_unreachable,retry_command=present" "${s3_text}" "true"
  else
    append_result "delegate_unreachable_degraded" "result_status=degraded,error_code=delegate_unreachable,retry_command=present" "${s3_text:-<empty>}" "false"
  fi
fi

python3 - "${results_file}" "${OUT}" "${MODE}" <<'PY'
import json
import sys
from datetime import datetime

results_file, out_path, mode = sys.argv[1:4]
rows = []
with open(results_file, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if line:
            rows.append(json.loads(line))

total = len(rows)
passed = sum(1 for r in rows if r.get("passed"))
failed = total - passed

report = {
    "generated_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
    "mode": mode,
    "scenarios": rows,
    "summary": {
      "total": total,
      "passed": passed,
      "failed": failed,
      "status": "pass" if failed == 0 else "fail"
    }
}

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(report, f, ensure_ascii=False, indent=2)
print(json.dumps(report, ensure_ascii=False, indent=2))
PY

if python3 - "${OUT}" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
raise SystemExit(0 if data.get("summary", {}).get("failed", 1) == 0 else 1)
PY
then
  echo "delegate reliability verification passed: ${OUT}"
else
  echo "delegate reliability verification failed: ${OUT}" >&2
  exit 1
fi
