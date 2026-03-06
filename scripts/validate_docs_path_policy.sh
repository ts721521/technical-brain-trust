#!/usr/bin/env bash
set -euo pipefail

DOCS_ROOT="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
OUT_DIR=""
MAX_DEPTH=3
TEAM_PATTERN='^team-[a-z0-9]+(-[a-z0-9]+)*$'
FILE_PATTERN='^[a-z0-9]+(-[a-z0-9]+)*-[0-9]{8}-[0-9]{6}\.[a-z0-9]+$'
FILENAMES=""

usage() {
  cat <<'USAGE'
Usage: validate_docs_path_policy.sh --out <dir> [options]

Options:
  --docs-root <path>   Docs root path (default: $BT_DOCS_ROOT or /Volumes/TB512/3_ClawDocs)
  --out <path>         Business artifact output directory to validate
  --filenames <csv>    Optional file names to validate against naming rule
  --max-depth <n>      Max depth after docs root (default: 3)
  -h, --help           Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --docs-root)
      DOCS_ROOT="${2:-}"
      shift 2
      ;;
    --out)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    --filenames)
      FILENAMES="${2:-}"
      shift 2
      ;;
    --max-depth)
      MAX_DEPTH="${2:-}"
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

if [[ -z "${OUT_DIR}" ]]; then
  echo '{"ok":false,"error_code":"path_policy_violation","message":"missing --out"}'
  exit 2
fi

if ! [[ "${MAX_DEPTH}" =~ ^[0-9]+$ ]] || (( MAX_DEPTH < 1 )); then
  echo '{"ok":false,"error_code":"path_policy_violation","message":"invalid --max-depth"}'
  exit 2
fi

if [[ ! -d "${DOCS_ROOT}" ]]; then
  echo "{\"ok\":false,\"error_code\":\"docs_root_unavailable\",\"message\":\"docs_root does not exist: ${DOCS_ROOT}\",\"retry_hint\":\"export BT_DOCS_ROOT=<mounted_path> && retry\"}"
  exit 3
fi

if [[ ! -w "${DOCS_ROOT}" ]]; then
  echo "{\"ok\":false,\"error_code\":\"docs_root_unavailable\",\"message\":\"docs_root is not writable: ${DOCS_ROOT}\",\"retry_hint\":\"chmod/chown docs root or export BT_DOCS_ROOT and retry\"}"
  exit 3
fi

root_abs="$(cd "${DOCS_ROOT}" && pwd)"

if [[ "${OUT_DIR}" = /* ]]; then
  out_abs="${OUT_DIR}"
else
  out_abs="$(cd "$(dirname "${OUT_DIR}")" && pwd)/$(basename "${OUT_DIR}")"
fi

case "${out_abs}" in
  "${root_abs}"/*) ;;
  *)
    echo "{\"ok\":false,\"error_code\":\"path_policy_violation\",\"message\":\"out_dir is outside docs_root\",\"docs_root\":\"${root_abs}\",\"out_dir\":\"${out_abs}\"}"
    exit 2
    ;;
esac

rel="${out_abs#${root_abs}/}"
IFS='/' read -r -a parts <<< "${rel}"

if (( ${#parts[@]} != MAX_DEPTH )); then
  echo "{\"ok\":false,\"error_code\":\"depth_exceeded\",\"message\":\"expected exactly ${MAX_DEPTH} levels after docs_root\",\"relative\":\"${rel}\"}"
  exit 4
fi

team="${parts[0]}"
artifact="${parts[1]}"
yyyymm="${parts[2]}"

if ! [[ "${team}" =~ ${TEAM_PATTERN} ]]; then
  echo "{\"ok\":false,\"error_code\":\"path_policy_violation\",\"message\":\"invalid team segment\",\"team\":\"${team}\"}"
  exit 2
fi

artifact_ok="false"
case "${artifact}" in
  review|execution|deploy|release|evidence|ops)
    artifact_ok="true"
    ;;
  custom-*)
    if [[ "${artifact}" =~ ^custom-[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
      artifact_ok="true"
    fi
    ;;
esac

if [[ "${artifact_ok}" != "true" ]]; then
  echo "{\"ok\":false,\"error_code\":\"path_policy_violation\",\"message\":\"invalid artifact segment\",\"artifact\":\"${artifact}\"}"
  exit 2
fi

if ! [[ "${yyyymm}" =~ ^[0-9]{6}$ ]]; then
  echo "{\"ok\":false,\"error_code\":\"path_policy_violation\",\"message\":\"invalid yyyymm segment\",\"yyyymm\":\"${yyyymm}\"}"
  exit 2
fi

if [[ -n "${FILENAMES}" ]]; then
  IFS=',' read -r -a names <<< "${FILENAMES}"
  for name in "${names[@]}"; do
    trimmed="$(echo "${name}" | xargs)"
    [[ -z "${trimmed}" ]] && continue
    if ! [[ "${trimmed}" =~ ${FILE_PATTERN} ]]; then
      echo "{\"ok\":false,\"error_code\":\"path_policy_violation\",\"message\":\"invalid filename\",\"filename\":\"${trimmed}\"}"
      exit 2
    fi
  done
fi

echo "{\"ok\":true,\"docs_root\":\"${root_abs}\",\"team\":\"${team}\",\"artifact\":\"${artifact}\",\"yyyymm\":\"${yyyymm}\",\"out_dir\":\"${out_abs}\"}"
