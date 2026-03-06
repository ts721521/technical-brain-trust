#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: pangu_task_scheduler.sh <command> [options]

Commands:
  enqueue        Enqueue a heavy task
  dispatch-once  Reserve one queued task for execution
  complete       Mark task as success/failed
  drain          Requeue stale running tasks
  stats          Show queue statistics

Common options:
  --queue-file <path>              Queue event log path (jsonl)
  --state-file <path>              Queue state file path (json)
  --lock-file <path>               Lock file path (default: <state-file>.lock)

enqueue options:
  --intent-class <value>           default: execution_heavy
  --task-hint <text>               default: stage4_execution
  --queue-max <n>                  default: 50

dispatch-once options:
  --queue-id <id>                  optional specific queue id
  --max-inflight <n>               default: 2
  --dispatch-timeout-seconds <n>   default: 180
  --dispatch-target <agent>        default: pangu
  --scale-action <value>           default: none

complete options:
  --queue-id <id>                  required
  --result <success|failed>        required
  --error-code <code>              optional

drain options:
  --running-ttl-seconds <n>        default: 180

stats options:
  (none)
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

command="$1"
shift

queue_file=""
state_file=""
lock_file=""

intent_class="execution_heavy"
task_hint="stage4_execution"
queue_max="50"

queue_id=""
max_inflight="2"
dispatch_timeout_seconds="180"
dispatch_target="pangu"
scale_action="none"

result_status=""
error_code=""
running_ttl_seconds="180"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --queue-file)
      queue_file="${2:-}"; shift 2 ;;
    --state-file)
      state_file="${2:-}"; shift 2 ;;
    --lock-file)
      lock_file="${2:-}"; shift 2 ;;
    --intent-class)
      intent_class="${2:-}"; shift 2 ;;
    --task-hint)
      task_hint="${2:-}"; shift 2 ;;
    --queue-max)
      queue_max="${2:-}"; shift 2 ;;
    --queue-id)
      queue_id="${2:-}"; shift 2 ;;
    --max-inflight)
      max_inflight="${2:-}"; shift 2 ;;
    --dispatch-timeout-seconds)
      dispatch_timeout_seconds="${2:-}"; shift 2 ;;
    --dispatch-target)
      dispatch_target="${2:-}"; shift 2 ;;
    --scale-action)
      scale_action="${2:-}"; shift 2 ;;
    --result)
      result_status="${2:-}"; shift 2 ;;
    --error-code)
      error_code="${2:-}"; shift 2 ;;
    --running-ttl-seconds)
      running_ttl_seconds="${2:-}"; shift 2 ;;
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

if [[ -z "${queue_file}" || -z "${state_file}" ]]; then
  echo "--queue-file and --state-file are required" >&2
  exit 1
fi

if [[ -z "${lock_file}" ]]; then
  lock_file="${state_file}.lock"
fi

if ! [[ "${queue_max}" =~ ^[0-9]+$ ]] || (( queue_max < 1 )); then
  echo "invalid --queue-max: ${queue_max}" >&2
  exit 1
fi
if ! [[ "${max_inflight}" =~ ^[0-9]+$ ]] || (( max_inflight < 1 )); then
  echo "invalid --max-inflight: ${max_inflight}" >&2
  exit 1
fi
if ! [[ "${dispatch_timeout_seconds}" =~ ^[0-9]+$ ]] || (( dispatch_timeout_seconds < 1 )); then
  echo "invalid --dispatch-timeout-seconds: ${dispatch_timeout_seconds}" >&2
  exit 1
fi
if ! [[ "${running_ttl_seconds}" =~ ^[0-9]+$ ]] || (( running_ttl_seconds < 1 )); then
  echo "invalid --running-ttl-seconds: ${running_ttl_seconds}" >&2
  exit 1
fi

python3 - "$command" "$queue_file" "$state_file" "$lock_file" "$intent_class" "$task_hint" "$queue_max" "$queue_id" "$max_inflight" "$dispatch_timeout_seconds" "$dispatch_target" "$scale_action" "$result_status" "$error_code" "$running_ttl_seconds" <<'PY'
import json
import os
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
import fcntl

(
    command,
    queue_file,
    state_file,
    lock_file,
    intent_class,
    task_hint,
    queue_max,
    queue_id,
    max_inflight,
    dispatch_timeout_seconds,
    dispatch_target,
    scale_action,
    result_status,
    error_code,
    running_ttl_seconds,
) = sys.argv[1:]

