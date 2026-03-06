#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

docs_root_default="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
team_default="${BT_TEAM_ID:-team-brain-trust}"
yyyymm_default="$(date +%Y%m)"
ledger_default="${docs_root_default}/${team_default}/ops/${yyyymm_default}/task_ledger.jsonl"

usage() {
  cat <<USAGE
Usage:
  ${SCRIPT_NAME} create --task-id <id> --team <team> --title <title> --owner <owner> [--state published] [--ledger <path>]
  ${SCRIPT_NAME} transition --task-id <id> --to <state> [--reason <text>] [--error-code <code>] [--reopen-actions <json-or-text>] [--owner <owner>] [--ledger <path>]
  ${SCRIPT_NAME} get --task-id <id> [--ledger <path>]
  ${SCRIPT_NAME} list [--team <team>] [--state <state>] [--owner <owner>] [--ledger <path>]

States:
  published -> assigned -> in_progress -> review -> acceptance -> done
  acceptance -> in_progress (reopen)
USAGE
}

command="${1:-}"
if [[ -z "${command}" || "${command}" == "-h" || "${command}" == "--help" ]]; then
  usage
  exit 0
fi
shift || true

ledger_path="${ledger_default}"
task_id=""
team=""
title=""
owner=""
state=""
to_state=""
reason=""
error_code=""
reopen_actions=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ledger)
      ledger_path="${2:-}"
      shift 2
      ;;
    --task-id)
      task_id="${2:-}"
      shift 2
      ;;
    --team)
      team="${2:-}"
      shift 2
      ;;
    --title)
      title="${2:-}"
      shift 2
      ;;
    --owner)
      owner="${2:-}"
      shift 2
      ;;
    --state)
      state="${2:-}"
      shift 2
      ;;
    --to)
      to_state="${2:-}"
      shift 2
      ;;
    --reason)
      reason="${2:-}"
      shift 2
      ;;
    --error-code)
      error_code="${2:-}"
      shift 2
      ;;
    --reopen-actions)
      reopen_actions="${2:-}"
      shift 2
      ;;
    *)
      echo "unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

mkdir -p "$(dirname "${ledger_path}")"
touch "${ledger_path}"

python3 - "${command}" "${ledger_path}" "${task_id}" "${team}" "${title}" "${owner}" "${state}" "${to_state}" "${reason}" "${error_code}" "${reopen_actions}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

command = sys.argv[1]
ledger_path = Path(sys.argv[2])
task_id = sys.argv[3]
team = sys.argv[4]
title = sys.argv[5]
owner = sys.argv[6]
state = sys.argv[7]
to_state = sys.argv[8]
reason = sys.argv[9]
error_code = sys.argv[10]
reopen_actions_raw = sys.argv[11]

ALLOWED_STATES = {
    "published",
    "assigned",
    "in_progress",
    "review",
    "acceptance",
    "done",
}

TRANSITIONS = {
    "published": {"assigned"},
    "assigned": {"in_progress"},
    "in_progress": {"review"},
    "review": {"acceptance"},
    "acceptance": {"done", "in_progress"},
    "done": set(),
}


def fail(msg: str, code: int = 1) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(code)


def parse_lines(path: Path):
    rows = []
    if not path.exists():
        return rows
    for idx, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except Exception:
            continue
        if isinstance(obj, dict):
            obj["_line"] = idx
            rows.append(obj)
    return rows


def latest_map(rows):
    latest = {}
    for row in rows:
        tid = str(row.get("task_id", "") or "")
        if tid:
            latest[tid] = row
    return latest


def append_row(path: Path, row: dict):
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")


def parse_reopen_actions(raw: str):
    text = str(raw or "").strip()
    if not text:
        return []
    if text.startswith("["):
        try:
            arr = json.loads(text)
            if isinstance(arr, list):
                return [str(x).strip() for x in arr if str(x).strip()]
        except Exception:
            pass
    return [text]

rows = parse_lines(ledger_path)
latest = latest_map(rows)
now = datetime.now(timezone.utc).isoformat(timespec="seconds")

if command == "create":
    if not task_id:
        fail("missing required arg: --task-id")
    if not team:
        fail("missing required arg: --team")
    if not title:
        fail("missing required arg: --title")
    if not owner:
        fail("missing required arg: --owner")
    if not state:
        state = "published"
    if state not in ALLOWED_STATES:
        fail(f"invalid state: {state}")
    if task_id in latest:
        fail(f"task already exists: {task_id}", code=2)

    row = {
        "timestamp": now,
        "action": "create",
        "task_id": task_id,
        "team": team,
        "title": title,
        "owner": owner,
        "state": state,
        "previous_state": "",
        "reason": "",
        "error_code": "",
        "reopen_actions": [],
    }
    append_row(ledger_path, row)
    print(json.dumps(row, ensure_ascii=False))
    raise SystemExit(0)

if command == "transition":
    if not task_id:
        fail("missing required arg: --task-id")
    if not to_state:
        fail("missing required arg: --to")
    if to_state not in ALLOWED_STATES:
        fail(f"invalid target state: {to_state}")
    current = latest.get(task_id)
    if not current:
        fail(f"task not found: {task_id}", code=2)

    from_state = str(current.get("state", "") or "")
    if not from_state:
        fail(f"task has no state: {task_id}", code=3)

    if to_state != from_state and to_state not in TRANSITIONS.get(from_state, set()):
        fail(f"invalid transition: {from_state} -> {to_state}", code=3)

    row = {
        "timestamp": now,
        "action": "transition",
        "task_id": task_id,
        "team": str(current.get("team") or team or ""),
        "title": str(current.get("title") or title or ""),
        "owner": owner or str(current.get("owner") or ""),
        "state": to_state,
        "previous_state": from_state,
        "reason": reason,
        "error_code": error_code,
        "reopen_actions": parse_reopen_actions(reopen_actions_raw),
    }
    append_row(ledger_path, row)
    print(json.dumps(row, ensure_ascii=False))
    raise SystemExit(0)

if command == "get":
    if not task_id:
        fail("missing required arg: --task-id")
    current = latest.get(task_id)
    if not current:
        fail(f"task not found: {task_id}", code=2)
    current.pop("_line", None)
    print(json.dumps(current, ensure_ascii=False, indent=2))
    raise SystemExit(0)

if command == "list":
    out = []
    team_filter = team
    state_filter = state if state else ""
    owner_filter = owner

    for tid, row in latest.items():
        row = dict(row)
        row.pop("_line", None)
        if team_filter and str(row.get("team", "")) != team_filter:
            continue
        if state_filter and str(row.get("state", "")) != state_filter:
            continue
        if owner_filter and str(row.get("owner", "")) != owner_filter:
            continue
        out.append(row)

    out.sort(key=lambda x: (str(x.get("team", "")), str(x.get("task_id", ""))))
    print(json.dumps(out, ensure_ascii=False, indent=2))
    raise SystemExit(0)

fail(f"unknown command: {command}")
PY
