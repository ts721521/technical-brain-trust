#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTER_SCRIPT="${ROOT_DIR}/scripts/register_artifact_index.sh"

DOCS_ROOT="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
TEAM_ID="${BT_TEAM_ID:-team-brain-trust}"
SLOT_TIME="050000"
TEAMS_CSV="team-brain-trust,team-knowledge,team-rd,team-smart3d,team-proposal"
NOTIFY_ON_ANOMALY="true"
QUEUE_STATE_FILE="${BT_QUEUE_STATE_FILE:-$HOME/.openclaw/workspaces/pangu/memory/TASK_QUEUE_STATE.json}"
QUEUE_FAILURE_WINDOW_HOURS="${BT_QUEUE_FAILURE_WINDOW_HOURS:-24}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--docs-root <path>] [--team <team-id>] [--slot-time HHMMSS] [--teams <csv>] [--notify true|false]

Outputs (daily):
  runtime_health_report-YYYYMMDD-HHMMSS.json
  agent_model_inventory-YYYYMMDD-HHMMSS.md
  team_topology-YYYYMMDD-HHMMSS.md
  improvement_backlog-YYYYMMDD-HHMMSS.md
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
    --slot-time)
      SLOT_TIME="${2:-}"
      shift 2
      ;;
    --teams)
      TEAMS_CSV="${2:-}"
      shift 2
      ;;
    --notify)
      NOTIFY_ON_ANOMALY="${2:-}"
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

if [[ ! -d "${DOCS_ROOT}" || ! -w "${DOCS_ROOT}" ]]; then
  echo "docs root unavailable or not writable: ${DOCS_ROOT}" >&2
  exit 1
fi

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw command not found" >&2
  exit 1
fi

run_date="$(date +%Y%m%d)"
yyyymm="$(date +%Y%m)"
out_dir="${DOCS_ROOT}/${TEAM_ID}/ops/${yyyymm}"
mkdir -p "${out_dir}"

runtime_json="${out_dir}/runtime_health_report-${run_date}-${SLOT_TIME}.json"
inventory_md="${out_dir}/agent_model_inventory-${run_date}-${SLOT_TIME}.md"
topology_md="${out_dir}/team_topology-${run_date}-${SLOT_TIME}.md"
backlog_md="${out_dir}/improvement_backlog-${run_date}-${SLOT_TIME}.md"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

openclaw agents list --json >"${tmp_dir}/agents.json"
openclaw status --json >"${tmp_dir}/status.json"
openclaw security audit --json >"${tmp_dir}/security.json"
openclaw cron list --json >"${tmp_dir}/cron.json"

python3 - "${tmp_dir}/agents.json" "${tmp_dir}/status.json" "${tmp_dir}/security.json" "${tmp_dir}/cron.json" \
  "${runtime_json}" "${inventory_md}" "${topology_md}" "${backlog_md}" \
  "${TEAMS_CSV}" "${QUEUE_STATE_FILE}" "${NOTIFY_ON_ANOMALY}" "${QUEUE_FAILURE_WINDOW_HOURS}" <<'PY'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

agents_path = Path(sys.argv[1])
status_path = Path(sys.argv[2])
security_path = Path(sys.argv[3])
cron_path = Path(sys.argv[4])
runtime_json_path = Path(sys.argv[5])
inventory_md_path = Path(sys.argv[6])
topology_md_path = Path(sys.argv[7])
backlog_md_path = Path(sys.argv[8])
teams_csv = sys.argv[9]
queue_state_file = Path(sys.argv[10]).expanduser()
notify_on_anomaly = sys.argv[11].lower() == "true"
queue_failure_window_hours = int(sys.argv[12])

agents = json.loads(agents_path.read_text(encoding="utf-8"))
status = json.loads(status_path.read_text(encoding="utf-8"))
security = json.loads(security_path.read_text(encoding="utf-8"))
cron = json.loads(cron_path.read_text(encoding="utf-8"))


