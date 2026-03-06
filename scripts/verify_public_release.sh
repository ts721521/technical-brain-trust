#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="."
MANIFEST_FILE=""
ENFORCE_MANIFEST="false"

usage() {
  cat <<'USAGE'
Usage: verify_public_release.sh [options]

Options:
  --root <path>              Root directory to scan (default: .)
  --manifest <path>          Optional release manifest file
  --enforce-manifest         Fail if tracked files are outside manifest
  -h, --help                 Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT_DIR="${2:-}"
      shift 2
      ;;
    --manifest)
      MANIFEST_FILE="${2:-}"
      shift 2
      ;;
    --enforce-manifest)
      ENFORCE_MANIFEST="true"
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

ROOT_DIR="$(cd "${ROOT_DIR}" && pwd)"
if [[ -n "${MANIFEST_FILE}" && ! "${MANIFEST_FILE}" = /* ]]; then
  MANIFEST_FILE="${ROOT_DIR}/${MANIFEST_FILE}"
fi

if [[ -n "${MANIFEST_FILE}" && ! -f "${MANIFEST_FILE}" ]]; then
  echo "manifest file not found: ${MANIFEST_FILE}" >&2
  exit 1
fi

if [[ ! -d "${ROOT_DIR}" ]]; then
  echo "root directory not found: ${ROOT_DIR}" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

FAILURES_FILE="${TMP_DIR}/failures.txt"
: > "${FAILURES_FILE}"

record_failure() {
  printf '%s\n' "$1" >>"${FAILURES_FILE}"
}

tracked_file_list_file="${TMP_DIR}/tracked_files.list"
if git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "${ROOT_DIR}" ls-files >"${tracked_file_list_file}"
else
  (
    cd "${ROOT_DIR}"
    find . -type f | sed 's#^\./##'
  ) >"${tracked_file_list_file}"
fi

# 1) Runtime artifact pollution in tracked files
while IFS= read -r f; do
  [[ -z "${f}" ]] && continue
  if [[ "${f}" =~ (^reviews/|^tmp/|\.stderr$|\.bak$|(^|/)\.env$|(^|/)\.env\.) ]]; then
    record_failure "forbidden tracked runtime file: ${f}"
  fi
done <"${tracked_file_list_file}"

# 2) Secret and token patterns
check_pattern() {
  local pattern="$1"
  local label="$2"
  local out_file="${TMP_DIR}/${label}.txt"
  : >"${out_file}"
  while IFS= read -r rel; do
    [[ -z "${rel}" ]] && continue
    [[ "${rel}" == ".git" ]] && continue
    if [[ "${label}" == "absolute_user_path" || "${label}" == "absolute_home_path" ]]; then
      [[ "${rel}" == "scripts/verify_public_release.sh" ]] && continue
    fi
    local abs="${ROOT_DIR}/${rel}"
    [[ -f "${abs}" ]] || continue
    rg -n --no-ignore-vcs -I "${pattern}" "${abs}" >>"${out_file}" 2>/dev/null || true
  done <"${tracked_file_list_file}"
  if [[ -s "${out_file}" ]]; then
    while IFS= read -r line; do
      record_failure "${label}: ${line}"
    done <"${out_file}"
  fi
}

check_pattern 'sk-[A-Za-z0-9]{20,}' 'secret_openai_style'
check_pattern 'BEGIN (RSA|OPENSSH|EC) PRIVATE KEY' 'private_key_block'
# Literal credential detector: keep this narrow to avoid false positives on
# command substitution or variable expansion (for example token="$(...)" / "${TOKEN}").
check_pattern '(?i)(api[_-]?key|token|password|secret)\s*[:=]\s*["\x27][A-Za-z0-9._~+/=:@-]{8,}["\x27]' 'hardcoded_credential_like'

# 3) Personal absolute path leakage and local auth-profile copy hints
check_pattern '/Users/[A-Za-z0-9._-]+/' 'absolute_user_path'
check_pattern '/home/[A-Za-z0-9._-]+/' 'absolute_home_path'
check_pattern 'auth-profiles\.json' 'local_auth_profiles_reference'

# 4) Manifest enforcement (for release branch)
if [[ "${ENFORCE_MANIFEST}" == "true" ]]; then
  if [[ -z "${MANIFEST_FILE}" ]]; then
    record_failure "manifest enforcement enabled but --manifest not provided"
  else
    manifest_resolved="${TMP_DIR}/manifest.resolved"
    : >"${manifest_resolved}"
    while IFS= read -r line; do
      line="${line%%#*}"
      line="${line%$'\r'}"
      line="$(printf '%s' "${line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [[ -z "${line}" ]] && continue
      printf '%s\n' "${line}" >>"${manifest_resolved}"
    done <"${MANIFEST_FILE}"

    tracked_file_list="${TMP_DIR}/tracked.list"
    sort "${tracked_file_list_file}" >"${tracked_file_list}"
    sort -u "${manifest_resolved}" >"${manifest_resolved}.sorted"

    while IFS= read -r tracked; do
      [[ -z "${tracked}" ]] && continue
      if ! rg -qx --fixed-strings "${tracked}" "${manifest_resolved}.sorted"; then
        record_failure "tracked file not in manifest: ${tracked}"
      fi
    done <"${tracked_file_list}"
  fi
fi

if [[ -s "${FAILURES_FILE}" ]]; then
  echo "public release verification failed:" >&2
  sed 's/^/  - /' "${FAILURES_FILE}" >&2
  exit 1
fi

echo "public release verification passed: ${ROOT_DIR}"
