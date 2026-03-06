#!/usr/bin/env bash
set -euo pipefail

INDEX_FILE=""
DOCS_ROOT="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
TEAM_ID="team-brain-trust"
PRODUCER_SCRIPT="scholar"
TOPIC="scholar-learning"
DRY_RUN="false"

usage() {
  cat <<'USAGE'
Usage: normalize_artifact_index.sh --index <path> [options]

Options:
  --index <path>        artifact_index.jsonl path (required)
  --docs-root <path>    docs root for resolving relative paths
  --team <team-id>      team id (default: team-brain-trust)
  --producer <name>     producer_script for converted lines (default: scholar)
  --topic <label>       topic for converted lines (default: scholar-learning)
  --dry-run             print normalized output to stdout only
  -h, --help            show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --index)
      INDEX_FILE="${2:-}"
      shift 2
      ;;
    --docs-root)
      DOCS_ROOT="${2:-}"
      shift 2
      ;;
    --team)
      TEAM_ID="${2:-}"
      shift 2
      ;;
    --producer)
      PRODUCER_SCRIPT="${2:-}"
      shift 2
      ;;
    --topic)
      TOPIC="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
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

if [[ -z "${INDEX_FILE}" ]]; then
  echo "--index is required" >&2
  exit 1
fi

if [[ ! -f "${INDEX_FILE}" ]]; then
  echo "index file not found: ${INDEX_FILE}" >&2
  exit 1
fi

tmp_out="$(mktemp)"
python3 - "${INDEX_FILE}" "${tmp_out}" "${DOCS_ROOT}" "${TEAM_ID}" "${PRODUCER_SCRIPT}" "${TOPIC}" <<'PY'
import json
import sys
from pathlib import Path
from datetime import datetime, timezone

idx = Path(sys.argv[1])
out = Path(sys.argv[2])
docs_root = Path(sys.argv[3])
team = sys.argv[4]
producer = sys.argv[5]
topic_default = sys.argv[6]

required = ["timestamp", "team", "artifact", "topic", "path", "producer_script", "status"]

rows = []
for line_no, raw in enumerate(idx.read_text(encoding="utf-8").splitlines(), start=1):
    line = raw.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
    except Exception as e:
        raise SystemExit(f"invalid json on line {line_no}: {e}")

    if all(k in obj for k in required):
        if "hash_sha256" not in obj:
            obj["hash_sha256"] = None
        rows.append(obj)
        continue

    if "run_id" in obj and isinstance(obj.get("artifacts"), list):
        generated = obj.get("generated")
        try:
            ts = datetime.fromisoformat(str(generated).replace("Z", "+00:00")).astimezone(timezone.utc).isoformat(timespec="seconds")
        except Exception:
            ts = datetime.now(timezone.utc).isoformat(timespec="seconds")

        for art in obj["artifacts"]:
            rel_path = str(art.get("path", "")).strip()
            if not rel_path:
                continue
            abs_path = docs_root / team / rel_path
            rows.append(
                {
                    "timestamp": ts,
                    "team": team,
                    "artifact": "custom-learning",
                    "topic": topic_default,
                    "path": str(abs_path),
                    "producer_script": producer,
                    "status": obj.get("status", "generated"),
                    "hash_sha256": None,
                }
            )
        continue

    raise SystemExit(f"unsupported row format on line {line_no}: keys={sorted(obj.keys())}")

with out.open("w", encoding="utf-8") as f:
    for row in rows:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")

print(json.dumps({"ok": True, "rows": len(rows), "output": str(out)}, ensure_ascii=False))
PY

if [[ "${DRY_RUN}" == "true" ]]; then
  cat "${tmp_out}"
else
  cp "${INDEX_FILE}" "${INDEX_FILE}.bak"
  mv "${tmp_out}" "${INDEX_FILE}"
  echo "Normalized ${INDEX_FILE} (backup: ${INDEX_FILE}.bak)"
fi