expected_models = {
    "architect": {
        "primary": os.environ.get("BT_ARCHITECT_MODEL", "openai-codex/gpt-5.3-codex"),
        "fallbacks": [
            os.environ.get("BT_ARCHITECT_FALLBACK_1", "zai/glm-5"),
            os.environ.get("BT_ARCHITECT_FALLBACK_2", "google-gemini-cli/gemini-3.1-pro-preview"),
            os.environ.get("BT_ARCHITECT_FALLBACK_3", "bailian/qwen3.5-plus"),
        ],
    },
    "critic": {
        "primary": os.environ.get("BT_CRITIC_MODEL", "zai/glm-5"),
        "fallbacks": [
            os.environ.get("BT_CRITIC_FALLBACK_1", "openai-codex/gpt-5.3-codex"),
            os.environ.get("BT_CRITIC_FALLBACK_2", "google-gemini-cli/gemini-3-pro-preview"),
            os.environ.get("BT_CRITIC_FALLBACK_3", "bailian/qwen3-max-2026-01-23"),
        ],
    },
    "innovator": {
        "primary": os.environ.get("BT_INNOVATOR_MODEL", "google-gemini-cli/gemini-3.1-pro-preview"),
        "fallbacks": [
            os.environ.get("BT_INNOVATOR_FALLBACK_1", "openai-codex/gpt-5.3-codex"),
            os.environ.get("BT_INNOVATOR_FALLBACK_2", "zai/glm-4.7"),
            os.environ.get("BT_INNOVATOR_FALLBACK_3", "bailian/kimi-k2.5"),
        ],
    },
    "pangu": {
        "primary": os.environ.get("BT_PANGU_MODEL", "bailian/qwen3-coder-plus"),
        "fallbacks": [
            os.environ.get("BT_PANGU_FALLBACK_1", "openai-codex/gpt-5.3-codex"),
            os.environ.get("BT_PANGU_FALLBACK_2", "zai/glm-5"),
            os.environ.get("BT_PANGU_FALLBACK_3", "bailian/qwen3.5-plus"),
        ],
    },
    "scholar": {
        "primary": os.environ.get("BT_SCHOLAR_MODEL", "zai/glm-5"),
        "fallbacks": [
            os.environ.get("BT_SCHOLAR_FALLBACK_1", "openai-codex/gpt-5.3-codex"),
            os.environ.get("BT_SCHOLAR_FALLBACK_2", "google-gemini-cli/gemini-3.1-pro-preview"),
            os.environ.get("BT_SCHOLAR_FALLBACK_3", "bailian/qwen3.5-plus"),
        ],
    },
    "feige_notifier": {
        "primary": os.environ.get("BT_FEIGE_MODEL", "google-gemini-cli/gemini-2.0-flash"),
        "fallbacks": [
            os.environ.get("BT_FEIGE_FALLBACK_1", "bailian/qwen3.5-plus"),
            os.environ.get("BT_FEIGE_FALLBACK_2", "openai-codex/gpt-5.3-codex"),
            os.environ.get("BT_FEIGE_FALLBACK_3", "zai/glm-5"),
        ],
    },
}


def run_cmd(cmd):
    try:
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT).strip()
        return out, ""
    except subprocess.CalledProcessError as e:
        return "", (e.output or str(e)).strip()


def now_ms():
    return int(datetime.now(timezone.utc).timestamp() * 1000)


def parse_global_fallbacks():
    out, err = run_cmd(["openclaw", "models", "fallbacks", "list"])
    if err:
        return []
    rows = []
    for line in out.splitlines():
        s = line.strip()
        if s.startswith("-"):
            rows.append(s[1:].strip())
    return rows


def parse_global_primary():
    out, err = run_cmd(["openclaw", "models", "status", "--plain"])
    if err:
        return ""
    return out.strip().splitlines()[-1].strip() if out.strip() else ""


def load_available_models():
    out, err = run_cmd(["openclaw", "models", "list"])
    if err:
        return []
    models = []
    for line in out.splitlines():
        s = line.strip()
        if not s or s.startswith("Model "):
            continue
        token = s.split()[0]
        if "/" in token:
            models.append(token)
    return models


def classify_team(agent_id):
    if agent_id in {"main", "luban", "pangu", "braintrust", "braintrust_compliance", "braintrust_chief", "braintrust_architect", "architect", "critic", "innovator"}:
        return "core"
    if agent_id in {"scholar", "wenquxing", "knowledge_manager", "feige_notifier"} or agent_id.startswith("km_"):
        return "knowledge"
    if agent_id.startswith("rd_") or agent_id in {"developer", "tester", "documentation", "coordinator"}:
        return "rd"
    if agent_id.startswith("smart3d_"):
        return "smart3d"
    if agent_id.startswith("proposal_"):
        return "proposal"
    return "misc"


