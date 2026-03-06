#!/usr/bin/env bash
set -euo pipefail

# Validate OpenClaw agent channel/account bindings visibility.
# Note: `openclaw agents bindings` reports delivery bindings, not intent routing rules.

strict="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      strict="true"
      shift
      ;;
    -h|--help)
      cat <<USAGE
Usage: $(basename "$0") [--strict]

Default:
  - Validate command/JSON shape
  - If no bindings exist, print warning and exit 0

Strict mode:
  - If no bindings exist, exit 1
USAGE
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -x "$(command -v openclaw || true)" ]]; then
  echo "openclaw command not found" >&2
  exit 2
fi

bindings_json="$(openclaw agents bindings --json 2>/dev/null || true)"
if [[ -z "${bindings_json}" ]]; then
  echo "bindings check failed: empty output from 'openclaw agents bindings --json'" >&2
  exit 1
fi

python3 - "${bindings_json}" "${strict}" <<'PY'
import json
import sys

raw = sys.argv[1]
strict = sys.argv[2].lower() == "true"

try:
    data = json.loads(raw)
except Exception as exc:
    print(f"bindings check failed: invalid JSON ({exc})", file=sys.stderr)
    raise SystemExit(1)

if not isinstance(data, list):
    print("bindings check failed: payload is not a list", file=sys.stderr)
    raise SystemExit(1)

count = len(data)
if count == 0:
    msg = (
        "bindings check warning: no explicit channel bindings configured. "
        "This may be valid in default routing mode; use --strict to enforce non-empty bindings."
    )
    if strict:
        print(msg, file=sys.stderr)
        raise SystemExit(1)
    print(msg)
    raise SystemExit(0)

print(f"bindings check passed: {count} binding(s) found")
PY
