#!/usr/bin/env bash
set -euo pipefail

SKILL=""
PANGU_WORKSPACE="${HOME}/.openclaw/workspaces/pangu"
MAIN_WORKSPACE="${HOME}/.openclaw/workspace"

MIN_RUNS=5
MIN_SUCCESS_RATE=80
MAX_ROLLBACKS=0

OBS_RUNS=5
OBS_SUCCESS_RATE=100
OBS_ROLLBACKS=0
FORCE="false"

usage() {
  cat <<'EOF'
Usage: promote_skill_from_pangu_to_main.sh --skill <slug> [options]

Options:
  --skill <slug>                 Skill slug to promote
  --pangu-workspace <path>       Pangu workspace path
  --main-workspace <path>        Main workspace path
  --min-runs <n>                 Promotion threshold: min runs (default 5)
  --min-success-rate <n>         Promotion threshold: min success rate (default 80)
  --max-rollbacks <n>            Promotion threshold: max rollbacks (default 0)
  --observed-runs <n>            Observed gray-release runs
  --observed-success-rate <n>    Observed gray-release success rate
  --observed-rollbacks <n>       Observed gray-release rollback count
  --force                        Bypass thresholds
  -h, --help                     Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill) SKILL="$2"; shift 2 ;;
    --pangu-workspace) PANGU_WORKSPACE="$2"; shift 2 ;;
    --main-workspace) MAIN_WORKSPACE="$2"; shift 2 ;;
    --min-runs) MIN_RUNS="$2"; shift 2 ;;
    --min-success-rate) MIN_SUCCESS_RATE="$2"; shift 2 ;;
    --max-rollbacks) MAX_ROLLBACKS="$2"; shift 2 ;;
    --observed-runs) OBS_RUNS="$2"; shift 2 ;;
    --observed-success-rate) OBS_SUCCESS_RATE="$2"; shift 2 ;;
    --observed-rollbacks) OBS_ROLLBACKS="$2"; shift 2 ;;
    --force) FORCE="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1 ;;
  esac
done

if [[ -z "${SKILL}" ]]; then
  echo "--skill is required" >&2
  exit 1
fi

if [[ "${FORCE}" != "true" ]]; then
  if (( OBS_RUNS < MIN_RUNS )); then
    echo "promotion blocked: observed runs ${OBS_RUNS} < min ${MIN_RUNS}" >&2
    exit 1
  fi
  if (( OBS_SUCCESS_RATE < MIN_SUCCESS_RATE )); then
    echo "promotion blocked: success rate ${OBS_SUCCESS_RATE} < min ${MIN_SUCCESS_RATE}" >&2
    exit 1
  fi
  if (( OBS_ROLLBACKS > MAX_ROLLBACKS )); then
    echo "promotion blocked: rollbacks ${OBS_ROLLBACKS} > max ${MAX_ROLLBACKS}" >&2
    exit 1
  fi
fi

src="${PANGU_WORKSPACE}/skills/${SKILL}"
dst="${MAIN_WORKSPACE}/skills/${SKILL}"

if [[ ! -d "${src}" ]]; then
  echo "source skill not found: ${src}" >&2
  exit 1
fi

mkdir -p "${MAIN_WORKSPACE}/skills"
rm -rf "${dst}"
cp -R "${src}" "${dst}"

mkdir -p "${MAIN_WORKSPACE}/memory" "${PANGU_WORKSPACE}/memory"
promotion_log="${MAIN_WORKSPACE}/memory/PROMOTION_LOG.jsonl"
patch_log="${PANGU_WORKSPACE}/memory/MAIN_PATCH_LOG.jsonl"
touch "${promotion_log}" "${patch_log}"

python3 - "${SKILL}" "${src}" "${dst}" "${OBS_RUNS}" "${OBS_SUCCESS_RATE}" "${OBS_ROLLBACKS}" "${promotion_log}" "${patch_log}" <<'PY'
import json
import sys
from datetime import datetime

skill, src, dst, runs, success_rate, rollbacks, promotion_log, patch_log = sys.argv[1:9]
event = {
    "timestamp": datetime.utcnow().isoformat(timespec="seconds") + "Z",
    "event": "skill_promotion",
    "skill": skill,
    "source": src,
    "target": dst,
    "gray_release": {
        "runs": int(runs),
        "success_rate": int(success_rate),
        "rollbacks": int(rollbacks),
    },
    "status": "promoted",
}

for path in (promotion_log, patch_log):
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")
print(json.dumps(event, ensure_ascii=False, indent=2))
PY

echo "promotion completed: ${SKILL}"