def role_summary(agent_id):
    if agent_id == "main":
        return "全局入口与路由"
    if agent_id == "pangu":
        return "执行与孵化"
    if agent_id.startswith("braintrust"):
        return "评审/验收"
    if agent_id in {"architect", "critic", "innovator"}:
        return "三专家审查"
    if agent_id in {"scholar", "wenquxing", "knowledge_manager", "feige_notifier"} or agent_id.startswith("km_"):
        return "学习与知识治理"
    if agent_id.startswith("rd_") or agent_id in {"developer", "tester", "documentation"}:
        return "研发执行"
    return "团队成员"


target_role_chains = {}
for role, expected in expected_models.items():
    target_role_chains[role] = {
        "primary": expected.get("primary", ""),
        "fallbacks": [x for x in expected.get("fallbacks", []) if x],
    }

global_primary = parse_global_primary()
global_fallbacks = parse_global_fallbacks()
available_models = load_available_models()

agent_rows = []
for item in agents:
    if not isinstance(item, dict):
        continue
    aid = str(item.get("id", ""))
    if not aid:
        continue
    model = str(item.get("model", ""))
    role_chain = target_role_chains.get(aid, {})
    fbs = role_chain.get("fallbacks", [])
    agent_rows.append(
        {
            "agent": aid,
            "team": classify_team(aid),
            "model": model,
            "fallbacks": fbs,
            "responsibility": role_summary(aid),
        }
    )

agent_rows.sort(key=lambda x: (x["team"], x["agent"]))


architect_chain = target_role_chains.get("architect", {"primary": "", "fallbacks": []})
drift_items = [
    {
        "scope": "global-default",
        "baseline_role": "architect",
        "expected_primary": architect_chain.get("primary", ""),
        "current_primary": global_primary,
        "expected_fallbacks": architect_chain.get("fallbacks", []),
        "current_fallbacks": global_fallbacks,
        "drift": (
            global_primary != architect_chain.get("primary", "")
            or global_fallbacks != architect_chain.get("fallbacks", [])
        ),
        "note": "OpenClaw default model scope is global. Role-specific chains are switched at runtime by run_brain_trust_review.sh.",
    }
]

model_contract_issues = []
if available_models:
    for role, chain in target_role_chains.items():
        candidates = [chain.get("primary", "")] + list(chain.get("fallbacks", []))
        missing = [m for m in candidates if m and m not in available_models]
        if missing:
            model_contract_issues.append(
                {
                    "role": role,
                    "missing_models": missing,
                }
            )

queue_failed_total = 0
queue_failed_recent = 0
queue_pending = 0
queue_running = 0
if queue_state_file.exists():
    try:
        queue_data = json.loads(queue_state_file.read_text(encoding="utf-8"))
        if isinstance(queue_data, dict):
            now_ts_ms = now_ms()
            recent_window_ms = max(1, queue_failure_window_hours) * 3600 * 1000
            for item in queue_data.get("items", []) or []:
                st = str(item.get("status", "")).lower()
                if st == "failed":
                    queue_failed_total += 1
                    end_ts_ms = int(item.get("end_ts_ms", 0) or 0)
                    if end_ts_ms <= 0:
                        end_ts_ms = int(item.get("start_ts_ms", 0) or 0)
                    if end_ts_ms <= 0:
                        end_ts_ms = int(item.get("enqueue_ts_ms", 0) or 0)
                    if end_ts_ms > 0 and now_ts_ms - end_ts_ms <= recent_window_ms:
                        queue_failed_recent += 1
                elif st in {"queued", "pending"}:
                    queue_pending += 1
                elif st in {"dispatched", "running"}:
                    queue_running += 1
    except Exception:
        pass

team_summaries = []
missing_ledgers = []
current_month = datetime.now().strftime("%Y%m")
for team in [x.strip() for x in teams_csv.split(",") if x.strip()]:
    ledger = Path(os.environ.get("BT_DOCS_ROOT", "/Volumes/TB512/3_ClawDocs")) / team / "ops" / current_month / "task_ledger.jsonl"
    if not ledger.exists():
        missing_ledgers.append(team)
        team_summaries.append({"team": team, "ledger": str(ledger), "exists": False, "tasks": 0, "done": 0, "blocked": 0, "in_progress": 0})
        continue
    latest = {}
    for line in ledger.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        tid = str(row.get("task_id", "") or "")
        if tid:
            latest[tid] = row
    done = sum(1 for r in latest.values() if str(r.get("state", "")) == "done")
    blocked = sum(1 for r in latest.values() if str(r.get("state", "")) == "acceptance")
    in_progress = sum(1 for r in latest.values() if str(r.get("state", "")) == "in_progress")
    team_summaries.append(
        {
            "team": team,
            "ledger": str(ledger),
            "exists": True,
            "tasks": len(latest),
            "done": done,
            "blocked": blocked,
            "in_progress": in_progress,
        }
    )

