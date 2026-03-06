#!/usr/bin/env bash
set -euo pipefail

DOCS_ROOT="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
TEAMS_CSV="${BT_AUDIT_TEAMS:-team-brain-trust,team-knowledge,team-rd,team-smart3d,team-proposal}"
YYYYMM="${BT_AUDIT_YYYYMM:-$(date +%Y%m)}"
STALE_HOURS="${BT_LEDGER_STALE_HOURS:-24}"
OUT_REPORT=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--docs-root <path>] [--teams <csv>] [--yyyymm <YYYYMM>] [--stale-hours <hours>] [--out-report <path>]

Audit task ledgers and report stale/open tasks by team.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --docs-root)
      DOCS_ROOT="${2:-}"
      shift 2
      ;;
    --teams)
      TEAMS_CSV="${2:-}"
      shift 2
      ;;
    --yyyymm)
      YYYYMM="${2:-}"
      shift 2
      ;;
    --stale-hours)
      STALE_HOURS="${2:-}"
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

if ! [[ "${STALE_HOURS}" =~ ^[0-9]+$ ]]; then
  echo "invalid --stale-hours: ${STALE_HOURS}" >&2
  exit 1
fi

if [[ -z "${OUT_REPORT}" ]]; then
  ts="$(date +%Y%m%d-%H%M%S)"
  OUT_REPORT="${DOCS_ROOT}/team-brain-trust/ops/${YYYYMM}/task_ledger_audit_report-${ts}.json"
fi

mkdir -p "$(dirname "${OUT_REPORT}")"

python3 - "${DOCS_ROOT}" "${TEAMS_CSV}" "${YYYYMM}" "${STALE_HOURS}" "${OUT_REPORT}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

docs_root = Path(sys.argv[1])
teams_csv = sys.argv[2]
yyyymm = sys.argv[3]
stale_hours = int(sys.argv[4])
out_report = Path(sys.argv[5])

open_states = {"published", "assigned", "in_progress", "review", "acceptance"}
now = datetime.now(timezone.utc)

def parse_ts(value):
    text = str(value or "").strip()
    if not text:
        return None
    try:
        if text.endswith("Z"):
            text = text.replace("Z", "+00:00")
        dt = datetime.fromisoformat(text)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except Exception:
        return None

def load_latest(path: Path):
    latest = {}
    malformed = 0
    if not path.exists():
        return latest, malformed
    for line in path.read_text(encoding="utf-8").splitlines():
        row_text = line.strip()
        if not row_text:
            continue
        try:
            row = json.loads(row_text)
        except Exception:
            malformed += 1
            continue
        if not isinstance(row, dict):
            malformed += 1
            continue
        task_id = str(row.get("task_id", "") or "").strip()
        if task_id:
            latest[task_id] = row
    return latest, malformed

teams = [x.strip() for x in teams_csv.split(",") if x.strip()]
team_reports = []
missing_ledgers = []
total_open = 0
total_stale = 0

for team in teams:
    ledger = docs_root / team / "ops" / yyyymm / "task_ledger.jsonl"
    latest, malformed = load_latest(ledger)
    open_tasks = []
    stale_tasks = []
    for task_id, row in latest.items():
        state = str(row.get("state", "") or "")
        if state not in open_states:
            continue
        ts = parse_ts(row.get("timestamp"))
        age_hours = None
        stale = False
        if ts is not None:
            age_hours = max(0.0, (now - ts).total_seconds() / 3600.0)
            stale = age_hours >= stale_hours
        open_info = {
            "task_id": task_id,
            "state": state,
            "owner": str(row.get("owner", "") or ""),
            "title": str(row.get("title", "") or ""),
            "timestamp": str(row.get("timestamp", "") or ""),
            "age_hours": round(age_hours, 2) if age_hours is not None else None,
            "stale": stale,
        }
        open_tasks.append(open_info)
        if stale:
            stale_tasks.append(open_info)

    open_tasks.sort(key=lambda x: (x["age_hours"] is None, -(x["age_hours"] or 0.0), x["task_id"]))
    stale_tasks.sort(key=lambda x: (-(x["age_hours"] or 0.0), x["task_id"]))
    if not ledger.exists():
        missing_ledgers.append(team)
    team_reports.append(
        {
            "team": team,
            "ledger_path": str(ledger),
            "ledger_exists": ledger.exists(),
            "malformed_lines": malformed,
            "open_count": len(open_tasks),
            "stale_count": len(stale_tasks),
            "open_tasks": open_tasks,
            "stale_tasks": stale_tasks,
        }
    )
    total_open += len(open_tasks)
    total_stale += len(stale_tasks)

payload = {
    "generated_at": now.isoformat(timespec="seconds"),
    "docs_root": str(docs_root),
    "yyyymm": yyyymm,
    "stale_hours": stale_hours,
    "summary": {
        "teams_count": len(teams),
        "missing_ledgers": missing_ledgers,
        "open_total": total_open,
        "stale_total": total_stale,
    },
    "teams": team_reports,
}
out_report.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(str(out_report))
PY

echo "task ledger audit report: ${OUT_REPORT}"
