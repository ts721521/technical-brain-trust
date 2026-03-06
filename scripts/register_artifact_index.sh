#!/usr/bin/env bash
set -euo pipefail

DOCS_ROOT="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
TEAM_ID="team-brain-trust"
ARTIFACT="review"
TOPIC="general"
ARTIFACT_PATH=""
PRODUCER_SCRIPT=""
STATUS="success"
HASH_SHA256=""

usage() {
  cat <<'USAGE'
Usage: register_artifact_index.sh --path <artifact_path> --producer-script <path_or_name> [options]

Options:
  --docs-root <path>       Docs root (default: $BT_DOCS_ROOT or /Volumes/TB512/3_ClawDocs)
  --team <team-id>         Team id (default: team-brain-trust)
  --artifact <name>        Artifact class (default: review)
  --topic <topic>          Topic label (default: general)
  --path <artifact_path>   Artifact absolute path (required)
  --producer-script <id>   Producer script id/path (required)
  --status <value>         status value (default: success)
  --hash <sha256>          Optional precomputed sha256
  -h, --help               Show help
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
    --artifact)
      ARTIFACT="${2:-}"
      shift 2
      ;;
    --topic)
      TOPIC="${2:-}"
      shift 2
      ;;
    --path)
      ARTIFACT_PATH="${2:-}"
      shift 2
      ;;
    --producer-script)
      PRODUCER_SCRIPT="${2:-}"
      shift 2
      ;;
    --status)
      STATUS="${2:-}"
      shift 2
      ;;
    --hash)
      HASH_SHA256="${2:-}"
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

if [[ -z "${ARTIFACT_PATH}" || -z "${PRODUCER_SCRIPT}" ]]; then
  echo "--path and --producer-script are required" >&2
  exit 1
fi

artifact_ok="false"
case "${ARTIFACT}" in
  review|execution|deploy|release|evidence|ops)
    artifact_ok="true"
    ;;
  custom-*)
    if [[ "${ARTIFACT}" =~ ^custom-[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
      artifact_ok="true"
    fi
    ;;
esac
if [[ "${artifact_ok}" != "true" ]]; then
  echo "invalid --artifact: ${ARTIFACT}. Use review|execution|deploy|release|evidence|ops|custom-<kebab>." >&2
  exit 1
fi

if [[ ! -d "${DOCS_ROOT}" || ! -w "${DOCS_ROOT}" ]]; then
  echo "docs root unavailable: ${DOCS_ROOT}" >&2
  exit 2
fi

if [[ -z "${HASH_SHA256}" && -f "${ARTIFACT_PATH}" ]]; then
  HASH_SHA256="$(shasum -a 256 "${ARTIFACT_PATH}" | awk '{print $1}')"
fi

yyyymm="$(date +%Y%m)"
index_dir="${DOCS_ROOT}/${TEAM_ID}/ops/${yyyymm}"
index_file="${index_dir}/artifact_index.jsonl"
mkdir -p "${index_dir}"

python3 - "${index_file}" "${TEAM_ID}" "${ARTIFACT}" "${TOPIC}" "${ARTIFACT_PATH}" "${PRODUCER_SCRIPT}" "${STATUS}" "${HASH_SHA256}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

index_file = Path(sys.argv[1])
row = {
    "timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "team": sys.argv[2],
    "artifact": sys.argv[3],
    "topic": sys.argv[4],
    "path": sys.argv[5],
    "producer_script": sys.argv[6],
    "status": sys.argv[7],
    "hash_sha256": sys.argv[8] or None,
}
with index_file.open("a", encoding="utf-8") as f:
    f.write(json.dumps(row, ensure_ascii=False) + "\n")
print(json.dumps({"ok": True, "index_file": str(index_file), "row": row}, ensure_ascii=False))
PY
