#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_LEDGER_SCRIPT="${ROOT_DIR}/scripts/task_ledger.sh"
REGISTER_SCRIPT="${ROOT_DIR}/scripts/register_artifact_index.sh"

DOCS_ROOT="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
TEAM_ID="${BT_TEAM_ID:-team-brain-trust}"
OWNER="${BT_BACKLOG_OWNER:-pangu}"
YYYYMM="$(date +%Y%m)"
RUNTIME_REPORT=""
LEDGER_FILE=""
OUT_REPORT=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") --runtime-report <path> [--docs-root <path>] [--team <team-id>] [--owner <agent-id>] [--yyyymm <YYYYMM>] [--ledger <path>] [--out-report <path>]

Sync runtime_health_report.improvement_backlog(p0/p1) to task ledger with dedup.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime-report)
      RUNTIME_REPORT="${2:-}"
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
    --owner)
      OWNER="${2:-}"
      shift 2
      ;;
    --yyyymm)
      YYYYMM="${2:-}"
      shift 2
      ;;
    --ledger)
      LEDGER_FILE="${2:-}"
      shift 2
      ;;
    --out-report)
      OUT_REPORT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${RUNTIME_REPORT}" ]]; then
  echo "--runtime-report is required" >&2
  exit 1
fi
if [[ ! -f "${RUNTIME_REPORT}" ]]; then
  echo "runtime report not found: ${RUNTIME_REPORT}" >&2
  exit 1
fi
if [[ ! -x "${TASK_LEDGER_SCRIPT}" ]]; then
  echo "missing executable: ${TASK_LEDGER_SCRIPT}" >&2
  exit 1
fi

if [[ -z "${LEDGER_FILE}" ]]; then
  LEDGER_FILE="${DOCS_ROOT}/${TEAM_ID}/ops/${YYYYMM}/task_ledger.jsonl"
fi
mkdir -p "$(dirname "${LEDGER_FILE}")"
touch "${LEDGER_FILE}"

if [[ -z "${OUT_REPORT}" ]]; then
  ts="$(date +%Y%m%d-%H%M%S)"
  OUT_REPORT="${DOCS_ROOT}/${TEAM_ID}/ops/${YYYYMM}/backlog_sync_report-${ts}.json"
fi
mkdir -p "$(dirname "${OUT_REPORT}")"

python3 - "${RUNTIME_REPORT}" "${LEDGER_FILE}" "${TASK_LEDGER_SCRIPT}" "${TEAM_ID}" "${OWNER}" "${OUT_REPORT}" <<'PY'
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

runtime_report = Path(sys.argv[1])
ledger_file = Path(sys.argv[2])
task_ledger_script = sys.argv[3]
team_id = sys.argv[4]
owner = sys.argv[5]
out_report = Path(sys.argv[6])

def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))

def load_latest_tasks(path: Path):
    latest = {}
    if not path.exists():
        return latest
    for line in path.read_text(encoding="utf-8").splitlines():
        text = line.strip()
        if not text:
            continue
        try:
            row = json.loads(text)
        except Exception:
            continue
        tid = str(row.get("task_id", "") or "")
        if tid:
            latest[tid] = row
    return latest

def call_create(task_id: str, title: str):
    cmd = [
        task_ledger_script,
        "create",
        "--task-id",
        task_id,
        "--team",
        team_id,
        "--title",
        title,
        "--owner",
        owner,
        "--state",
        "published",
        "--ledger",
        str(ledger_file),
    ]
    try:
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)
        return True, out.strip()
    except subprocess.CalledProcessError as exc:
        return False, (exc.output or str(exc)).strip()

data = load_json(runtime_report)
backlog = data.get("improvement_backlog", {})
p0 = backlog.get("p0", []) if isinstance(backlog, dict) else []
p1 = backlog.get("p1", []) if isinstance(backlog, dict) else []
p0 = [str(x).strip() for x in p0 if str(x).strip()]
p1 = [str(x).strip() for x in p1 if str(x).strip()]

latest = load_latest_tasks(ledger_file)
created = []
skipped = []
failed = []

def sync_items(level: str, items):
    for text in items:
        digest = hashlib.sha1(f"{level}:{text}".encode("utf-8")).hexdigest()[:12]
        task_id = f"ops-backlog-{level.lower()}-{digest}"
        title = f"[{level}] {text}"
        existing = latest.get(task_id)
        if existing:
            skipped.append(
                {
                    "task_id": task_id,
                    "title": title,
                    "reason": "already_exists",
                    "current_state": str(existing.get("state", "") or ""),
                }
            )
            continue
        ok, detail = call_create(task_id, title)
        if ok:
            created.append({"task_id": task_id, "title": title})
        else:
            failed.append({"task_id": task_id, "title": title, "error": detail})

sync_items("P0", p0)
sync_items("P1", p1)

payload = {
    "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "team": team_id,
    "owner": owner,
    "runtime_report": str(runtime_report),
    "ledger_file": str(ledger_file),
    "summary": {
        "p0_count": len(p0),
        "p1_count": len(p1),
        "created_count": len(created),
        "skipped_count": len(skipped),
        "failed_count": len(failed),
    },
    "created": created,
    "skipped": skipped,
    "failed": failed,
}
out_report.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(str(out_report))
PY

if [[ -x "${REGISTER_SCRIPT}" ]]; then
  "${REGISTER_SCRIPT}" \
    --docs-root "${DOCS_ROOT}" \
    --team "${TEAM_ID}" \
    --artifact "ops" \
    --topic "runtime-backlog-sync" \
    --path "${OUT_REPORT}" \
    --producer-script "sync_runtime_backlog_tasks.sh" \
    --status "generated" >/dev/null || true
fi

echo "backlog sync report: ${OUT_REPORT}"
