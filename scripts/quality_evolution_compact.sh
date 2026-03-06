#!/usr/bin/env bash
set -euo pipefail

DOCS_ROOT="${BT_DOCS_ROOT:-/Volumes/TB512/3_ClawDocs}"
TEAM_ID="${BT_TEAM_ID:-team-brain-trust}"
TEAMS_CSV="${BT_QUALITY_TEAMS_CSV:-team-knowledge,team-rd,team-smart3d,team-proposal}"
WINDOW_DAYS="${BT_QUALITY_WINDOW_DAYS:-30}"
SLOT_TIME=""
OUT_DIR=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--docs-root <path>] [--team <team-id>] [--teams <csv>] [--window-days <n>] [--slot-time HHMMSS] [--out-dir <path>]

Generate quality evolution compact report from Stage5 quality_improvement_log.jsonl.

Outputs:
  quality_evolution_report-YYYYMMDD-HHMMSS.json
  quality_evolution_report-YYYYMMDD-HHMMSS.md
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
    --teams)
      TEAMS_CSV="${2:-}"
      shift 2
      ;;
    --window-days)
      WINDOW_DAYS="${2:-}"
      shift 2
      ;;
    --slot-time)
      SLOT_TIME="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
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

if [[ ! -d "${DOCS_ROOT}" || ! -w "${DOCS_ROOT}" ]]; then
  echo "docs root unavailable or not writable: ${DOCS_ROOT}" >&2
  exit 1
fi

if ! [[ "${WINDOW_DAYS}" =~ ^[0-9]+$ ]] || (( WINDOW_DAYS < 1 )); then
  echo "invalid --window-days: ${WINDOW_DAYS}" >&2
  exit 1
fi

run_date="$(date +%Y%m%d)"
if [[ -z "${SLOT_TIME}" ]]; then
  SLOT_TIME="$(date +%H%M%S)"
fi
yyyymm="$(date +%Y%m)"

if [[ -z "${OUT_DIR}" ]]; then
  OUT_DIR="${DOCS_ROOT}/${TEAM_ID}/ops/${yyyymm}"
fi
mkdir -p "${OUT_DIR}"

json_out="${OUT_DIR}/quality_evolution_report-${run_date}-${SLOT_TIME}.json"
md_out="${OUT_DIR}/quality_evolution_report-${run_date}-${SLOT_TIME}.md"

python3 - "${DOCS_ROOT}" "${TEAMS_CSV}" "${WINDOW_DAYS}" "${json_out}" "${md_out}" <<'PY'
import json
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path

docs_root = Path(sys.argv[1])
teams_csv = sys.argv[2]
window_days = int(sys.argv[3])
json_out = Path(sys.argv[4])
md_out = Path(sys.argv[5])

now = datetime.now(timezone.utc)
cutoff = now - timedelta(days=window_days)

teams = [x.strip() for x in teams_csv.split(",") if x.strip()]
team_rows = []
global_entries = []

def parse_ts(value: str):
    if not value:
        return None
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(text)
    except Exception:
        return None

for team in teams:
    pattern = docs_root / team / "review"
    files = sorted(pattern.glob("*/quality_improvement_log.jsonl"))
    entries = []
    for file in files:
        for line in file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            ts = parse_ts(str(row.get("timestamp", "") or ""))
            if ts is not None and ts.tzinfo is None:
                ts = ts.replace(tzinfo=timezone.utc)
            if ts is not None and ts < cutoff:
                continue
            entries.append(row)
            global_entries.append((team, row))

    total = len(entries)
    blocked = 0
    score_values = []
    issue_counter = Counter()
    action_counter = Counter()
    for row in entries:
        if str(row.get("experiment_result", "")).lower() != "pass":
            blocked += 1
        baseline = row.get("baseline_metrics", {})
        if isinstance(baseline, dict):
            try:
                score_values.append(float(baseline.get("final_score", 0)))
            except Exception:
                pass
        for issue in row.get("issues_topn", []) if isinstance(row.get("issues_topn", []), list) else []:
            text = str(issue).strip()
            if text:
                issue_counter[text] += 1
        for action in row.get("improvement_actions", []) if isinstance(row.get("improvement_actions", []), list) else []:
            text = str(action).strip()
            if text:
                action_counter[text] += 1

    avg_score = round(sum(score_values) / len(score_values), 2) if score_values else 0.0
    blocked_rate = round((blocked / total), 4) if total else 0.0
    team_rows.append(
        {
            "team": team,
            "entries": total,
            "blocked": blocked,
            "blocked_rate": blocked_rate,
            "avg_final_score": avg_score,
            "top_issues": [i for i, _ in issue_counter.most_common(3)],
            "top_actions": [a for a, _ in action_counter.most_common(3)],
        }
    )

all_total = len(global_entries)
all_blocked = sum(
    1 for _, row in global_entries if str(row.get("experiment_result", "")).lower() != "pass"
)
global_blocked_rate = round((all_blocked / all_total), 4) if all_total else 0.0

recommendations = []
if all_total == 0:
    recommendations.append("最近窗口内无质量改进样本，建议至少完成一次 Stage5 审查闭环。")
if global_blocked_rate >= 0.2:
    recommendations.append(f"全局 blocked_rate={global_blocked_rate:.2%} 偏高，建议优先处理高频阻断项。")
for row in team_rows:
    if row["entries"] >= 3 and row["blocked_rate"] >= 0.3:
        recommendations.append(f"{row['team']} blocked_rate={row['blocked_rate']:.2%}，建议触发专项复盘。")

payload = {
    "generated_at": now.isoformat(timespec="seconds"),
    "window_days": window_days,
    "teams": team_rows,
    "global": {
        "entries": all_total,
        "blocked": all_blocked,
        "blocked_rate": global_blocked_rate,
    },
    "recommendations": recommendations,
}

json_out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

md_lines = [
    "# Quality Evolution Report",
    "",
    f"- Generated at: `{payload['generated_at']}`",
    f"- Window days: `{window_days}`",
    "",
    "## Global",
    "",
    f"- Entries: `{all_total}`",
    f"- Blocked: `{all_blocked}`",
    f"- Blocked rate: `{global_blocked_rate:.2%}`",
    "",
    "## Team Metrics",
    "",
    "| Team | Entries | Blocked | Blocked Rate | Avg Final Score |",
    "|---|---:|---:|---:|---:|",
]
for row in team_rows:
    md_lines.append(
        f"| {row['team']} | {row['entries']} | {row['blocked']} | {row['blocked_rate']:.2%} | {row['avg_final_score']} |"
    )

md_lines.append("")
md_lines.append("## Recommendations")
if recommendations:
    for idx, rec in enumerate(recommendations, 1):
        md_lines.append(f"{idx}. {rec}")
else:
    md_lines.append("1. 无")

md_out.write_text("\n".join(md_lines) + "\n", encoding="utf-8")
print(str(json_out))
PY

echo "quality evolution report generated:"
echo "- ${json_out}"
echo "- ${md_out}"
