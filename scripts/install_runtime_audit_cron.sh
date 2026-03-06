#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT_SCRIPT="${ROOT_DIR}/scripts/runtime_health_audit.sh"
MARKER="# BT_RUNTIME_AUDIT"

DOCS_ROOT="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
TEAM_ID="${BT_TEAM_ID:-team-brain-trust}"
ENABLE_NOTIFY="true"
REMOVE_ONLY="false"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--docs-root <path>] [--team <team-id>] [--notify true|false] [--remove]

Install daily 05:00 cron entry:
  0 5 * * * <repo>/scripts/runtime_health_audit.sh --slot-time 050000 ...
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --docs-root)
      DOCS_ROOT="${2:-}"
      shift 2
      ;;
    --team)
      TEAM_ID="${2:-}"
      shift 2
      ;;
    --notify)
      ENABLE_NOTIFY="${2:-}"
      shift 2
      ;;
    --remove)
      REMOVE_ONLY="true"
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

if [[ ! -x "${AUDIT_SCRIPT}" ]]; then
  echo "missing executable script: ${AUDIT_SCRIPT}" >&2
  exit 1
fi

if ! command -v crontab >/dev/null 2>&1; then
  echo "crontab command not found" >&2
  exit 1
fi

current="$(crontab -l 2>/dev/null || true)"
filtered="$(printf "%s\n" "${current}" | rg -v "${MARKER}" || true)"

if [[ "${REMOVE_ONLY}" == "true" ]]; then
  printf "%s\n" "${filtered}" | crontab -
  echo "removed runtime audit cron entry"
  exit 0
fi

entry="0 5 * * * cd ${ROOT_DIR} && BT_DOCS_ROOT='${DOCS_ROOT}' BT_TEAM_ID='${TEAM_ID}' ${AUDIT_SCRIPT} --slot-time 050000 --notify ${ENABLE_NOTIFY} >> ${DOCS_ROOT}/${TEAM_ID}/ops/runtime_audit_cron.log 2>&1 ${MARKER}"

{
  printf "%s\n" "${filtered}"
  printf "%s\n" "${entry}"
} | awk 'NF' | crontab -

echo "installed runtime audit cron entry"
crontab -l | rg "${MARKER}" -n || true
