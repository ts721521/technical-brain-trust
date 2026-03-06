#!/usr/bin/env bash
set -euo pipefail

MEMORY_DIR="${HOME}/.openclaw/workspace/memory"
WINDOW=200
REPORT_JSON=""
REPORT_MD=""

usage() {
  cat <<'EOF'
Usage: route_learning_compact.sh [options]

Options:
  --memory-dir <path>    Memory directory (default: ~/.openclaw/workspace/memory)
  --window <n>           Max recent records to aggregate (default: 200)
  --report-json <path>   Optional JSON report output path
  --report-md <path>     Optional Markdown report output path
  -h, --help             Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --memory-dir)
      MEMORY_DIR="$2"; shift 2 ;;
    --window)
      WINDOW="$2"; shift 2 ;;
    --report-json)
      REPORT_JSON="$2"; shift 2 ;;
    --report-md)
      REPORT_MD="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1 ;;
  esac
done

DECISIONS="${MEMORY_DIR}/ROUTING_DECISIONS.jsonl"
MEMO="${MEMORY_DIR}/ROUTING_MEMORY.md"

if [[ ! -f "${DECISIONS}" ]]; then
  echo "missing decisions file: ${DECISIONS}" >&2
  exit 1
fi

mkdir -p "${MEMORY_DIR}"
[[ -f "${MEMO}" ]] || cat > "${MEMO}" <<'EOF'
# Routing Memory
EOF

python3 - "${DECISIONS}" "${MEMO}" "${WINDOW}" "${REPORT_JSON}" "${REPORT_MD}" <<'PY'
import json
import sys
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

decisions_path, memo_path, window_str = sys.argv[1], sys.argv[2], sys.argv[3]
report_json = sys.argv[4].strip()
report_md = sys.argv[5].strip()
window = int(window_str)

