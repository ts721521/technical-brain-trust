#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_BRANCH="main"
RELEASE_BRANCH="release"
MANIFEST_FILE="${ROOT_DIR}/release/release_manifest.txt"
VERSION="v1.4.1"
DRY_RUN="false"
ALLOW_DIRTY="false"
REPORT_FILE="${ROOT_DIR}/release_publish_report.json"
WORKTREE_DIR="${ROOT_DIR}/.worktrees/release"

usage() {
  cat <<'USAGE'
Usage: build_release_branch.sh [options]

Options:
  --version <vX.Y.Z>          Release semantic version (default: v1.4.1)
  --source-branch <name>      Source branch (default: main)
  --release-branch <name>     Release branch (default: release)
  --manifest <path>           Manifest path (default: release/release_manifest.txt)
  --report <path>             Report output path (default: ./release_publish_report.json)
  --dry-run                   Build and verify only; do not update branch
  --allow-dirty               Allow dirty source worktree (default: false)
  -h, --help                  Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"; shift 2 ;;
    --source-branch)
      SOURCE_BRANCH="${2:-}"; shift 2 ;;
    --release-branch)
      RELEASE_BRANCH="${2:-}"; shift 2 ;;
    --manifest)
      MANIFEST_FILE="${2:-}"; shift 2 ;;
    --report)
      REPORT_FILE="${2:-}"; shift 2 ;;
    --dry-run)
      DRY_RUN="true"; shift ;;
    --allow-dirty)
      ALLOW_DIRTY="true"; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1 ;;
  esac
done

if [[ -z "${VERSION}" || ! "${VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid --version. expected vX.Y.Z" >&2
  exit 1
fi

if [[ ! -f "${MANIFEST_FILE}" ]]; then
  echo "Manifest file not found: ${MANIFEST_FILE}" >&2
  exit 1
fi

if ! git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repository: ${ROOT_DIR}" >&2
  exit 1
fi

if [[ "${ALLOW_DIRTY}" != "true" ]]; then
  if [[ -n "$(git -C "${ROOT_DIR}" status --porcelain)" ]]; then
    echo "Working tree is dirty. Commit/stash first or use --allow-dirty." >&2
    exit 1
  fi
fi

if ! git -C "${ROOT_DIR}" rev-parse --verify "${SOURCE_BRANCH}" >/dev/null 2>&1; then
  echo "Source branch not found: ${SOURCE_BRANCH}" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
TMP_SOURCE="${TMP_DIR}/source"
TMP_RELEASE="${TMP_DIR}/release"
mkdir -p "${TMP_SOURCE}" "${TMP_RELEASE}"

# Build source snapshot
current_branch="$(git -C "${ROOT_DIR}" rev-parse --abbrev-ref HEAD)"
if [[ "${ALLOW_DIRTY}" == "true" && "${current_branch}" == "${SOURCE_BRANCH}" ]]; then
  rsync -a --delete --exclude '.git/' --exclude '.worktrees/' "${ROOT_DIR}/" "${TMP_SOURCE}/"
else
  ( cd "${ROOT_DIR}" && git archive "${SOURCE_BRANCH}" | tar -x -C "${TMP_SOURCE}" )
fi

# Copy whitelist into release snapshot
while IFS= read -r line; do
  line="${line%%#*}"
  line="${line%$'\r'}"
  line="$(printf '%s' "${line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -z "${line}" ]] && continue

  src="${TMP_SOURCE}/${line}"
  dst="${TMP_RELEASE}/${line}"
  if [[ ! -e "${src}" ]]; then
    echo "manifest path not found in ${SOURCE_BRANCH}: ${line}" >&2
    exit 1
  fi
  mkdir -p "$(dirname "${dst}")"
  if [[ -d "${src}" ]]; then
    cp -R "${src}" "${dst}"
  else
    cp "${src}" "${dst}"
  fi
done <"${MANIFEST_FILE}"

# Public release safety verification
"${ROOT_DIR}/scripts/verify_public_release.sh" \
  --root "${TMP_RELEASE}" \
  --manifest "${MANIFEST_FILE}" \
  --enforce-manifest

files_count="$(find "${TMP_RELEASE}" -type f | wc -l | tr -d ' ')"
status="passed"
release_commit=""
release_tag="release-${VERSION}"
branch_updated="false"

if [[ "${DRY_RUN}" == "false" ]]; then
  mkdir -p "${ROOT_DIR}/.worktrees"

  if [[ -d "${WORKTREE_DIR}" ]]; then
    git -C "${ROOT_DIR}" worktree remove --force "${WORKTREE_DIR}" >/dev/null 2>&1 || true
  fi

  # Ensure local release branch exists
  if ! git -C "${ROOT_DIR}" show-ref --verify --quiet "refs/heads/${RELEASE_BRANCH}"; then
    if git -C "${ROOT_DIR}" ls-remote --exit-code --heads origin "${RELEASE_BRANCH}" >/dev/null 2>&1; then
      git -C "${ROOT_DIR}" fetch origin "${RELEASE_BRANCH}:${RELEASE_BRANCH}"
    else
      git -C "${ROOT_DIR}" branch "${RELEASE_BRANCH}" "${SOURCE_BRANCH}"
    fi
  fi

  git -C "${ROOT_DIR}" worktree add "${WORKTREE_DIR}" "${RELEASE_BRANCH}" >/dev/null

  rsync -a --delete --exclude='.git/' "${TMP_RELEASE}/" "${WORKTREE_DIR}/"

  if [[ -n "$(git -C "${WORKTREE_DIR}" status --porcelain)" ]]; then
    git -C "${WORKTREE_DIR}" add -A
    git -C "${WORKTREE_DIR}" commit -m "release: ${VERSION}" >/dev/null
    branch_updated="true"
  fi

  if git -C "${ROOT_DIR}" rev-parse --verify "refs/tags/${release_tag}" >/dev/null 2>&1; then
    echo "tag already exists: ${release_tag}" >&2
    exit 1
  fi

  git -C "${WORKTREE_DIR}" tag "${release_tag}"
  release_commit="$(git -C "${WORKTREE_DIR}" rev-parse HEAD)"
fi

python3 - "${REPORT_FILE}" "${VERSION}" "${SOURCE_BRANCH}" "${RELEASE_BRANCH}" "${status}" "${files_count}" "${branch_updated}" "${release_commit}" "${release_tag}" "${DRY_RUN}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

(
    report_file,
    version,
    source_branch,
    release_branch,
    status,
    files_count,
    branch_updated,
    release_commit,
    release_tag,
    dry_run,
) = sys.argv[1:]

obj = {
    "timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "release_version": version,
    "source_branch": source_branch,
    "release_branch": release_branch,
    "status": status,
    "files_count": int(files_count),
    "branch_updated": branch_updated.lower() == "true",
    "release_commit": release_commit,
    "release_tag": release_tag,
    "dry_run": dry_run.lower() == "true",
    "failures": [],
}
Path(report_file).write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

echo "release build completed: ${REPORT_FILE}"
if [[ "${DRY_RUN}" == "false" ]]; then
  echo "release branch updated: ${RELEASE_BRANCH}"
  echo "release tag created: ${release_tag}"
fi
