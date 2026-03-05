#!/usr/bin/env bash
set -euo pipefail

mode="check-only"
record_path=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--check-only|--apply] [--record <path>]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only)
      mode="check-only"
      shift
      ;;
    --apply)
      mode="apply"
      shift
      ;;
    --record)
      record_path="${2:-}"
      shift 2
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

require_env() {
  local key="$1"
  if [[ -z "${!key:-}" ]]; then
    echo "Missing required env var: ${key}" >&2
    exit 1
  fi
}

for key in \
  BT_ARCHITECT_MODEL BT_ARCHITECT_FALLBACK_1 BT_ARCHITECT_FALLBACK_2 BT_ARCHITECT_FALLBACK_3 \
  BT_CRITIC_MODEL BT_CRITIC_FALLBACK_1 BT_CRITIC_FALLBACK_2 BT_CRITIC_FALLBACK_3 \
  BT_INNOVATOR_MODEL BT_INNOVATOR_FALLBACK_1 BT_INNOVATOR_FALLBACK_2 BT_INNOVATOR_FALLBACK_3; do
  require_env "${key}"
done

openai_allowed="openai-codex/gpt-5.3-codex"
for key in \
  BT_ARCHITECT_MODEL BT_ARCHITECT_FALLBACK_1 BT_ARCHITECT_FALLBACK_2 BT_ARCHITECT_FALLBACK_3 \
  BT_CRITIC_MODEL BT_CRITIC_FALLBACK_1 BT_CRITIC_FALLBACK_2 BT_CRITIC_FALLBACK_3 \
  BT_INNOVATOR_MODEL BT_INNOVATOR_FALLBACK_1 BT_INNOVATOR_FALLBACK_2 BT_INNOVATOR_FALLBACK_3; do
  value="${!key}"
  if [[ "${value}" == openai-codex/* && "${value}" != "${openai_allowed}" ]]; then
    echo "OpenAI model hard constraint violated (${key}=${value}); only ${openai_allowed} is allowed." >&2
    exit 1
  fi
done

available_models=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && available_models+=("${line}")
done < <(python3 - <<'PY'
import subprocess

try:
    out = subprocess.check_output(["openclaw", "models", "list"], text=True, stderr=subprocess.STDOUT)
except Exception:
    raise SystemExit(1)

for line in out.splitlines():
    s = line.strip()
    if not s or s.startswith("Model "):
        continue
    token = s.split()[0]
    if "/" in token:
        print(token)
PY
)

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

get_primary() {
  local role="$1"
  case "${role}" in
    architect) echo "${BT_ARCHITECT_MODEL}" ;;
    critic) echo "${BT_CRITIC_MODEL}" ;;
    innovator) echo "${BT_INNOVATOR_MODEL}" ;;
    *) return 1 ;;
  esac
}

get_fallbacks() {
  local role="$1"
  case "${role}" in
    architect) printf "%s\n" "${BT_ARCHITECT_FALLBACK_1}" "${BT_ARCHITECT_FALLBACK_2}" "${BT_ARCHITECT_FALLBACK_3}" ;;
    critic) printf "%s\n" "${BT_CRITIC_FALLBACK_1}" "${BT_CRITIC_FALLBACK_2}" "${BT_CRITIC_FALLBACK_3}" ;;
    innovator) printf "%s\n" "${BT_INNOVATOR_FALLBACK_1}" "${BT_INNOVATOR_FALLBACK_2}" "${BT_INNOVATOR_FALLBACK_3}" ;;
    *) return 1 ;;
  esac
}

verify_chain_models() {
  local role="$1"
  shift
  local models=("$@")
  local model
  for model in "${models[@]}"; do
    if ! contains_model "${model}"; then
      echo "Role ${role} references unavailable model: ${model}" >&2
      return 1
    fi
  done
}

read_global_primary() {
  openclaw models status --plain 2>/dev/null | tail -n 1 | tr -d '\r'
}

read_global_fallbacks() {
  openclaw models fallbacks list 2>/dev/null | sed -n '2,$p' | sed 's/^- //'
}

architect_primary="$(get_primary "architect")"
architect_fallbacks=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && architect_fallbacks+=("${line}")
done < <(get_fallbacks "architect")

verify_chain_models "architect" "${architect_primary}" "${architect_fallbacks[@]}"
for role in critic innovator; do
  role_primary="$(get_primary "${role}")"
  role_fallbacks=()
  while IFS= read -r line; do
    [[ -n "${line}" ]] && role_fallbacks+=("${line}")
  done < <(get_fallbacks "${role}")
  verify_chain_models "${role}" "${role_primary}" "${role_fallbacks[@]}"
done

before_primary="$(read_global_primary || true)"
before_fallbacks=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && before_fallbacks+=("${line}")
done < <(read_global_fallbacks || true)

mismatch=0
if [[ "${before_primary}" != "${architect_primary}" ]]; then
  mismatch=1
fi
if (( ${#before_fallbacks[@]} != ${#architect_fallbacks[@]} )); then
  mismatch=1
else
  for i in "${!architect_fallbacks[@]}"; do
    if [[ "${before_fallbacks[$i]:-}" != "${architect_fallbacks[$i]}" ]]; then
      mismatch=1
      break
    fi
  done
fi

after_primary="${before_primary}"
after_fallbacks=("${before_fallbacks[@]}")
if (( mismatch == 1 )) && [[ "${mode}" == "apply" ]]; then
  openclaw models set "${architect_primary}" >/dev/null
  openclaw models fallbacks clear >/dev/null
  for fb in "${architect_fallbacks[@]}"; do
    openclaw models fallbacks add "${fb}" >/dev/null
  done
  after_primary="$(read_global_primary || true)"
  after_fallbacks=()
  while IFS= read -r line; do
    [[ -n "${line}" ]] && after_fallbacks+=("${line}")
  done < <(read_global_fallbacks || true)
fi

if [[ -n "${record_path}" ]]; then
  python3 - "${record_path}" "${mode}" "${mismatch}" "${before_primary}" "${after_primary}" "$(printf "%s\n" "${before_fallbacks[@]-}")" "$(printf "%s\n" "${after_fallbacks[@]-}")" <<'PY'
import json
import os
import sys
from datetime import datetime
from pathlib import Path

record_path = Path(sys.argv[1])
mode = sys.argv[2]
mismatch = bool(int(sys.argv[3]))
before_primary = sys.argv[4]
after_primary = sys.argv[5]
before_fallbacks = [x for x in sys.argv[6].splitlines() if x.strip()]
after_fallbacks = [x for x in sys.argv[7].splitlines() if x.strip()]

payload = {
    "timestamp": datetime.utcnow().isoformat() + "Z",
    "mode": mode,
    "mismatch_detected": mismatch,
    "semantics": "OpenClaw model defaults are global; role-specific model routing is applied at run time by run_brain_trust_review.sh.",
    "baseline_role": "architect",
    "baseline_chain": {
        "primary": os.environ.get("BT_ARCHITECT_MODEL", ""),
        "fallbacks": [
            os.environ.get("BT_ARCHITECT_FALLBACK_1", ""),
            os.environ.get("BT_ARCHITECT_FALLBACK_2", ""),
            os.environ.get("BT_ARCHITECT_FALLBACK_3", ""),
        ],
    },
    "global_before": {
        "primary": before_primary,
        "fallbacks": before_fallbacks,
    },
    "global_after": {
        "primary": after_primary,
        "fallbacks": after_fallbacks,
    },
    "roles": {
        "architect": {
            "primary": os.environ.get("BT_ARCHITECT_MODEL", ""),
            "fallbacks": [
                os.environ.get("BT_ARCHITECT_FALLBACK_1", ""),
                os.environ.get("BT_ARCHITECT_FALLBACK_2", ""),
                os.environ.get("BT_ARCHITECT_FALLBACK_3", ""),
            ],
        },
        "critic": {
            "primary": os.environ.get("BT_CRITIC_MODEL", ""),
            "fallbacks": [
                os.environ.get("BT_CRITIC_FALLBACK_1", ""),
                os.environ.get("BT_CRITIC_FALLBACK_2", ""),
                os.environ.get("BT_CRITIC_FALLBACK_3", ""),
            ],
        },
        "innovator": {
            "primary": os.environ.get("BT_INNOVATOR_MODEL", ""),
            "fallbacks": [
                os.environ.get("BT_INNOVATOR_FALLBACK_1", ""),
                os.environ.get("BT_INNOVATOR_FALLBACK_2", ""),
                os.environ.get("BT_INNOVATOR_FALLBACK_3", ""),
            ],
        },
    },
}
record_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
fi

if [[ "${mode}" == "check-only" && "${mismatch}" -eq 1 ]]; then
  echo "Global model baseline mismatch detected (architect chain)." >&2
  exit 2
fi

echo "Brain Trust model sync ${mode} passed."
