#!/usr/bin/env bash
set -euo pipefail

DOCS_ROOT="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
TEAM_ID="${BT_TEAM_ID:-team-brain-trust}"
AGENTS_CSV="${BT_BOOTSTRAP_AGENTS_CSV:-main,pangu,luban,braintrust,braintrust_compliance,scholar,knowledge_manager,rd_lead,smart3d_lead,proposal_lead,feige_notifier}"
TIMEOUT_SECONDS="${BT_BOOTSTRAP_TIMEOUT_SECONDS:-45}"
STRICT_MODE="false"
MESSAGE_TEXT="${BT_BOOTSTRAP_MESSAGE:-Bootstrap health check: return one-line status and no action.}"
REPORT_FILE=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--docs-root <path>] [--team <team-id>] [--agents <csv>] [--timeout-seconds <n>] [--message <text>] [--report-file <abs-path>] [--strict true|false]

Purpose:
  Trigger one lightweight agent turn per target agent so bootstrapPending can converge.

Exit:
  0: completed (or non-strict failures)
  2: strict=true and at least one target failed
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
    --agents)
      AGENTS_CSV="${2:-}"
      shift 2
      ;;
    --timeout-seconds)
      TIMEOUT_SECONDS="${2:-}"
      shift 2
      ;;
    --message)
      MESSAGE_TEXT="${2:-}"
      shift 2
      ;;
    --report-file)
      REPORT_FILE="${2:-}"
      shift 2
      ;;
    --strict)
      STRICT_MODE="${2:-}"
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

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw command not found" >&2
  exit 1
fi

if [[ -z "${REPORT_FILE}" ]]; then
  yyyymm="$(date +%Y%m)"
  ts="$(date +%Y%m%d-%H%M%S)"
  out_dir="${DOCS_ROOT}/${TEAM_ID}/ops/${yyyymm}"
  mkdir -p "${out_dir}"
  REPORT_FILE="${out_dir}/agent_bootstrap_report-${ts}.json"
else
  mkdir -p "$(dirname "${REPORT_FILE}")"
fi

if ! [[ "${TIMEOUT_SECONDS}" =~ ^[0-9]+$ ]] || (( TIMEOUT_SECONDS < 5 )); then
  echo "invalid --timeout-seconds: ${TIMEOUT_SECONDS}" >&2
  exit 1
fi

python3 - "${AGENTS_CSV}" "${TIMEOUT_SECONDS}" "${MESSAGE_TEXT}" "${REPORT_FILE}" "${STRICT_MODE}" <<'PY'
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

agents_csv = sys.argv[1]
timeout_seconds = int(sys.argv[2])
message_text = sys.argv[3]
report_file = Path(sys.argv[4])
strict_mode = sys.argv[5].lower() == "true"

requested = [x.strip() for x in agents_csv.split(",") if x.strip()]
if not requested:
    raise SystemExit("no agents to bootstrap")

try:
    out = subprocess.check_output(["openclaw", "agents", "list", "--json"], text=True, stderr=subprocess.STDOUT)
    listed = json.loads(out)
except subprocess.CalledProcessError as exc:
    raise SystemExit(f"openclaw agents list failed: {(exc.output or '').strip()}")
except json.JSONDecodeError as exc:
    raise SystemExit(f"openclaw agents list returned invalid json: {exc}")

available = {str(item.get("id", "")).strip() for item in listed if isinstance(item, dict)}

results = []
for aid in requested:
    if aid not in available:
        results.append(
            {
                "agent_id": aid,
                "status": "skipped_missing_agent",
                "ok": False,
                "duration_ms": 0,
                "error": "agent_not_found",
            }
        )
        continue

    cmd = [
        "openclaw",
        "agent",
        "--agent",
        aid,
        "--message",
        message_text,
        "--timeout",
        str(timeout_seconds),
        "--json",
    ]
    started = time.time()
    try:
        output = subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT, timeout=timeout_seconds + 15)
        duration_ms = int((time.time() - started) * 1000)
        parsed = None
        try:
            parsed = json.loads(output)
        except Exception:
            parsed = {"raw": output.strip()[:1200]}
        results.append(
            {
                "agent_id": aid,
                "status": "ok",
                "ok": True,
                "duration_ms": duration_ms,
                "response": parsed,
            }
        )
    except subprocess.TimeoutExpired:
        duration_ms = int((time.time() - started) * 1000)
        results.append(
            {
                "agent_id": aid,
                "status": "timeout",
                "ok": False,
                "duration_ms": duration_ms,
                "error": "bootstrap_timeout",
            }
        )
    except subprocess.CalledProcessError as exc:
        duration_ms = int((time.time() - started) * 1000)
        results.append(
            {
                "agent_id": aid,
                "status": "failed",
                "ok": False,
                "duration_ms": duration_ms,
                "error": (exc.output or str(exc)).strip()[:2000],
            }
        )

success_count = sum(1 for x in results if x["status"] == "ok")
failed_count = sum(1 for x in results if x["status"] in {"failed", "timeout"})
skipped_count = sum(1 for x in results if x["status"] == "skipped_missing_agent")

payload = {
    "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "scope": "agent_bootstrap_sessions",
    "strict_mode": strict_mode,
    "requested_agents": requested,
    "summary": {
        "success_count": success_count,
        "failed_count": failed_count,
        "skipped_count": skipped_count,
    },
    "results": results,
}

report_file.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"report: {report_file}")

if strict_mode and failed_count > 0:
    raise SystemExit(2)
PY
