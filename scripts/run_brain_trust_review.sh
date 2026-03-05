#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/config/brain_trust_config.yaml"
VALIDATOR="${ROOT_DIR}/scripts/validate_brain_trust_env.sh"
MODEL_SYNC="${ROOT_DIR}/scripts/sync_brain_trust_models.sh"

proposal=""
depth="standard"
focus=""
out_dir=""
use_local="false"

usage() {
  cat <<USAGE
Usage: $(basename "$0") --proposal <path> [--depth quick|standard|deep] [--focus "text"] [--out <dir>] [--local]
USAGE
}

read_config_path() {
  local path="$1"
  local default_value="$2"
  local value

  value="$(python3 - "${CONFIG_FILE}" "${path}" "${default_value}" <<'PY'
import re
import sys
from pathlib import Path


def strip_inline_comment(s: str) -> str:
    out = []
    in_single = False
    in_double = False
    for ch in s:
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == "#" and not in_single and not in_double:
            break
        out.append(ch)
    return "".join(out).rstrip()


def parse_scalar(raw: str):
    val = raw.strip()
    if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
        return val[1:-1]
    lowered = val.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    if re.fullmatch(r"-?\d+", val):
        return int(val)
    if re.fullmatch(r"-?\d+\.\d+", val):
        return float(val)
    return val


cfg_path = Path(sys.argv[1])
target_path = sys.argv[2]
default_value = sys.argv[3]

root = {}
stack = [(-1, root)]

for raw_line in cfg_path.read_text(encoding="utf-8").splitlines():
    if not raw_line.strip() or raw_line.lstrip().startswith("#"):
        continue

    indent = len(raw_line) - len(raw_line.lstrip(" "))
    content = strip_inline_comment(raw_line.lstrip(" "))
    if not content:
        continue
    if content.startswith("- "):
        continue
    if ":" not in content:
        continue

    key, val = content.split(":", 1)
    key = key.strip()
    val = val.strip()

    while stack and indent <= stack[-1][0]:
        stack.pop()
    parent = stack[-1][1] if stack else root

    if val == "":
        node = {}
        parent[key] = node
        stack.append((indent, node))
    else:
        parent[key] = parse_scalar(val)

node = root
missing = False
for part in target_path.split("."):
    if isinstance(node, dict) and part in node:
        node = node[part]
    else:
        missing = True
        break

if missing or node is None:
    print(default_value)
elif isinstance(node, bool):
    print("true" if node else "false")
else:
    print(node)
PY
)"

  if [[ -z "${value}" ]]; then
    echo "${default_value}"
  else
    echo "${value}"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proposal)
      proposal="${2:-}"
      shift 2
      ;;
    --depth)
      depth="${2:-}"
      shift 2
      ;;
    --focus)
      focus="${2:-}"
      shift 2
      ;;
    --out)
      out_dir="${2:-}"
      shift 2
      ;;
    --local)
      use_local="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${proposal}" ]]; then
  echo "--proposal is required" >&2
  usage
  exit 1
fi

if [[ ! -f "${proposal}" ]]; then
  echo "proposal file not found: ${proposal}" >&2
  exit 1
fi

case "${depth}" in
  quick|standard|deep) ;;
  *)
    echo "invalid --depth: ${depth}" >&2
    exit 1
    ;;
esac

"${VALIDATOR}"

max_tokens_per_role="$(read_config_path "runtime.max_tokens_per_role" "16000")"
max_proposal_chars="$(read_config_path "runtime.max_proposal_chars" "24000")"
timeout_per_role_seconds="$(read_config_path "runtime.timeout_per_role_seconds" "120")"
max_attempts="$(read_config_path "runtime.retry.max_attempts" "2")"
backoff_seconds="$(read_config_path "runtime.retry.backoff_seconds" "5")"
min_roles_required="$(read_config_path "runtime.degradation.min_roles_required" "2")"

weight_feasibility="$(read_config_path "scoring_weights.feasibility" "0.25")"
weight_robustness="$(read_config_path "scoring_weights.robustness" "0.20")"
weight_scalability="$(read_config_path "scoring_weights.scalability" "0.15")"
weight_simplicity="$(read_config_path "scoring_weights.simplicity" "0.15")"
weight_innovation="$(read_config_path "scoring_weights.innovation" "0.10")"
weight_risk="$(read_config_path "scoring_weights.risk" "0.15")"

if ! [[ "${max_tokens_per_role}" =~ ^[0-9]+$ ]] || (( max_tokens_per_role < 1 )); then
  max_tokens_per_role="16000"
fi
if ! [[ "${max_proposal_chars}" =~ ^[0-9]+$ ]]; then
  max_proposal_chars="24000"
fi
if ! [[ "${max_attempts}" =~ ^[0-9]+$ ]] || (( max_attempts < 1 )); then
  max_attempts="1"
fi
if ! [[ "${min_roles_required}" =~ ^[0-9]+$ ]] || (( min_roles_required < 1 )); then
  min_roles_required="2"
