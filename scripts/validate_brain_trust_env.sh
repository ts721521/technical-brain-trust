#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/config/brain_trust_config.yaml"

required_envs=(
  BT_ARCHITECT_MODEL
  BT_ARCHITECT_FALLBACK_1
  BT_ARCHITECT_FALLBACK_2
  BT_ARCHITECT_FALLBACK_3
  BT_CRITIC_MODEL
  BT_CRITIC_FALLBACK_1
  BT_CRITIC_FALLBACK_2
  BT_CRITIC_FALLBACK_3
  BT_INNOVATOR_MODEL
  BT_INNOVATOR_FALLBACK_1
  BT_INNOVATOR_FALLBACK_2
  BT_INNOVATOR_FALLBACK_3
)

missing=()
for key in "${required_envs[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    missing+=("${key}")
  fi
done

if (( ${#missing[@]} > 0 )); then
  printf 'Missing required env vars:\n' >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

if [[ "${BT_ARCHITECT_MODEL}" == "${BT_CRITIC_MODEL}" || \
      "${BT_ARCHITECT_MODEL}" == "${BT_INNOVATOR_MODEL}" || \
      "${BT_CRITIC_MODEL}" == "${BT_INNOVATOR_MODEL}" ]]; then
  echo "Primary role models must be different: BT_ARCHITECT_MODEL, BT_CRITIC_MODEL, BT_INNOVATOR_MODEL" >&2
  exit 1
fi

required_yaml_keys=(
  "max_proposal_chars"
  "timeout_per_role_seconds"
  "retry:"
  "max_attempts"
  "degradation:"
  "min_roles_required"
  "execution:"
  "enabled:"
  "executor_agent:"
  "timeout_seconds:"
  "on_failure:"
  "scheduler:"
  "scope:"
  "max_inflight:"
  "queue_max:"
  "backlog_scale_threshold:"
  "dispatch_timeout_seconds:"
  "output:"
  "docs_root:"
  "team_id:"
  "path_policy:"
  "max_depth_after_root:"
  "index_file_policy:"
  "relative_path:"
)

for key in "${required_yaml_keys[@]}"; do
  if ! rg -q "${key}" "${CONFIG_FILE}"; then
    echo "Missing required runtime key in config: ${key}" >&2
    exit 1
  fi
done

python3 - "${CONFIG_FILE}" <<'PY'
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
    if re.fullmatch(r"-?\d+", val):
        return int(val)
    if re.fullmatch(r"-?\d+\.\d+", val):
        return float(val)
    lowered = val.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    return val


cfg_path = Path(sys.argv[1])
root = {}
stack = [(-1, root)]

for raw_line in cfg_path.read_text(encoding="utf-8").splitlines():
    if not raw_line.strip() or raw_line.lstrip().startswith("#"):
        continue
    indent = len(raw_line) - len(raw_line.lstrip(" "))
    content = strip_inline_comment(raw_line.lstrip(" "))
    if not content or content.startswith("- ") or ":" not in content:
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


def get(path: str):
    node = root
    for part in path.split("."):
        if not isinstance(node, dict) or part not in node:
            return None
        node = node[part]
    return node


checks = {
    "runtime.scheduler.max_inflight": lambda v: isinstance(v, int) and v >= 1,
    "runtime.scheduler.queue_max": lambda v: isinstance(v, int) and v >= 1,
    "runtime.scheduler.backlog_scale_threshold": lambda v: isinstance(v, int) and v >= 1,
    "runtime.scheduler.dispatch_timeout_seconds": lambda v: isinstance(v, int) and v >= 1,
    "runtime.scheduler.retry.max_attempts": lambda v: isinstance(v, int) and v >= 1,
    "runtime.scheduler.retry.backoff_seconds": lambda v: isinstance(v, (int, float)) and v >= 0,
    "output.path_policy.max_depth_after_root": lambda v: isinstance(v, int) and v == 3,
}

for key, fn in checks.items():
    value = get(key)
    if not fn(value):
        print(f"Invalid scheduler config value: {key}={value}", file=sys.stderr)
        raise SystemExit(1)

scope = get("runtime.scheduler.scope")
if scope != "execution_heavy_only":
    print(f"Invalid runtime.scheduler.scope: {scope}", file=sys.stderr)
    raise SystemExit(1)

docs_root = get("output.docs_root")
if not isinstance(docs_root, str) or not docs_root.strip():
    print("Invalid output.docs_root", file=sys.stderr)
    raise SystemExit(1)

team_id = get("output.team_id")
if not isinstance(team_id, str) or not re.fullmatch(r"team-[a-z0-9]+(-[a-z0-9]+)*", team_id):
    print(f"Invalid output.team_id: {team_id}", file=sys.stderr)
    raise SystemExit(1)

index_path = get("output.index_file_policy.relative_path")
if not isinstance(index_path, str) or "<yyyymm>" not in index_path:
    print(f"Invalid output.index_file_policy.relative_path: {index_path}", file=sys.stderr)
    raise SystemExit(1)
PY

docs_root_runtime="${BT_DOCS_ROOT:-}"
if [[ -z "${docs_root_runtime}" ]]; then
  docs_root_runtime="$(python3 - "${CONFIG_FILE}" <<'PY'
import re
import sys
from pathlib import Path
txt = Path(sys.argv[1]).read_text(encoding="utf-8")
m = re.search(r'^\s*docs_root:\s*"?([^"\n]+)"?\s*$', txt, flags=re.M)
print(m.group(1).strip() if m else "")
PY
)"
fi

if [[ -z "${docs_root_runtime}" || ! -d "${docs_root_runtime}" || ! -w "${docs_root_runtime}" ]]; then
  echo "Business docs root unavailable or not writable: ${docs_root_runtime:-<empty>}" >&2
  echo "Set BT_DOCS_ROOT to a writable mounted path before running." >&2
  exit 1
fi

available_models=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && available_models+=("${line}")
done < <(python3 - <<'PY'
import subprocess
import sys

try:
    out = subprocess.check_output(["openclaw", "models", "list"], text=True, stderr=subprocess.STDOUT)
except Exception as e:
    print(f"__ERROR__{e}")
    raise SystemExit(0)

for line in out.splitlines():
    stripped = line.strip()
    if not stripped or stripped.startswith("Model "):
        continue
    first = stripped.split()[0]
    if "/" in first:
        print(first)
PY
)

if (( ${#available_models[@]} == 0 )); then
  echo "Failed to read available models from: openclaw models list" >&2
  exit 1
fi

contains_model() {
  local target="$1"
  local m
  for m in "${available_models[@]}"; do
    if [[ "${m}" == "${target}" ]]; then
      return 0
    fi
  done
  return 1
}

invalid_models=()
for key in "${required_envs[@]}"; do
  if ! contains_model "${!key}"; then
    invalid_models+=("${key}=${!key}")
  fi
done

if (( ${#invalid_models[@]} > 0 )); then
  printf 'Model ids not found in `openclaw models list`:\n' >&2
  printf '  - %s\n' "${invalid_models[@]}" >&2
  exit 1
fi

openai_allowed="openai-codex/gpt-5.3-codex"
openai_violations=()
for key in "${required_envs[@]}"; do
  value="${!key}"
  if [[ "${value}" == openai-codex/* && "${value}" != "${openai_allowed}" ]]; then
    openai_violations+=("${key}=${value}")
  fi
done

if (( ${#openai_violations[@]} > 0 )); then
  echo "OpenAI model hard constraint violated: only ${openai_allowed} is allowed." >&2
  printf '  - %s\n' "${openai_violations[@]}" >&2
  exit 1
fi

required_agents=(architect critic innovator pangu luban braintrust_compliance wenquxing knowledge_manager rd_lead scholar feige_notifier)

agents_json_output="$(openclaw agents list --json 2>/dev/null || true)"
agents_plain_output="$(openclaw agents list 2>/dev/null || true)"

agent_exists() {
  local target="$1"
  if [[ -n "${agents_json_output}" ]] && python3 - "${target}" "${agents_json_output}" <<'PY'
import json
import sys

target = sys.argv[1]
raw = sys.argv[2].strip()
if not raw:
    raise SystemExit(1)
try:
    data = json.loads(raw)
except Exception:
    raise SystemExit(1)
if isinstance(data, list):
    for item in data:
        if isinstance(item, dict) and item.get("id") == target:
            raise SystemExit(0)
raise SystemExit(1)
PY
  then
    return 0
  fi

  if printf '%s\n' "${agents_plain_output}" | rg -q -- "(^- ${target}(\\s|$)|\"id\"\\s*:\\s*\"${target}\"|\\b${target}\\b)"; then
    return 0
  fi
  return 1
}

for role in "${required_agents[@]}"; do
  if ! agent_exists "${role}"; then
    echo "Missing required agent: ${role}. Run openclaw agents add ${role} ..." >&2
    exit 1
  fi
done

check_provider_coverage() {
  local role="$1"
  shift
  local models=("$@")
  local has_openai="false"
  local has_google="false"
  local has_zai="false"
  local has_bailian="false"
  local model provider

  for model in "${models[@]}"; do
    provider="${model%%/*}"
    case "${provider}" in
      openai-codex) has_openai="true" ;;
      google-gemini-cli) has_google="true" ;;
      zai) has_zai="true" ;;
      bailian) has_bailian="true" ;;
    esac
  done

  if [[ "${has_openai}" != "true" || "${has_google}" != "true" || "${has_zai}" != "true" || "${has_bailian}" != "true" ]]; then
    echo "Role ${role} does not cover all 4 providers (openai-codex/google-gemini-cli/zai/bailian)." >&2
    echo "Current chain: ${models[*]}" >&2
    return 1
  fi
}

check_provider_coverage "architect" \
  "${BT_ARCHITECT_MODEL}" "${BT_ARCHITECT_FALLBACK_1}" "${BT_ARCHITECT_FALLBACK_2}" "${BT_ARCHITECT_FALLBACK_3}"
check_provider_coverage "critic" \
  "${BT_CRITIC_MODEL}" "${BT_CRITIC_FALLBACK_1}" "${BT_CRITIC_FALLBACK_2}" "${BT_CRITIC_FALLBACK_3}"
check_provider_coverage "innovator" \
  "${BT_INNOVATOR_MODEL}" "${BT_INNOVATOR_FALLBACK_1}" "${BT_INNOVATOR_FALLBACK_2}" "${BT_INNOVATOR_FALLBACK_3}"

echo "Brain Trust env/config validation passed."
