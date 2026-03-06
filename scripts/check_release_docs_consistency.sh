#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

failures=()

add_failure() {
  failures+=("$1")
}

require_file() {
  local f="$1"
  if [[ ! -f "${ROOT_DIR}/${f}" ]]; then
    add_failure "missing file: ${f}"
  fi
}

extract_release_version() {
  python3 - "${ROOT_DIR}/config/deployment_release.yaml" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding='utf-8')
m = re.search(r'^release_version:\s*"?([^"\n]+)"?', text, flags=re.M)
if not m:
    raise SystemExit(1)
print(m.group(1).strip())
PY
}

contains_literal() {
  local file="$1"
  local text="$2"
  rg -Fq "${text}" "${file}"
}

check_core_commands() {
  local file="$1"
  local label="$2"

  contains_literal "${file}" "./scripts/build_release_branch.sh --version" || add_failure "${label} missing command: build_release_branch"
  contains_literal "${file}" "git switch release" || add_failure "${label} missing command: git switch release"
  contains_literal "${file}" "./scripts/verify_public_release.sh --root . --manifest release/release_manifest.txt --enforce-manifest" || add_failure "${label} missing command: verify_public_release"
}

check_links_exist() {
  python3 - "${ROOT_DIR}" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
target_files = [
    root / "README.md",
    root / "DEPLOYMENT_RELEASE.md",
    root / "docs" / "RELEASE_OVERVIEW.md",
    root / "docs" / "AI_RELEASE_PROTOCOL.md",
    root / "docs" / "HUMAN_RELEASE_RUNBOOK.md",
]

missing = []
pattern = re.compile(r"\[[^\]]*\]\(([^)]+)\)")

for file in target_files:
    if not file.exists():
        continue
    text = file.read_text(encoding="utf-8")
    for m in pattern.finditer(text):
        link = m.group(1).strip()
        if not link or link.startswith("http://") or link.startswith("https://") or link.startswith("#"):
            continue
        link = link.split("#", 1)[0]
        path = (file.parent / link).resolve()
        if not path.exists():
            missing.append(f"{file.relative_to(root)} -> {link}")

if missing:
    for item in missing:
        print(item)
    raise SystemExit(1)
PY
}

require_file "README.md"
require_file "DEPLOYMENT_RELEASE.md"
require_file "docs/RELEASE_OVERVIEW.md"
require_file "docs/AI_RELEASE_PROTOCOL.md"
require_file "docs/HUMAN_RELEASE_RUNBOOK.md"

version="$(extract_release_version || true)"
if [[ -z "${version}" ]]; then
  add_failure "cannot parse release_version from config/deployment_release.yaml"
else
  for f in "DEPLOYMENT_RELEASE.md" "docs/RELEASE_OVERVIEW.md" "docs/AI_RELEASE_PROTOCOL.md" "docs/HUMAN_RELEASE_RUNBOOK.md"; do
    if [[ -f "${ROOT_DIR}/${f}" ]] && ! rg -Fq "${version}" "${ROOT_DIR}/${f}"; then
      add_failure "version mismatch: ${f} does not contain ${version}"
    fi
  done
fi

check_core_commands "${ROOT_DIR}/README.md" "README.md"
check_core_commands "${ROOT_DIR}/DEPLOYMENT_RELEASE.md" "DEPLOYMENT_RELEASE.md"
check_core_commands "${ROOT_DIR}/docs/RELEASE_OVERVIEW.md" "docs/RELEASE_OVERVIEW.md"
check_core_commands "${ROOT_DIR}/docs/AI_RELEASE_PROTOCOL.md" "docs/AI_RELEASE_PROTOCOL.md"
check_core_commands "${ROOT_DIR}/docs/HUMAN_RELEASE_RUNBOOK.md" "docs/HUMAN_RELEASE_RUNBOOK.md"

if ! check_links_exist >/tmp/check_release_docs_links.err 2>&1; then
  while IFS= read -r line; do
    [[ -n "${line}" ]] && add_failure "broken link: ${line}"
  done </tmp/check_release_docs_links.err
fi
rm -f /tmp/check_release_docs_links.err

if (( ${#failures[@]} > 0 )); then
  echo "release docs consistency check failed:" >&2
  for f in "${failures[@]}"; do
    echo "  - ${f}" >&2
  done
  exit 1
fi

echo "release docs consistency check passed."