fi
if ! [[ "${timeout_per_role_seconds}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  timeout_per_role_seconds="120"
fi
if ! [[ "${backoff_seconds}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  backoff_seconds="5"
fi

proposal_text="$(cat "${proposal}")"
original_chars="${#proposal_text}"
proposal_truncated="false"
if (( original_chars > max_proposal_chars )); then
  proposal_text="${proposal_text:0:max_proposal_chars}"
  proposal_truncated="true"
fi
effective_chars="${#proposal_text}"
estimated_tokens_per_role=$(( (effective_chars + 3) / 4 ))
token_budget_exceeded="false"
if (( estimated_tokens_per_role > max_tokens_per_role )); then
  token_budget_exceeded="true"
fi

ts="$(date +%Y%m%d_%H%M%S)"
if [[ -z "${out_dir}" ]]; then
  out_dir="${ROOT_DIR}/reviews/${ts}"
fi
mkdir -p "${out_dir}"

if [[ "${BT_SKIP_MODEL_SYNC:-false}" != "true" ]]; then
  if ! "${MODEL_SYNC}" --check-only --record "${out_dir}/model_assignment_check.json"; then
    "${MODEL_SYNC}" --apply --record "${out_dir}/model_assignment_record.json"
  fi
fi

build_prompt() {
  local role="$1"
  cat <<PROMPT
## 审查请求

角色：${role}
审查深度：${depth}
特别关注：${focus:-无}

### 方案内容
${proposal_text}

### 输出要求
1. 按你的 SKILL 方法论输出完整审查意见。
2. 必须包含结构化 JSON 摘要。
3. 必须包含意图纠偏结论（intent_alignment）。
4. 若推荐开源方案，必须包含 opensource_validation 证据。
5. 必须包含 complexity_reduction 结构：
   {
     "reduction_required": false,
     "items": [],
     "rationale": ""
   }
6. 必须包含 consensus_checks：goal_clarity / benefit_verifiability / operability / recommendation。
7. 必须包含 p0_items（Top 3）与 p1_items（Top 3）。
8. 必须包含 alternative_proposals（至少 1 个）。
9. P0/P1 每条必须使用固定格式：问题 -> 影响 -> 建议 -> 验证方式。
10. 不要输出任何外部裁决字段。
PROMPT
}

run_with_timeout() {
  local timeout_seconds="$1"
  local stdout_file="$2"
  local stderr_file="$3"
  shift 3

  python3 - "$timeout_seconds" "$stdout_file" "$stderr_file" "$@" <<'PY'
import subprocess
import sys
import traceback


def _to_text(value):
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    return value.decode("utf-8", errors="ignore")


timeout = float(sys.argv[1])
stdout_file = sys.argv[2]
stderr_file = sys.argv[3]
cmd = sys.argv[4:]

try:
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    with open(stdout_file, "w", encoding="utf-8") as f:
        f.write(_to_text(proc.stdout))
    with open(stderr_file, "w", encoding="utf-8") as f:
        f.write(_to_text(proc.stderr))
    sys.exit(proc.returncode)
except subprocess.TimeoutExpired as e:
    with open(stdout_file, "w", encoding="utf-8") as f:
        f.write(_to_text(e.stdout))
    timeout_msg = f"Process timed out after {int(timeout)} seconds\n"
    timeout_msg += _to_text(e.stderr)
    with open(stderr_file, "w", encoding="utf-8") as f:
        f.write(timeout_msg)
    sys.exit(124)
except Exception:
    with open(stdout_file, "w", encoding="utf-8") as f:
        f.write("")
    with open(stderr_file, "w", encoding="utf-8") as f:
        f.write(traceback.format_exc())
    sys.exit(125)
PY
}

get_role_model_chain() {
  local role="$1"
  case "${role}" in
    architect)
      printf "%s\n" "${BT_ARCHITECT_MODEL}" "${BT_ARCHITECT_FALLBACK_1}" "${BT_ARCHITECT_FALLBACK_2}" "${BT_ARCHITECT_FALLBACK_3}"
      ;;
    critic)
      printf "%s\n" "${BT_CRITIC_MODEL}" "${BT_CRITIC_FALLBACK_1}" "${BT_CRITIC_FALLBACK_2}" "${BT_CRITIC_FALLBACK_3}"
      ;;
    innovator)
      printf "%s\n" "${BT_INNOVATOR_MODEL}" "${BT_INNOVATOR_FALLBACK_1}" "${BT_INNOVATOR_FALLBACK_2}" "${BT_INNOVATOR_FALLBACK_3}"
      ;;
    *)
      return 1
      ;;
  esac
}

categorize_failure_reason() {
  local stderr_file="$1"
  local txt=""
  txt="$(cat "${stderr_file}" 2>/dev/null || true)"

  if printf "%s" "${txt}" | rg -qi "timed out|timeout"; then
    echo "timeout"
    return
  fi
  if printf "%s" "${txt}" | rg -qi "rate limit|quota|RESOURCE_EXHAUSTED"; then
    echo "rate_or_quota"
    return
  fi
  if printf "%s" "${txt}" | rg -qi "API key expired|API_KEY_INVALID|No API key|auth"; then
    echo "auth_invalid"
    return
  fi
  if printf "%s" "${txt}" | rg -qi "session file locked|locked"; then
    echo "session_locked"
    return
  fi
  echo "command_failed"
}

