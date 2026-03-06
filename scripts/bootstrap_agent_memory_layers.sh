#!/usr/bin/env bash
set -euo pipefail

MAIN_WORKSPACE="${HOME}/.openclaw/workspace"
PANGU_WORKSPACE="${HOME}/.openclaw/workspaces/pangu"
WORKSPACES_ROOT="${HOME}/.openclaw/workspaces"
DRY_RUN="false"

usage() {
  cat <<'EOF'
Usage: bootstrap_agent_memory_layers.sh [options]

Options:
  --main-workspace <path>    Main workspace path
  --pangu-workspace <path>   Pangu workspace path
  --workspaces-root <path>   Root folder for scheduler-* workspaces
  --dry-run                  Print actions without writing
  -h, --help                 Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --main-workspace)
      MAIN_WORKSPACE="$2"; shift 2 ;;
    --pangu-workspace)
      PANGU_WORKSPACE="$2"; shift 2 ;;
    --workspaces-root)
      WORKSPACES_ROOT="$2"; shift 2 ;;
    --dry-run)
      DRY_RUN="true"; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1 ;;
  esac
done

create_dir() {
  local d="$1"
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] mkdir -p ${d}"
  else
    mkdir -p "${d}"
  fi
}

write_if_missing() {
  local path="$1"
  local content="$2"
  if [[ -f "${path}" ]]; then
    echo "[skip] exists: ${path}"
    return
  fi
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] create file: ${path}"
  else
    printf "%s" "${content}" > "${path}"
    echo "[ok] created: ${path}"
  fi
}

touch_if_missing() {
  local path="$1"
  if [[ -f "${path}" ]]; then
    echo "[skip] exists: ${path}"
    return
  fi
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] touch ${path}"
  else
    : > "${path}"
    echo "[ok] created: ${path}"
  fi
}

main_memory="${MAIN_WORKSPACE}/memory"
pangu_memory="${PANGU_WORKSPACE}/memory"
template_memory="${WORKSPACES_ROOT}/.scheduler-template/memory"

create_dir "${main_memory}"
create_dir "${pangu_memory}"
create_dir "${template_memory}"

write_if_missing "${main_memory}/ROUTING_MEMORY.md" "# Routing Memory

Shared routing patterns learned by main.
"
touch_if_missing "${main_memory}/ROUTING_DECISIONS.jsonl"
touch_if_missing "${main_memory}/PROMOTION_LOG.jsonl"

write_if_missing "${pangu_memory}/EXECUTION_LEARNINGS.md" "# Pangu Execution Learnings

Execution lessons and improvement notes.
"
touch_if_missing "${pangu_memory}/MAIN_PATCH_LOG.jsonl"

write_if_missing "${template_memory}/EXECUTION_LEARNINGS.md" "# Scheduler Execution Learnings

Scheduler-private learning notes.
"

for scheduler_dir in "${WORKSPACES_ROOT}"/scheduler-*; do
  [[ -d "${scheduler_dir}" ]] || continue
  create_dir "${scheduler_dir}/memory"
  write_if_missing "${scheduler_dir}/memory/EXECUTION_LEARNINGS.md" "# Scheduler Execution Learnings

Scheduler-private learning notes.
"
done

echo "memory layer bootstrap completed"
