#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/verify_public_release.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

init_repo() {
  local repo="$1"
  mkdir -p "${repo}"
  git -C "${repo}" init -q
  git -C "${repo}" config user.email "bot@example.com"
  git -C "${repo}" config user.name "bot"
}

# Case 1: command substitution should not be treated as hardcoded credential.
repo_cmd_sub="${tmp_dir}/repo_cmd_sub"
init_repo "${repo_cmd_sub}"
mkdir -p "${repo_cmd_sub}/scripts"
cat >"${repo_cmd_sub}/scripts/phase2_runtime_convergence.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
gateway_token="$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(32))
PY
)"
EOF
git -C "${repo_cmd_sub}" add scripts/phase2_runtime_convergence.sh

"${SCRIPT}" --root "${repo_cmd_sub}" >/dev/null

# Case 2: literal credential must be blocked.
repo_literal="${tmp_dir}/repo_literal"
init_repo "${repo_literal}"
cat >"${repo_literal}/settings.env" <<'EOF'
API_TOKEN="hardcoded-token-12345678"
EOF
git -C "${repo_literal}" add settings.env

set +e
out="$("${SCRIPT}" --root "${repo_literal}" 2>&1)"
status=$?
set -e
if [[ ${status} -eq 0 ]]; then
  echo "expected literal credential case to fail" >&2
  exit 1
fi
printf '%s' "${out}" | rg -n "hardcoded_credential_like" >/dev/null

echo "verify_public_release tests passed"