run_agent_prompt() {
  local role="$1"
  local prompt="$2"
  local review_file="$3"
  local json_file="$4"
  local routing_file="$5"

  local cmd=(openclaw agent --agent "${role}" --message "${prompt}" --json)
  if [[ "${use_local}" == "true" ]]; then
    cmd+=(--local)
  fi

  : >"${json_file}.stderr"
  : >"${routing_file}"

  local attempt rc tmp_out tmp_err
  local -a model_chain=()
  while IFS= read -r line; do
    [[ -n "${line}" ]] && model_chain+=("${line}")
  done < <(get_role_model_chain "${role}")
  local max_chain_attempts="${#model_chain[@]}"
  local effective_attempts="${max_chain_attempts}"
  if (( max_attempts < effective_attempts )); then
    effective_attempts="${max_attempts}"
  fi

  for (( attempt=1; attempt<=effective_attempts; attempt++ )); do
    local model="${model_chain[$((attempt-1))]}"
    tmp_out="${json_file}.attempt${attempt}.out"
    tmp_err="${json_file}.attempt${attempt}.err"

    if ! openclaw models --agent "${role}" set "${model}" >"${tmp_err}" 2>&1; then
      {
        echo "[attempt ${attempt}/${effective_attempts}] status=failed model=${model} reason=model_set_failed"
        cat "${tmp_err}"
        echo
      } >>"${json_file}.stderr"
      printf "%s\t%s\t%s\t%s\t%s\n" "${attempt}" "${model}" "failed" "2" "model_set_failed" >>"${routing_file}"
      rm -f "${tmp_out}" "${tmp_err}"
      if (( attempt < effective_attempts )); then
        sleep "${backoff_seconds}"
      fi
      continue
    fi

    if run_with_timeout "${timeout_per_role_seconds}" "${tmp_out}" "${tmp_err}" "${cmd[@]}"; then
      mv "${tmp_out}" "${json_file}"
      {
        echo "[attempt ${attempt}/${effective_attempts}] status=success model=${model}"
        cat "${tmp_err}"
        echo
      } >>"${json_file}.stderr"
      printf "%s\t%s\t%s\t%s\t%s\n" "${attempt}" "${model}" "success" "0" "ok" >>"${routing_file}"
      rm -f "${tmp_err}"

      python3 - "$json_file" "$review_file" <<'PY'
import json
import sys
from pathlib import Path

src = Path(sys.argv[1])
out = Path(sys.argv[2])
raw = src.read_text(encoding="utf-8") if src.exists() else ""
text = ""
obj = None

try:
    obj = json.loads(raw)
except Exception:
    # Some providers prepend non-JSON logs before the JSON envelope.
    decoder = json.JSONDecoder()
    i = 0
    n = len(raw)
    while i < n:
        idx = raw.find("{", i)
        if idx < 0:
            break
        try:
            candidate, end = decoder.raw_decode(raw[idx:])
            if isinstance(candidate, dict):
                obj = candidate
                break
            i = idx + max(end, 1)
        except Exception:
            i = idx + 1

if isinstance(obj, dict):
    for key in ("response", "reply", "message", "output", "text"):
        if key in obj and isinstance(obj[key], str):
            text = obj[key]
            break
    # Compatible with openclaw --json envelope:
    # {"payloads":[{"text":"..."}], ...}
    if not text and isinstance(obj.get("payloads"), list):
        for item in obj["payloads"]:
            if isinstance(item, dict) and isinstance(item.get("text"), str):
                text = item["text"]
                break
    if not text and isinstance(obj.get("response"), dict):
        text = obj["response"].get("text", "")

if not text:
    text = raw.strip()

if not text:
    text = "# Empty response"
out.write_text(text + "\n", encoding="utf-8")
PY
      return 0
    fi

    rc=$?
    reason="$(categorize_failure_reason "${tmp_err}")"
    {
      echo "[attempt ${attempt}/${effective_attempts}] status=failed model=${model} exit_code=${rc} reason=${reason}"
      cat "${tmp_err}"
      echo
    } >>"${json_file}.stderr"
    printf "%s\t%s\t%s\t%s\t%s\n" "${attempt}" "${model}" "failed" "${rc}" "${reason}" >>"${routing_file}"

    rm -f "${tmp_out}" "${tmp_err}"

    if (( attempt < effective_attempts )); then
      sleep "${backoff_seconds}"
    fi
  done

  cat >"${review_file}" <<ERR
# ${role} review failed

Command failed after ${effective_attempts} attempts. See:
- ${json_file}.stderr
ERR
  return 1
}

run_role() {
  local role="$1"
  local review_file="$2"
  local json_file="$3"
  local routing_file="$4"
  local prompt
  prompt="$(build_prompt "${role}")"
  run_agent_prompt "${role}" "${prompt}" "${review_file}" "${json_file}" "${routing_file}"
}

