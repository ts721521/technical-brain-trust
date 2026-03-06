#!/usr/bin/env bash
set -euo pipefail

queue_depth=""
threshold="6"
registry_file=""
events_file=""
workspace_root="${HOME}/.openclaw/workspaces"
scheduler_prefix="scheduler-overflow"
default_target="pangu"

usage() {
  cat <<'USAGE'
Usage: ensure_scheduler_capacity.sh --queue-depth <n> --threshold <n> --registry-file <path> --events-file <path> [options]

Options:
  --queue-depth <n>      Current queued+running depth
  --threshold <n>        Trigger threshold (default: 6)
  --registry-file <path> Scheduler registry json
  --events-file <path>   Scheduler events jsonl
  --workspace-root <p>   Scheduler workspace root (default: ~/.openclaw/workspaces)
  --scheduler-prefix <p> Scheduler id prefix (default: scheduler-overflow)
  --default-target <id>  Fallback target agent (default: pangu)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --queue-depth)
      queue_depth="${2:-}"; shift 2 ;;
    --threshold)
      threshold="${2:-}"; shift 2 ;;
    --registry-file)
      registry_file="${2:-}"; shift 2 ;;
    --events-file)
      events_file="${2:-}"; shift 2 ;;
    --workspace-root)
      workspace_root="${2:-}"; shift 2 ;;
    --scheduler-prefix)
      scheduler_prefix="${2:-}"; shift 2 ;;
    --default-target)
      default_target="${2:-}"; shift 2 ;;
    -h|--help)
      usage
      exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1 ;;
  esac
done

if [[ -z "${queue_depth}" || -z "${registry_file}" || -z "${events_file}" ]]; then
  echo "--queue-depth, --registry-file and --events-file are required" >&2
  exit 1
fi
if ! [[ "${queue_depth}" =~ ^[0-9]+$ ]]; then
  echo "invalid --queue-depth: ${queue_depth}" >&2
  exit 1
fi
if ! [[ "${threshold}" =~ ^[0-9]+$ ]]; then
  echo "invalid --threshold: ${threshold}" >&2
  exit 1
fi

mkdir -p "$(dirname "${registry_file}")" "$(dirname "${events_file}")" "${workspace_root}"
[[ -f "${registry_file}" ]] || echo '{"schedulers": []}' > "${registry_file}"
[[ -f "${events_file}" ]] || : > "${events_file}"

if (( queue_depth <= threshold )); then
  python3 - <<'PY' "${queue_depth}" "${threshold}" "${default_target}"
import json, sys
print(json.dumps({
  "status": "ok",
  "action": "none",
  "queue_depth": int(sys.argv[1]),
  "threshold": int(sys.argv[2]),
  "dispatch_target": sys.argv[3],
  "error_code": ""
}, ensure_ascii=False))
PY
  exit 0
fi

existing_scheduler="$(python3 - <<'PY' "${registry_file}"
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
try:
    data = json.loads(p.read_text(encoding='utf-8'))
except Exception:
    data = {}
for it in data.get('schedulers', []):
    if isinstance(it, dict) and it.get('status') == 'active' and it.get('id'):
        print(it['id'])
        break
PY
)"

append_event() {
  local action="$1"
  local scheduler_id="$2"
  local status="$3"
  local reason="$4"
  python3 - <<'PY' "${events_file}" "${action}" "${scheduler_id}" "${status}" "${reason}" "${queue_depth}" "${threshold}"
import json, sys
from datetime import datetime, timezone
from pathlib import Path
p = Path(sys.argv[1])
obj = {
  "timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
  "action": sys.argv[2],
  "scheduler_id": sys.argv[3],
  "status": sys.argv[4],
  "reason": sys.argv[5],
  "queue_depth": int(sys.argv[6]),
  "threshold": int(sys.argv[7]),
}
with p.open("a", encoding="utf-8") as f:
  f.write(json.dumps(obj, ensure_ascii=False) + "\n")
PY
}

if [[ -n "${existing_scheduler}" ]]; then
  append_event "route_to_scheduler" "${existing_scheduler}" "ok" "active_scheduler_reused"
  python3 - <<'PY' "${registry_file}" "${existing_scheduler}"
import json, sys
from datetime import datetime, timezone
from pathlib import Path
p = Path(sys.argv[1])
sid = sys.argv[2]
try:
    data = json.loads(p.read_text(encoding='utf-8'))
except Exception:
    data = {"schedulers": []}
for item in data.get("schedulers", []):
    if isinstance(item, dict) and item.get("id") == sid:
        item["last_seen"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding='utf-8')
PY

  python3 - <<'PY' "${existing_scheduler}" "${queue_depth}" "${threshold}"
import json, sys
print(json.dumps({
  "status": "ok",
  "action": "route_to_scheduler",
  "dispatch_target": sys.argv[1],
  "queue_depth": int(sys.argv[2]),
  "threshold": int(sys.argv[3]),
  "error_code": "scheduler_routed",
}, ensure_ascii=False))
PY
  exit 0
fi

new_scheduler_id="${scheduler_prefix}-$(date +%H%M%S)"
new_workspace="${workspace_root}/${new_scheduler_id}"
mkdir -p "${new_workspace}"

if openclaw agents add "${new_scheduler_id}" --workspace "${new_workspace}" --non-interactive >/tmp/${new_scheduler_id}.add.log 2>&1; then
  python3 - <<'PY' "${registry_file}" "${new_scheduler_id}" "${new_workspace}"
import json, sys
from datetime import datetime, timezone
from pathlib import Path
p = Path(sys.argv[1])
sid = sys.argv[2]
workspace = sys.argv[3]
try:
    data = json.loads(p.read_text(encoding='utf-8'))
except Exception:
    data = {"schedulers": []}
if "schedulers" not in data or not isinstance(data["schedulers"], list):
    data["schedulers"] = []
now = datetime.now(timezone.utc).isoformat(timespec="seconds")
data["schedulers"].append({
    "id": sid,
    "workspace": workspace,
    "status": "active",
    "created_at": now,
    "last_seen": now,
})
p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding='utf-8')
PY

  append_event "spawn_scheduler" "${new_scheduler_id}" "ok" "created"

  python3 - <<'PY' "${new_scheduler_id}" "${queue_depth}" "${threshold}"
import json, sys
print(json.dumps({
  "status": "ok",
  "action": "spawn_scheduler",
  "dispatch_target": sys.argv[1],
  "queue_depth": int(sys.argv[2]),
  "threshold": int(sys.argv[3]),
  "error_code": "scheduler_routed",
}, ensure_ascii=False))
PY
  exit 0
fi

append_event "spawn_scheduler" "${new_scheduler_id}" "failed" "openclaw_agents_add_failed"
python3 - <<'PY' "${default_target}" "${queue_depth}" "${threshold}" "${new_scheduler_id}"
import json, sys
print(json.dumps({
  "status": "degraded",
  "action": "spawn_scheduler",
  "dispatch_target": sys.argv[1],
  "queue_depth": int(sys.argv[2]),
  "threshold": int(sys.argv[3]),
  "error_code": "scheduler_spawn_failed",
  "scheduler_id": sys.argv[4],
}, ensure_ascii=False))
PY
exit 0
