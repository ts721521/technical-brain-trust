#!/usr/bin/env bash
set -euo pipefail

INDEX_FILE=""

usage() {
  cat <<'USAGE'
Usage: validate_artifact_index_format.sh --index <path>
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --index)
      INDEX_FILE="${2:-}"
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

if [[ -z "${INDEX_FILE}" || ! -f "${INDEX_FILE}" ]]; then
  echo "index file not found: ${INDEX_FILE}" >&2
  exit 1
fi

python3 - "${INDEX_FILE}" <<'PY'
import json
import sys
from pathlib import Path

idx = Path(sys.argv[1])
required = ["timestamp", "team", "artifact", "topic", "path", "producer_script", "status", "hash_sha256"]

for i, raw in enumerate(idx.read_text(encoding="utf-8").splitlines(), start=1):
    if not raw.strip():
        continue
    try:
        row = json.loads(raw)
    except Exception as e:
        print(f"invalid_json line={i} err={e}", file=sys.stderr)
        raise SystemExit(1)
    missing = [k for k in required if k not in row]
    if missing:
        print(f"invalid_schema line={i} missing={','.join(missing)}", file=sys.stderr)
        raise SystemExit(1)
    if not isinstance(row["path"], str) or not row["path"].startswith("/"):
        print(f"invalid_path line={i} path={row.get('path')}", file=sys.stderr)
        raise SystemExit(1)
    artifact = row.get("artifact")
    if artifact not in {"review", "execution", "deploy", "release", "evidence", "ops"}:
        if not (isinstance(artifact, str) and artifact.startswith("custom-")):
            print(f"invalid_artifact line={i} artifact={artifact}", file=sys.stderr)
            raise SystemExit(1)

print("artifact_index format validation passed.")
PY