build_cross_review_prompt() {
  local role="$1"
  local own_role="$2"
  local own_file="$3"
  local other_a_role="$4"
  local other_a_file="$5"
  local other_b_role="$6"
  local other_b_file="$7"
  local context_limit=12000

  local own_text other_a_text other_b_text
  own_text="$(cat "${own_file}" 2>/dev/null || true)"
  other_a_text="$(cat "${other_a_file}" 2>/dev/null || true)"
  other_b_text="$(cat "${other_b_file}" 2>/dev/null || true)"

  if (( ${#own_text} > context_limit )); then
    own_text="${own_text:0:context_limit}\n[...已截断...]"
  fi
  if (( ${#other_a_text} > context_limit )); then
    other_a_text="${other_a_text:0:context_limit}\n[...已截断...]"
  fi
  if (( ${#other_b_text} > context_limit )); then
    other_b_text="${other_b_text:0:context_limit}\n[...已截断...]"
  fi

  cat <<PROMPT
## 交叉复核请求（Stage 2）

你当前角色：${role}
审查深度：${depth}
特别关注：${focus:-无}

### 你的 Stage 1 独立评审（${own_role}）
${own_text:-[无]}

### 其他角色评审 A（${other_a_role}）
${other_a_text:-[该角色未产出或缺失]}

### 其他角色评审 B（${other_b_role}）
${other_b_text:-[该角色未产出或缺失]}

### 你的任务（只做对齐，不重写整份评审）
仅输出以下三部分：
1) 同意点（+）
2) 不同意点（-，必须给出理由/证据）
3) 补充遗漏项（关键风险/指标）

禁止输出裁决语义；最终拍板在人类。
PROMPT
}

run_cross_review() {
  local role="$1"
  local own_role="$2"
  local own_file="$3"
  local other_a_role="$4"
  local other_a_file="$5"
  local other_b_role="$6"
  local other_b_file="$7"
  local review_file="$8"
  local json_file="$9"
  local routing_file="${10}"

  local prompt
  prompt="$(build_cross_review_prompt "${role}" "${own_role}" "${own_file}" "${other_a_role}" "${other_a_file}" "${other_b_role}" "${other_b_file}")"
  run_agent_prompt "${role}" "${prompt}" "${review_file}" "${json_file}" "${routing_file}"
}

csv_join() {
  local IFS=','
  echo "$*"
}

architect_file="${out_dir}/architect_review.md"
critic_file="${out_dir}/critic_review.md"
innovator_file="${out_dir}/innovator_review.md"

architect_json="${out_dir}/architect_raw.json"
critic_json="${out_dir}/critic_raw.json"
innovator_json="${out_dir}/innovator_raw.json"
architect_routing="${out_dir}/architect_model_routing.log"
critic_routing="${out_dir}/critic_model_routing.log"
innovator_routing="${out_dir}/innovator_model_routing.log"

ok_roles=0
fail_roles=0
stage1_ok_architect="false"
stage1_ok_critic="false"
stage1_ok_innovator="false"

# Stage1 uses serial execution to avoid global model override races in OpenClaw.
if run_role architect "${architect_file}" "${architect_json}" "${architect_routing}"; then
  ok_roles=$((ok_roles + 1))
  stage1_ok_architect="true"
else
  fail_roles=$((fail_roles + 1))
fi

if run_role critic "${critic_file}" "${critic_json}" "${critic_routing}"; then
  ok_roles=$((ok_roles + 1))
  stage1_ok_critic="true"
else
  fail_roles=$((fail_roles + 1))
fi

if run_role innovator "${innovator_file}" "${innovator_json}" "${innovator_routing}"; then
  ok_roles=$((ok_roles + 1))
  stage1_ok_innovator="true"
else
  fail_roles=$((fail_roles + 1))
fi

execution_status="normal"
if (( fail_roles > 0 )); then
  if (( ok_roles >= min_roles_required )); then
    execution_status="degraded"
  else
    echo "Not enough completed roles (${ok_roles}/${min_roles_required})." >&2
    exit 2
  fi
fi

architect_cross_file="${out_dir}/architect_cross_review.md"
critic_cross_file="${out_dir}/critic_cross_review.md"
innovator_cross_file="${out_dir}/innovator_cross_review.md"

architect_cross_json="${out_dir}/architect_cross_raw.json"
critic_cross_json="${out_dir}/critic_cross_raw.json"
innovator_cross_json="${out_dir}/innovator_cross_raw.json"
architect_cross_routing="${out_dir}/architect_cross_model_routing.log"
critic_cross_routing="${out_dir}/critic_cross_model_routing.log"
innovator_cross_routing="${out_dir}/innovator_cross_model_routing.log"

stage2_completed=()
stage2_failed=()
stage2_skipped=()

if [[ "${stage1_ok_architect}" == "true" ]]; then
  if run_cross_review architect "Architect" "${architect_file}" "Critic" "${critic_file}" "Innovator" "${innovator_file}" "${architect_cross_file}" "${architect_cross_json}" "${architect_cross_routing}"; then
    stage2_completed+=("architect")
  else
    stage2_failed+=("architect")
  fi
else
  stage2_skipped+=("architect")
  cat >"${architect_cross_file}" <<'SKIP'
# architect cross review skipped

Stage 1 review was unavailable; cross review skipped.
SKIP
fi

if [[ "${stage1_ok_critic}" == "true" ]]; then
  if run_cross_review critic "Critic" "${critic_file}" "Architect" "${architect_file}" "Innovator" "${innovator_file}" "${critic_cross_file}" "${critic_cross_json}" "${critic_cross_routing}"; then
    stage2_completed+=("critic")
  else
    stage2_failed+=("critic")
  fi
else
  stage2_skipped+=("critic")
  cat >"${critic_cross_file}" <<'SKIP'
# critic cross review skipped

Stage 1 review was unavailable; cross review skipped.
SKIP
fi

if [[ "${stage1_ok_innovator}" == "true" ]]; then
  if run_cross_review innovator "Innovator" "${innovator_file}" "Architect" "${architect_file}" "Critic" "${critic_file}" "${innovator_cross_file}" "${innovator_cross_json}" "${innovator_cross_routing}"; then
    stage2_completed+=("innovator")
  else
    stage2_failed+=("innovator")
  fi
else
  stage2_skipped+=("innovator")
  cat >"${innovator_cross_file}" <<'SKIP'
# innovator cross review skipped

Stage 1 review was unavailable; cross review skipped.
SKIP
fi

stage2_status="complete"
if (( ${#stage2_completed[@]} == 0 )); then
  stage2_status="insufficient"
elif (( ${#stage2_failed[@]} > 0 )); then
  stage2_status="degraded"
fi

stage2_completed_csv="$(csv_join "${stage2_completed[@]-}")"
stage2_failed_csv="$(csv_join "${stage2_failed[@]-}")"
stage2_skipped_csv="$(csv_join "${stage2_skipped[@]-}")"

summary_file="${out_dir}/summary_report.md"
structured_file="${out_dir}/structured_summary.json"
editor_file="${out_dir}/editor_review.md"

python3 - \
  "$architect_file" "$critic_file" "$innovator_file" \
  "$architect_routing" "$critic_routing" "$innovator_routing" \
  "$architect_cross_file" "$critic_cross_file" "$innovator_cross_file" \
  "$summary_file" "$structured_file" "$editor_file" "$execution_status" "$stage2_status" \
  "$stage2_completed_csv" "$stage2_failed_csv" "$stage2_skipped_csv" \
  "$original_chars" "$effective_chars" "$proposal_truncated" \
  "$max_tokens_per_role" "$estimated_tokens_per_role" "$token_budget_exceeded" \
  "$weight_feasibility" "$weight_robustness" "$weight_scalability" \
  "$weight_simplicity" "$weight_innovation" "$weight_risk" <<'PY'
import json
import re
import sys
from pathlib import Path

(
    architect,
    critic,
    innovator,
    architect_routing,
    critic_routing,
    innovator_routing,
    architect_cross,
    critic_cross,
    innovator_cross,
    summary_path,
    structured_path,
    editor_path,
    execution_status,
    stage2_status,
    stage2_completed_csv,
    stage2_failed_csv,
    stage2_skipped_csv,
    original_chars,
    effective_chars,
    proposal_truncated,
    max_tokens_per_role,
    estimated_tokens_per_role,
    token_budget_exceeded,
    w_feasibility,
    w_robustness,
    w_scalability,
    w_simplicity,
    w_innovation,
    w_risk,
) = sys.argv[1:]

role_files = {
    "architect": Path(architect),
    "critic": Path(critic),
    "innovator": Path(innovator),
}

routing_files = {
    "architect": Path(architect_routing),
    "critic": Path(critic_routing),
    "innovator": Path(innovator_routing),
}

cross_review_files = {
    "architect": Path(architect_cross),
    "critic": Path(critic_cross),
    "innovator": Path(innovator_cross),
}

weights = {
    "feasibility": float(w_feasibility),
    "robustness": float(w_robustness),
    "scalability": float(w_scalability),
    "simplicity": float(w_simplicity),
    "innovation": float(w_innovation),
    "risk": float(w_risk),
}


def parse_csv_roles(text: str):
    return [p.strip() for p in text.split(",") if p.strip()]


def parse_model_routing(path: Path):
    if not path.exists():
        return {
            "attempts": [],
            "models_tried": [],
            "final_success_model": "",
            "switch_reasons": [],
        }

    attempts = []
    models_tried = []
    switch_reasons = []
    final_success_model = ""

    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) != 5:
            continue
        attempt_s, model, status, exit_code_s, reason = parts
        try:
            attempt_n = int(attempt_s)
        except Exception:
            attempt_n = 0
        try:
            exit_code_n = int(exit_code_s)
        except Exception:
            exit_code_n = 0

        attempts.append(
            {
                "attempt": attempt_n,
                "model": model,
                "status": status,
                "exit_code": exit_code_n,
                "reason": reason,
            }
        )
        if model and model not in models_tried:
            models_tried.append(model)
        if status == "success" and not final_success_model:
            final_success_model = model
        if status != "success" and reason and reason not in switch_reasons:
            switch_reasons.append(reason)

    return {
        "attempts": attempts,
        "models_tried": models_tried,
        "final_success_model": final_success_model,
        "switch_reasons": switch_reasons,
    }


def extract_structured_payload(text: str, role: str):
    errors = []
    candidates = []

    def add_candidate(obj, source):
        if isinstance(obj, dict):
            candidates.append((obj, source))

    for raw in re.findall(r"```json\\s*(\{.*?\})\\s*```", text, flags=re.S):
        try:
            add_candidate(json.loads(raw), "fenced_json")
        except Exception as e:
            errors.append(f"{role}: fenced_json parse error: {e}")

    decoder = json.JSONDecoder()
    i = 0
    n = len(text)
    while i < n:
        idx = text.find("{", i)
        if idx < 0:
            break
        try:
            obj, end = decoder.raw_decode(text[idx:])
            add_candidate(obj, "raw_decode")
            i = idx + max(end, 1)
        except Exception:
            i = idx + 1

    stripped = text.strip()
    if stripped and not candidates:
        try:
            add_candidate(json.loads(stripped), "whole_text")
        except Exception as e:
            errors.append(f"{role}: whole_text parse error: {e}")

    if not candidates:
        return {}, errors

    def rank(item, idx):
        obj, _ = item
        score = 0
        if obj.get("role") == role:
            score += 3
        if isinstance(obj.get("scores"), dict):
            score += 2
        if isinstance(obj.get("intent_alignment"), dict):
            score += 1
        if isinstance(obj.get("top_findings"), list):
            score += 1
        return (score, idx)

    best_idx = 0
    best_rank = (-1, -1)
    for idx, item in enumerate(candidates):
        current_rank = rank(item, idx)
        if current_rank >= best_rank:
            best_rank = current_rank
            best_idx = idx

    return candidates[best_idx][0], errors


def as_number(value):
    if isinstance(value, bool):
        return None
    try:
        return float(value)
    except Exception:
        return None


payloads = {}
parse_errors = []
parsed_roles = []
failed_roles = []

for role, path in role_files.items():
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    data, errs = extract_structured_payload(text, role)
    payloads[role] = data
    parse_errors.extend(errs)
    if data:
        parsed_roles.append(role)
    else:
        failed_roles.append(role)
        parse_errors.append(f"{role}: no valid structured JSON payload found")

intent_notes = []
misalignment = False
opensource = []
complexity_items = []
structured_field_roles = 0
fallback_extracted_roles = 0

for role, data in payloads.items():
    ia = data.get("intent_alignment", {}) if isinstance(data, dict) else {}
    if isinstance(ia, dict):
        found = bool(ia.get("misalignment_found", False))
        if found:
            misalignment = True
        evidence = ia.get("evidence")
        correction = ia.get("correction")
        if evidence or correction:
            intent_notes.append({"role": role, "evidence": evidence or "", "correction": correction or ""})

    osv = data.get("opensource_validation", []) if isinstance(data, dict) else []
    if isinstance(osv, list):
        for item in osv:
            if isinstance(item, dict):
                opensource.append(item)

    cr = data.get("complexity_reduction", None) if isinstance(data, dict) else None
    if isinstance(cr, dict):
        structured_field_roles += 1
        reduction_required = bool(cr.get("reduction_required", False))
        items = cr.get("items", [])
        rationale = cr.get("rationale", "")
        added = False
        if isinstance(items, list):
            for it in items:
                if isinstance(it, str) and it.strip():
                    complexity_items.append({"role": role, "item": it, "source": "structured"})
                    added = True
        if not added and isinstance(rationale, str) and rationale.strip():
            complexity_items.append({"role": role, "item": rationale.strip(), "source": "structured"})
            added = True
        if not added and reduction_required:
            complexity_items.append({"role": role, "item": "该角色标记需要削减复杂度", "source": "structured"})
    else:
        suggestions = data.get("top_suggestions", []) if isinstance(data, dict) else []
        role_fallback_items = []
        if isinstance(suggestions, list):
            for s in suggestions:
                if isinstance(s, str) and ("简" in s or "复杂" in s or "削减" in s or "精简" in s):
                    role_fallback_items.append(s)
        if role_fallback_items:
            fallback_extracted_roles += 1
            for s in role_fallback_items:
                complexity_items.append({"role": role, "item": s, "source": "fallback"})

if not complexity_items:
    complexity_summary = {
        "reduction_required": False,
        "items": [],
        "source_breakdown": {
            "structured_field_roles": structured_field_roles,
            "fallback_extracted_roles": fallback_extracted_roles,
        },
    }
else:
    complexity_summary = {
        "reduction_required": True,
        "items": complexity_items,
        "source_breakdown": {
            "structured_field_roles": structured_field_roles,
            "fallback_extracted_roles": fallback_extracted_roles,
        },
    }

score_buckets = {
    "feasibility": [],
    "robustness": [],
    "scalability": [],
    "simplicity": [],
    "innovation": [],
    "risk_raw": [],
}
score_anomalies = []


def collect_score(role: str, dimension: str, raw_value, bucket: str):
    if raw_value is None:
        return
    numeric = as_number(raw_value)
    if numeric is None:
        score_anomalies.append(
            {
                "role": role,
                "dimension": dimension,
                "raw": str(raw_value),
                "normalized": None,
                "reason": "non_numeric_ignored",
            }
        )
        return

    normalized = max(1.0, min(10.0, numeric))
    if normalized != numeric:
        score_anomalies.append(
            {
                "role": role,
                "dimension": dimension,
                "raw": round(numeric, 4),
                "normalized": round(normalized, 4),
                "reason": "out_of_range_clamped",
            }
        )
    score_buckets[bucket].append(normalized)

for role, data in payloads.items():
    scores = data.get("scores", {}) if isinstance(data, dict) else {}
    if not isinstance(scores, dict):
        continue

    collect_score(role, "feasibility", scores.get("feasibility"), "feasibility")

    if role in ("architect", "critic"):
        collect_score(role, "robustness", scores.get("robustness"), "robustness")

    if role in ("architect", "innovator"):
        collect_score(role, "scalability", scores.get("scalability"), "scalability")
        collect_score(role, "simplicity", scores.get("simplicity"), "simplicity")

    if role == "innovator":
        collect_score(role, "innovation", scores.get("innovation"), "innovation")

    if role == "critic":
        collect_score(role, "risk_raw", scores.get("risk"), "risk_raw")


def avg(values):
    return sum(values) / len(values) if values else None


feasibility = avg(score_buckets["feasibility"])
robustness = avg(score_buckets["robustness"])
scalability = avg(score_buckets["scalability"])
simplicity = avg(score_buckets["simplicity"])
innovation = avg(score_buckets["innovation"])
risk_raw = avg(score_buckets["risk_raw"])
risk_normalized = None
if risk_raw is not None:
    risk_normalized = max(1.0, min(10.0, 11.0 - risk_raw))

dimension_values = {}
missing_dimensions = []

for key, value in (
    ("feasibility", feasibility),
    ("robustness", robustness),
    ("scalability", scalability),
    ("simplicity", simplicity),
    ("innovation", innovation),
    ("risk", risk_normalized),
):
    if value is None:
        missing_dimensions.append(key)
    else:
        dimension_values[key] = round(value, 2)

if risk_raw is not None:
    dimension_values["risk_raw"] = round(risk_raw, 2)

available_dims = [d for d in ("feasibility", "robustness", "scalability", "simplicity", "innovation", "risk") if d in dimension_values]
if available_dims:
    weight_sum = sum(weights[d] for d in available_dims)
    used_weights = {d: (weights[d] / weight_sum) for d in available_dims} if weight_sum > 0 else {}
    final_score = 0.0
    for d in available_dims:
        final_score += dimension_values[d] * used_weights.get(d, 0.0)
    final_score = round(final_score, 2)
else:
    used_weights = {}
    final_score = 0.0

if not available_dims:
    score_status = "insufficient"
elif execution_status == "degraded" or bool(missing_dimensions):
    score_status = "degraded"
else:
    score_status = "complete"

score_summary = {
    "status": score_status,
    "dimension_values": dimension_values,
    "used_weights": {k: round(v, 6) for k, v in used_weights.items()},
    "missing_dimensions": missing_dimensions,
    "anomalies": score_anomalies,
}

stage2_completed_roles = parse_csv_roles(stage2_completed_csv)
stage2_failed_roles = parse_csv_roles(stage2_failed_csv)
stage2_skipped_roles = parse_csv_roles(stage2_skipped_csv)


def uniq_keep_order(items):
    out = []
    seen = set()
    for item in items:
        key = item.strip()
        if not key or key in seen:
            continue
        seen.add(key)
        out.append(key)
    return out


p0_conditions = []
p1_items = []
unresolved_questions = []

if misalignment:
    p0_conditions.append("存在意图偏差：需先完成纠偏后再继续推进。")
if parse_errors:
    p0_conditions.append(f"结构化解析存在异常（{len(parse_errors)}条），需修复角色输出规范。")
if score_status in ("degraded", "insufficient"):
    p0_conditions.append(f"评分状态为 {score_status}，需补齐缺失维度或失败角色输出。")
if token_budget_exceeded.lower() == "true":
    p0_conditions.append("估算 token 超预算，需压缩输入或调整模型预算。")

for role, data in payloads.items():
    if not isinstance(data, dict):
        continue
    findings = data.get("top_findings", [])
    suggestions = data.get("top_suggestions", [])
    if isinstance(findings, list):
        for item in findings[:2]:
            if isinstance(item, str) and item.strip():
                p1_items.append(f"[{role}] {item.strip()}")
    if isinstance(suggestions, list):
        for item in suggestions[:3]:
            if isinstance(item, str) and item.strip():
                p1_items.append(f"[{role}] {item.strip()}")

p0_conditions = uniq_keep_order(p0_conditions)[:5]
p1_items = uniq_keep_order(p1_items)[:8]

if stage2_failed_roles:
    unresolved_questions.append("Stage 2 部分角色交叉复核失败，需确认失败原因是否影响结论。")
if not stage2_completed_roles:
    unresolved_questions.append("Stage 2 无有效交叉复核结果，建议补跑交叉复核。")
if missing_dimensions:
    unresolved_questions.append("存在缺失评分维度，是否需要补齐后再做最终决策。")

if stage2_status == "insufficient" or score_status == "insufficient" or final_score < 6.0:
    final_recommendation = "建议重审"
elif stage2_status == "degraded" or score_status == "degraded" or final_score < 8.0:
    final_recommendation = "建议优化后采纳"
else:
    final_recommendation = "建议采纳"

cross_review_summary = {}
for role, path in cross_review_files.items():
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    key_lines = []
    for ln in lines:
        if ln.startswith(("+", "-", "补充")):
            key_lines.append(ln)
        if len(key_lines) >= 5:
            break
    if not key_lines:
        key_lines = lines[:3]
    cross_review_summary[role] = key_lines

model_routing_summary = {}
for role, path in routing_files.items():
    model_routing_summary[role] = parse_model_routing(path)

structured = {
    "execution_status": execution_status,
    "final_score": final_score,
    "final_recommendation": final_recommendation,
    "orchestration": {
        "stage1_status": execution_status,
        "stage1_mode": "serial",
        "stage2_status": stage2_status,
        "stage2_completed_roles": stage2_completed_roles,
        "stage2_failed_roles": stage2_failed_roles,
        "stage2_skipped_roles": stage2_skipped_roles,
        "stage3_status": "complete",
        "stage3_editor": "script_editor",
    },
    "score_summary": score_summary,
    "intent_alignment_summary": {
        "misalignment_found": misalignment,
        "notes": intent_notes,
    },
    "complexity_reduction_summary": complexity_summary,
    "opensource_validation": opensource,
    "parse_diagnostics": {
        "parsed_roles": parsed_roles,
        "failed_roles": failed_roles,
        "errors": parse_errors,
    },
    "cross_review_summary": cross_review_summary,
    "model_routing_summary": model_routing_summary,
    "editor_summary": {
        "p0_conditions": p0_conditions,
        "p1_items": p1_items,
        "unresolved_questions": unresolved_questions,
    },
    "input_guard": {
        "original_chars": int(original_chars),
        "effective_chars": int(effective_chars),
        "truncated": proposal_truncated.lower() == "true",
        "max_tokens_per_role": int(max_tokens_per_role),
        "estimated_tokens_per_role": int(estimated_tokens_per_role),
        "token_budget_mode": "advisory",
        "token_budget_exceeded": token_budget_exceeded.lower() == "true",
    },
}

Path(structured_path).write_text(json.dumps(structured, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def _md_list(items, fallback):
    if not items:
        return f"1. {fallback}"
    return "\n".join(f"{idx + 1}. {item}" for idx, item in enumerate(items))


cross_md = []
for role in ("architect", "critic", "innovator"):
    points = cross_review_summary.get(role, [])
    cross_md.append(f"### {role} 交叉复核")
    if points:
        cross_md.extend([f"- {p}" for p in points])
    else:
        cross_md.append("- 无有效交叉复核内容")
cross_md_text = "\n".join(cross_md)

editor_report = f"""# 总编整合报告（Stage 3）

- Stage 1 状态：`{execution_status}`
- Stage 2 状态：`{stage2_status}`
- 最终建议语义：`{final_recommendation}`
- 综合评分：`{final_score:.2f}`

## P0 条件清单（<=5）
{_md_list(p0_conditions, "暂无，建议人工复核后确认。")}

## P1 改进清单（<=8）
{_md_list(p1_items, "暂无，建议沿用当前方案。")}

## 交叉复核摘要（Stage 2）
{cross_md_text}

## 行动项表
| 事项 | 负责人 | 截止时间 | 验收口径 |
|---|---|---|---|
| 完成 P0 条件并更新方案 | 方案作者 | 待定 | P0 项在复审中全部关闭 |
| 完成 P1 优化项并回归验证 | 评审者 | 待定 | 回归脚本通过 + 结构化摘要完整 |

## 未决问题
{_md_list(unresolved_questions, "无。")}
"""
Path(editor_path).write_text(editor_report, encoding="utf-8")

summary = f"""# 综合审查摘要

- 执行状态：`{execution_status}`
- 三段式编排：`Stage1={execution_status}, Stage2={stage2_status}, Stage3=script_editor`
- Stage1 执行方式：`serial`（避免 OpenClaw 全局模型配置覆盖冲突）
- 综合评分：`{final_score:.2f}`（自动计算，评分状态：`{score_status}`）
- 最终建议语义：`{final_recommendation}`

## 输入保护
- 原始字符数：`{original_chars}`
- 生效字符数：`{effective_chars}`
- 是否截断：`{'是' if proposal_truncated.lower() == 'true' else '否'}`
- 估算每角色 tokens：`{estimated_tokens_per_role}`（预算：`{max_tokens_per_role}`，模式：`advisory`）
- token 预算告警：`{'是' if token_budget_exceeded.lower() == 'true' else '否'}`

## 意图纠偏汇总（天条三）
- 发现偏差：`{'是' if misalignment else '否'}`
- 详情见 `structured_summary.json.intent_alignment_summary.notes`

## 开源推荐验证证据（天条四）
- 证据条数：`{len(opensource)}`

## 复杂度削减结论（天条六）
- 需要削减：`{'是' if complexity_summary['reduction_required'] else '否'}`
- 建议条数：`{len(complexity_summary['items'])}`
- 结构化来源角色数：`{complexity_summary['source_breakdown']['structured_field_roles']}`
- 回退提取角色数：`{complexity_summary['source_breakdown']['fallback_extracted_roles']}`

## 解析诊断
- 成功解析角色：`{len(parsed_roles)}`
- 解析失败角色：`{len(failed_roles)}`
- 解析告警数：`{len(parse_errors)}`
- 评分异常数：`{len(score_anomalies)}`

## Stage 2 交叉复核
- 完成角色：`{len(stage2_completed_roles)}`
- 失败角色：`{len(stage2_failed_roles)}`
- 跳过角色：`{len(stage2_skipped_roles)}`

## 模型路由摘要
- architect：尝试 `{' -> '.join(model_routing_summary['architect']['models_tried']) if model_routing_summary['architect']['models_tried'] else '无'}`，成功模型 `'{model_routing_summary['architect']['final_success_model'] or '无'}'`，切换原因 `'{', '.join(model_routing_summary['architect']['switch_reasons']) if model_routing_summary['architect']['switch_reasons'] else '无'}'`
- critic：尝试 `{' -> '.join(model_routing_summary['critic']['models_tried']) if model_routing_summary['critic']['models_tried'] else '无'}`，成功模型 `'{model_routing_summary['critic']['final_success_model'] or '无'}'`，切换原因 `'{', '.join(model_routing_summary['critic']['switch_reasons']) if model_routing_summary['critic']['switch_reasons'] else '无'}'`
- innovator：尝试 `{' -> '.join(model_routing_summary['innovator']['models_tried']) if model_routing_summary['innovator']['models_tried'] else '无'}`，成功模型 `'{model_routing_summary['innovator']['final_success_model'] or '无'}'`，切换原因 `'{', '.join(model_routing_summary['innovator']['switch_reasons']) if model_routing_summary['innovator']['switch_reasons'] else '无'}'`

## 角色报告
- architect_review.md
- critic_review.md
- innovator_review.md
- architect_cross_review.md
- critic_cross_review.md
- innovator_cross_review.md
- editor_review.md
"""
Path(summary_path).write_text(summary, encoding="utf-8")
PY

echo "Review finished: ${out_dir}"