queue_max = int(queue_max)
max_inflight = int(max_inflight)
dispatch_timeout_seconds = int(dispatch_timeout_seconds)
running_ttl_seconds = int(running_ttl_seconds)

queue_path = Path(queue_file)
state_path = Path(state_file)
lock_path = Path(lock_file)

queue_path.parent.mkdir(parents=True, exist_ok=True)
state_path.parent.mkdir(parents=True, exist_ok=True)
lock_path.parent.mkdir(parents=True, exist_ok=True)


def now_iso():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def now_ms():
    return int(time.time() * 1000)


def load_state():
    if not state_path.exists():
        return {"items": []}
    try:
        data = json.loads(state_path.read_text(encoding="utf-8"))
    except Exception:
        data = {"items": []}
    if not isinstance(data, dict):
        data = {"items": []}
    if not isinstance(data.get("items"), list):
        data["items"] = []
    return data


def save_state(data):
    state_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def append_event(event):
    with queue_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")


def state_counts(data):
    queued = 0
    running = 0
    completed = 0
    failed = 0
    for item in data.get("items", []):
        status = item.get("status", "")
        if status == "queued":
            queued += 1
        elif status == "running":
            running += 1
        elif status == "completed":
            completed += 1
        elif status == "failed":
            failed += 1
    return queued, running, completed, failed


def select_queued_item(data, specific_id=""):
    queued_items = [i for i in data.get("items", []) if i.get("status") == "queued"]
    queued_items.sort(key=lambda x: int(x.get("enqueue_ts_ms", 0)))
    if specific_id:
        for item in queued_items:
            if item.get("queue_id") == specific_id:
                return item
        return None
    return queued_items[0] if queued_items else None


def lock_and_run(fn):
    with lock_path.open("a+") as lock_f:
        fcntl.flock(lock_f.fileno(), fcntl.LOCK_EX)
        try:
            return fn()
        finally:
            fcntl.flock(lock_f.fileno(), fcntl.LOCK_UN)


def cmd_enqueue():
    def _do():
        data = load_state()
        queued, running, completed, failed = state_counts(data)
        active = queued + running
        if active >= queue_max:
            out = {
                "status": "rejected",
                "error_code": "queue_full",
                "queue_depth": active,
                "queue_max": queue_max,
            }
            print(json.dumps(out, ensure_ascii=False))
            return 3

        qid = f"q_{int(time.time())}_{uuid.uuid4().hex[:8]}"
        item = {
            "queue_id": qid,
            "intent_class": intent_class,
            "task_hint": task_hint,
            "status": "queued",
            "enqueue_ts": now_iso(),
            "enqueue_ts_ms": now_ms(),
            "dispatch_target": "",
            "scale_action": "none",
            "attempts": 0,
            "last_error": "",
        }
        data["items"].append(item)
        save_state(data)
        queued_after, running_after, _, _ = state_counts(data)
        append_event(
            {
                "event": "enqueue",
                "timestamp": now_iso(),
                "queue_id": qid,
                "intent_class": intent_class,
                "task_hint": task_hint,
                "queue_depth_at_enqueue": queued_after + running_after,
            }
        )
        out = {
            "status": "queued",
            "queue_id": qid,
            "queue_depth_at_enqueue": queued_after + running_after,
        }
        print(json.dumps(out, ensure_ascii=False))
        return 0

    return lock_and_run(_do)


def cmd_dispatch_once():
    deadline = time.time() + dispatch_timeout_seconds

    while True:
        result = {}

        def _do():
            data = load_state()
            queued, running, _, _ = state_counts(data)
            if running >= max_inflight:
                return {
                    "status": "busy",
                    "error_code": "queue_dispatch_timeout",
                    "running": running,
                    "max_inflight": max_inflight,
                    "queued": queued,
                }, None

            item = select_queued_item(data, queue_id)
            if item is None:
                return {
                    "status": "empty",
                    "running": running,
                    "queued": queued,
                }, None

            start_ms = now_ms()
            item["status"] = "running"
            item["dispatch_target"] = dispatch_target or "pangu"
            item["scale_action"] = scale_action or "none"
            item["attempts"] = int(item.get("attempts", 0)) + 1
            item["start_ts"] = now_iso()
            item["start_ts_ms"] = start_ms
            enqueue_ms = int(item.get("enqueue_ts_ms", start_ms))
            queue_wait_ms = max(0, start_ms - enqueue_ms)
            save_state(data)
            append_event(
                {
                    "event": "dispatch",
                    "timestamp": now_iso(),
                    "queue_id": item.get("queue_id"),
                    "dispatch_target": item.get("dispatch_target"),
                    "scale_action": item.get("scale_action"),
                    "queue_wait_ms": queue_wait_ms,
                }
            )
            return {
                "status": "dispatched",
                "queue_id": item.get("queue_id"),
                "dispatch_target": item.get("dispatch_target"),
                "scale_action": item.get("scale_action"),
                "queue_wait_ms": queue_wait_ms,
                "delegate_attempts": int(item.get("attempts", 1)),
            }, item.get("queue_id")

        result, _ = lock_and_run(_do)

        if result.get("status") in ("dispatched", "empty"):
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result.get("status") == "dispatched" else 4

        if time.time() >= deadline:
            result["status"] = "timeout"
            result["error_code"] = "queue_dispatch_timeout"
            print(json.dumps(result, ensure_ascii=False))
            return 124

        time.sleep(1)


