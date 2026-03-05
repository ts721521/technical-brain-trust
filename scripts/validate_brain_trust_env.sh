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
)

for key in "${required_yaml_keys[@]}"; do
  if ! rg -q "${key}" "${CONFIG_FILE}"; then
    echo "Missing required runtime key in config: ${key}" >&2
    exit 1
  fi
done

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

agents_output="$(openclaw agents list 2>/dev/null || true)"
for role in architect critic innovator; do
  if ! printf '%s\n' "${agents_output}" | rg -q -- "- ${role}$"; then
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