cron_jobs = cron.get("jobs", []) if isinstance(cron, dict) else []
cron_delivery_issues = []
for job in cron_jobs:
    if not isinstance(job, dict):
        continue
    state = job.get("state", {}) if isinstance(job.get("state"), dict) else {}
    delivery_cfg = job.get("delivery", {}) if isinstance(job.get("delivery"), dict) else {}
    delivery_mode = str(delivery_cfg.get("mode", "none") or "none").lower()
    delivery = str(state.get("lastDeliveryStatus", ""))
    last_run_status = str(state.get("lastRunStatus", ""))
    last_error = str(state.get("lastError", ""))
    last_delivery_error = str(state.get("lastDeliveryError", ""))
    enabled = bool(job.get("enabled", False))
    if not enabled:
        continue
    is_issue = False
    if last_run_status == "error":
        is_issue = True
    elif delivery_mode != "none" and delivery in {"failed", "error"}:
        is_issue = True
    if is_issue:
        cron_delivery_issues.append({
            "job_id": job.get("id", ""),
            "name": job.get("name", ""),
            "delivery_mode": delivery_mode,
            "last_delivery": delivery,
            "last_run_status": last_run_status,
            "last_error": last_error,
            "last_delivery_error": last_delivery_error,
        })

security_summary = security.get("summary", {}) if isinstance(security, dict) else {}
critical = int(security_summary.get("critical", 0) or 0)
warn = int(security_summary.get("warn", 0) or 0)

model_drift_count = sum(1 for x in drift_items if x["drift"])

p0_items = []
p1_items = []

if critical > 0:
    p0_items.append(f"security critical={critical}，需立即收敛 groupPolicy 与 gateway auth。")
if model_drift_count > 0:
    p0_items.append(f"关键角色模型漂移 {model_drift_count} 项，需执行基线校准。")
if model_contract_issues:
    p0_items.append(f"存在 {len(model_contract_issues)} 组模型契约缺失（目标模型不在可用列表）。")
if queue_failed_recent > 0:
    p0_items.append(f"执行队列近{queue_failure_window_hours}小时失败任务 {queue_failed_recent} 条，需排查并回放。")

if missing_ledgers:
    p1_items.append(f"缺少团队台账：{', '.join(missing_ledgers)}")
if cron_delivery_issues:
    p1_items.append(f"定时任务投递异常 {len(cron_delivery_issues)} 项。")
if queue_pending > 0 or queue_running > 0:
    p1_items.append(f"队列积压状态：pending={queue_pending}, running={queue_running}")
if warn > 0:
    p1_items.append(f"security warn={warn}，建议后续收敛。")

runtime_report = {
    "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "docs_root": os.environ.get("BT_DOCS_ROOT", "/Volumes/TB512/3_ClawDocs"),
    "team_id": os.environ.get("BT_TEAM_ID", "team-brain-trust"),
    "model_semantics": {
        "default_scope": "global",
        "runtime_switching": "run_brain_trust_review.sh applies per-role model chain before execution",
    },
    "target_role_chains": target_role_chains,
    "global_model_chain": {
        "primary": global_primary,
        "fallbacks": global_fallbacks,
    },
    "model_contract_issues": model_contract_issues,
    "security_summary": security_summary,
    "model_drift": {
        "count": model_drift_count,
        "items": drift_items,
    },
    "queue_summary": {
        "failed_total": queue_failed_total,
        "failed_recent": queue_failed_recent,
        "failure_window_hours": queue_failure_window_hours,
        "pending": queue_pending,
        "running": queue_running,
        "state_file": str(queue_state_file),
    },
    "cron_summary": {
        "total": len(cron_jobs),
        "delivery_issues": cron_delivery_issues,
    },
    "task_ledger_summary": team_summaries,
    "improvement_backlog": {
        "p0": p0_items,
        "p1": p1_items,
    },
}