def cmd_complete():
    if not queue_id:
        print(json.dumps({"status": "error", "error": "queue_id_required"}, ensure_ascii=False))
        return 2
    if result_status not in ("success", "failed"):
        print(json.dumps({"status": "error", "error": "result_required"}, ensure_ascii=False))
        return 2

    def _do():
        data = load_state()
        target = None
        for item in data.get("items", []):
            if item.get("queue_id") == queue_id:
                target = item
                break
        if target is None:
            print(json.dumps({"status": "missing", "queue_id": queue_id}, ensure_ascii=False))
            return 3

        target["status"] = "completed" if result_status == "success" else "failed"
        target["end_ts"] = now_iso()
        target["end_ts_ms"] = now_ms()
        target["last_error"] = error_code or ""
        save_state(data)
        append_event(
            {
                "event": "complete" if result_status == "success" else "failed",
                "timestamp": now_iso(),
                "queue_id": queue_id,
                "error_code": error_code or "",
            }
        )
        print(json.dumps({"status": target["status"], "queue_id": queue_id}, ensure_ascii=False))
        return 0

    return lock_and_run(_do)


def cmd_drain():
    now = now_ms()
    ttl_ms = running_ttl_seconds * 1000

    def _do():
        data = load_state()
        requeued = 0
        for item in data.get("items", []):
            if item.get("status") != "running":
                continue
            start_ms = int(item.get("start_ts_ms", 0))
            if start_ms > 0 and now - start_ms > ttl_ms:
                item["status"] = "queued"
                item["dispatch_target"] = ""
                item["scale_action"] = "none"
                item["last_error"] = "queue_dispatch_timeout"
                requeued += 1
                append_event(
                    {
                        "event": "requeue_stale",
                        "timestamp": now_iso(),
                        "queue_id": item.get("queue_id"),
                        "reason": "queue_dispatch_timeout",
                    }
                )
        save_state(data)
        queued, running, completed, failed = state_counts(data)
        print(
            json.dumps(
                {
                    "status": "ok",
                    "requeued": requeued,
                    "queued": queued,
                    "running": running,
                    "completed": completed,
                    "failed": failed,
                },
                ensure_ascii=False,
            )
        )
        return 0

    return lock_and_run(_do)


def cmd_stats():
    def _do():
        data = load_state()
        queued, running, completed, failed = state_counts(data)
        waits = []
        for item in data.get("items", []):
            if int(item.get("start_ts_ms", 0)) > 0 and int(item.get("enqueue_ts_ms", 0)) > 0:
                waits.append(max(0, int(item["start_ts_ms"]) - int(item["enqueue_ts_ms"])))
        avg_wait_ms = int(sum(waits) / len(waits)) if waits else 0
        print(
            json.dumps(
                {
                    "status": "ok",
                    "queued": queued,
                    "running": running,
                    "completed": completed,
                    "failed": failed,
                    "avg_queue_wait_ms": avg_wait_ms,
                },
                ensure_ascii=False,
            )
        )
        return 0

    return lock_and_run(_do)


if command == "enqueue":
    raise SystemExit(cmd_enqueue())
if command == "dispatch-once":
    raise SystemExit(cmd_dispatch_once())
if command == "complete":
    raise SystemExit(cmd_complete())
if command == "drain":
    raise SystemExit(cmd_drain())
if command == "stats":
    raise SystemExit(cmd_stats())

print(json.dumps({"status": "error", "error": f"unknown command: {command}"}, ensure_ascii=False))
raise SystemExit(2)
PY