records = []
with open(decisions_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            records.append(obj)
        except json.JSONDecodeError:
            continue

if not records:
    print("no valid routing records, skip")
    sys.exit(0)

recent = records[-window:]
intent_counter = Counter()
route_counter = Counter()
status_counter = Counter()
route_success = defaultdict(lambda: {"success": 0, "total": 0})
delivery_mode_counter = Counter()
delegate_total = 0
delegate_success = 0
delegate_recovered = 0
delegate_unreachable = 0
error_code_counter = Counter()
queued_total = 0
queue_wait_sum = 0
queue_wait_samples = 0
scale_spawn_count = 0
scheduler_routed_count = 0

for r in recent:
    intent = r.get("intent_class", "unknown")
    selected = r.get("selected_agent", "unknown")
    status = r.get("result_status", "unknown")
    delivery_mode = r.get("delivery_mode", "unknown")
    recovered = bool(r.get("recovered", False))
    error_code = r.get("error_code", "")
    queued_raw = r.get("queued", False)
    if isinstance(queued_raw, str):
        queued = queued_raw.strip().lower() in ("1", "true", "yes", "y")
    else:
        queued = bool(queued_raw)
    queue_wait_ms = r.get("queue_wait_ms", 0)
    scale_action = str(r.get("scale_action", "none") or "none")
    dispatch_target = str(r.get("dispatch_target", "") or "")
    key = f"{intent} -> {selected}"
    intent_counter[intent] += 1
    route_counter[key] += 1
    status_counter[status] += 1
    route_success[key]["total"] += 1
    delivery_mode_counter[delivery_mode] += 1
    if error_code:
        error_code_counter[error_code] += 1
    if status == "success":
        route_success[key]["success"] += 1
    if delivery_mode == "delegate":
        delegate_total += 1
        if status == "success":
            delegate_success += 1
        if recovered:
            delegate_recovered += 1
        if error_code == "delegate_unreachable":
            delegate_unreachable += 1
    if queued:
        queued_total += 1
        try:
            queue_wait_value = int(queue_wait_ms)
        except Exception:
            queue_wait_value = 0
        if queue_wait_value >= 0:
            queue_wait_sum += queue_wait_value
            queue_wait_samples += 1
    if scale_action == "spawn_scheduler":
        scale_spawn_count += 1
    if scale_action == "route_to_scheduler" or dispatch_target.startswith("scheduler-"):
        scheduler_routed_count += 1

top_routes = route_counter.most_common(8)
timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
delegate_success_rate = (delegate_success / delegate_total * 100.0) if delegate_total else 0.0
delegate_recovery_rate = (delegate_recovered / delegate_total * 100.0) if delegate_total else 0.0
queued_ratio = (queued_total / len(recent) * 100.0) if recent else 0.0
avg_queue_wait_ms = int(queue_wait_sum / queue_wait_samples) if queue_wait_samples else 0

lines = []
lines.append("")
lines.append(f"## Compaction {timestamp}")
lines.append(f"- records_used: {len(recent)}")
lines.append("- status_distribution:")
for status, c in status_counter.most_common():
    lines.append(f"  - {status}: {c}")
lines.append("- top_intent_classes:")
for intent, c in intent_counter.most_common(5):
    lines.append(f"  - {intent}: {c}")
lines.append("- delivery_modes:")
for mode, c in delivery_mode_counter.most_common():
    lines.append(f"  - {mode}: {c}")
lines.append("- delegate_metrics:")
lines.append(f"  - delegate_total: {delegate_total}")
lines.append(f"  - delegate_success_rate: {delegate_success_rate:.1f}%")
lines.append(f"  - delegate_recovery_rate: {delegate_recovery_rate:.1f}%")
lines.append(f"  - delegate_unreachable_count: {delegate_unreachable}")
lines.append("- scheduler_metrics:")
lines.append(f"  - queued_total: {queued_total}")
lines.append(f"  - queued_ratio: {queued_ratio:.1f}%")
lines.append(f"  - avg_queue_wait_ms: {avg_queue_wait_ms}")
lines.append(f"  - scale_spawn_count: {scale_spawn_count}")
lines.append(f"  - scheduler_routed_count: {scheduler_routed_count}")
if error_code_counter:
    lines.append("- error_codes:")
    for code, c in error_code_counter.most_common():
        lines.append(f"  - {code}: {c}")
lines.append("- top_routes:")
for route, c in top_routes:
    s = route_success[route]
    rate = (s["success"] / s["total"] * 100.0) if s["total"] else 0.0
    lines.append(f"  - {route}: total={c}, success_rate={rate:.1f}%")

with open(memo_path, "a", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

summary = {
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "records_used": len(recent),
    "status_distribution": dict(status_counter),
    "top_intent_classes": intent_counter.most_common(5),
    "delivery_modes": dict(delivery_mode_counter),
    "delegate_metrics": {
        "delegate_total": delegate_total,
        "delegate_success_rate": round(delegate_success_rate, 2),
        "delegate_recovery_rate": round(delegate_recovery_rate, 2),
        "delegate_unreachable_count": delegate_unreachable,
    },
    "scheduler_metrics": {
        "queued_total": queued_total,
        "queued_ratio": round(queued_ratio, 2),
        "avg_queue_wait_ms": avg_queue_wait_ms,
        "scale_spawn_count": scale_spawn_count,
        "scheduler_routed_count": scheduler_routed_count,
    },
    "error_codes": dict(error_code_counter),
    "top_routes": [
        {
            "route": route,
            "total": c,
            "success_rate": round((route_success[route]["success"] / route_success[route]["total"] * 100.0), 2)
            if route_success[route]["total"]
            else 0.0,
        }
        for route, c in top_routes
    ],
}

if report_json:
    p = Path(report_json)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

if report_md:
    p = Path(report_md)
    p.parent.mkdir(parents=True, exist_ok=True)
    md = [
        "# Route Learning Report",
        "",
        f"- Generated at: `{summary['generated_at']}`",
        f"- Records used: `{summary['records_used']}`",
        "",
        "## Status Distribution",
    ]
    for k, v in summary["status_distribution"].items():
        md.append(f"- {k}: {v}")
    md.append("")
    md.append("## Delegate Metrics")
    dm = summary["delegate_metrics"]
    md.append(f"- delegate_total: {dm['delegate_total']}")
    md.append(f"- delegate_success_rate: {dm['delegate_success_rate']}%")
    md.append(f"- delegate_recovery_rate: {dm['delegate_recovery_rate']}%")
    md.append(f"- delegate_unreachable_count: {dm['delegate_unreachable_count']}")
    md.append("")
    md.append("## Scheduler Metrics")
    sm = summary["scheduler_metrics"]
    md.append(f"- queued_total: {sm['queued_total']}")
    md.append(f"- queued_ratio: {sm['queued_ratio']}%")
    md.append(f"- avg_queue_wait_ms: {sm['avg_queue_wait_ms']}")
    md.append(f"- scale_spawn_count: {sm['scale_spawn_count']}")
    md.append(f"- scheduler_routed_count: {sm['scheduler_routed_count']}")
    md.append("")
    md.append("## Top Routes")
    if summary["top_routes"]:
        for row in summary["top_routes"]:
            md.append(f"- {row['route']}: total={row['total']}, success_rate={row['success_rate']}%")
    else:
        md.append("- 无")
    p.write_text("\n".join(md) + "\n", encoding="utf-8")

print(f"compacted {len(recent)} records into {memo_path}")
PY