runtime_json_path.write_text(json.dumps(runtime_report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

inventory_lines = [
    "# Agent Model Inventory",
    "",
    f"- Generated at: `{datetime.now().isoformat(timespec='seconds')}`",
    "",
    "| Agent | Team | Model | Fallbacks | Responsibility |",
    "|---|---|---|---|---|",
]
for row in agent_rows:
    inventory_lines.append(
        f"| {row['agent']} | {row['team']} | {row['model'] or '-'} | {', '.join(row['fallbacks']) if row['fallbacks'] else '-'} | {row['responsibility']} |"
    )
inventory_md_path.write_text("\n".join(inventory_lines) + "\n", encoding="utf-8")

topology = """# Team Topology

```mermaid
flowchart LR
  MAIN[\"main\"] --> LUBAN[\"luban\"]
  MAIN --> PANGU[\"pangu\"]
  MAIN --> BT[\"braintrust\"]
  MAIN --> SCHOLAR[\"scholar\"]
  MAIN --> RDLEAD[\"rd_lead\"]

  BT --> BTC[\"braintrust_compliance\"]

  SCHOLAR --> WQX[\"wenquxing\"]
  SCHOLAR --> KM[\"knowledge_manager\"]
  SCHOLAR --> KMC[\"km_collector\"]
  SCHOLAR --> KMO[\"km_organizer\"]
  SCHOLAR --> KMI[\"km_indexer\"]
  SCHOLAR --> FEIGE[\"feige_notifier\"]

  RDLEAD --> RDDEV[\"rd_developer\"]
  RDLEAD --> RDMGR[\"rd_manager\"]
  RDLEAD --> DEV[\"developer\"]
  RDLEAD --> TESTER[\"tester\"]
```
"""
topology_md_path.write_text(topology + "\n", encoding="utf-8")

backlog_lines = [
    "# Improvement Backlog",
    "",
    f"- Generated at: `{datetime.now().isoformat(timespec='seconds')}`",
    "",
    "## P0",
]
if p0_items:
    for i, item in enumerate(p0_items, 1):
        backlog_lines.append(f"{i}. {item}")
else:
    backlog_lines.append("1. 无")

backlog_lines.append("\n## P1")
if p1_items:
    for i, item in enumerate(p1_items, 1):
        backlog_lines.append(f"{i}. {item}")
else:
    backlog_lines.append("1. 无")

backlog_md_path.write_text("\n".join(backlog_lines) + "\n", encoding="utf-8")

# Optional anomaly alert (best effort)
alert_result = {"attempted": False, "sent": False, "error": ""}
if notify_on_anomaly and (p0_items or p1_items):
    allow_from_raw, _ = run_cmd(["openclaw", "config", "get", "channels.telegram.allowFrom", "--json"])
    target = ""
    try:
        parsed = json.loads(allow_from_raw)
        if isinstance(parsed, list) and parsed:
            target = str(parsed[0])
    except Exception:
        target = ""

    if target:
        msg = f"[Runtime Audit] P0={len(p0_items)} P1={len(p1_items)}。详情: {runtime_json_path}"
        alert_result["attempted"] = True
        out, err = run_cmd(["openclaw", "message", "send", "--channel", "telegram", "--target", target, "--message", msg, "--json"])
        if err:
            alert_result["error"] = err
        else:
            alert_result["sent"] = True
    else:
        alert_result["attempted"] = True
        alert_result["error"] = "missing telegram allowFrom target"

runtime_report["alert"] = alert_result
runtime_json_path.write_text(json.dumps(runtime_report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

if [[ -x "${REGISTER_SCRIPT}" ]]; then
  for f in "${runtime_json}" "${inventory_md}" "${topology_md}" "${backlog_md}"; do
    "${REGISTER_SCRIPT}" \
      --docs-root "${DOCS_ROOT}" \
      --team "${TEAM_ID}" \
      --artifact "ops" \
      --topic "runtime-health-audit" \
      --path "${f}" \
      --producer-script "runtime_health_audit.sh" \
      --status "generated" >/dev/null || true
  done
fi

echo "runtime audit generated:" 
echo "- ${runtime_json}" 
echo "- ${inventory_md}" 
echo "- ${topology_md}" 
echo "- ${backlog_md}" 
