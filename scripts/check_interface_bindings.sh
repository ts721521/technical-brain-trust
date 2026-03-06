#!/usr/bin/env bash
set -euo pipefail

# Validate interface-agent bindings are present and include required intent routes.

required_bindings_default="proposal:proposal_lead,rd:rd_lead,smart3d:smart3d_lead,knowledge_learning:scholar"
required_bindings="${BT_REQUIRED_BINDINGS:-${required_bindings_default}}"

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw command not found" >&2
  exit 2
fi

bindings_json="$(openclaw agents bindings --json 2>/dev/null || true)"
if [[ -z "${bindings_json}" ]]; then
  echo "bindings check failed: empty output from 'openclaw agents bindings --json'" >&2
  exit 1
fi

python3 - "${bindings_json}" "${required_bindings}" <<'PY'
import json
import sys

raw = sys.argv[1]
required = [p.strip() for p in sys.argv[2].split(",") if p.strip()]

try:
    data = json.loads(raw)
except Exception as exc:
    print(f"bindings check failed: invalid JSON ({exc})", file=sys.stderr)
    raise SystemExit(1)

if not isinstance(data, list) or len(data) == 0:
    print("bindings check failed: no bindings configured", file=sys.stderr)
    print("repair hint: current CLI supports list-only for bindings; update main routing rules in ~/.openclaw/workspace/AGENTS.md and verify with this script", file=sys.stderr)
    raise SystemExit(1)


def pick(row, keys):
    for k in keys:
        if k in row and row[k] not in (None, ""):
            return str(row[k]).strip()
    return ""

rows = []
for obj in data:
    if not isinstance(obj, dict):
        continue
    intent = pick(obj, ["intent_class", "intent", "pattern", "route"])
    target = pick(obj, ["target_agent", "target", "agent", "interface_agent"])
    rows.append((intent, target))

missing = []
for item in required:
    if ":" not in item:
        continue
    intent_need, target_need = item.split(":", 1)
    intent_need = intent_need.strip()
    target_need = target_need.strip()
    found = any(i == intent_need and t == target_need for i, t in rows)
    if not found:
        missing.append(f"{intent_need}:{target_need}")

if missing:
    print("bindings check failed: missing required routes:", file=sys.stderr)
    for m in missing:
        print(f"  - {m}", file=sys.stderr)
    print("repair hint: update ~/.openclaw/workspace/AGENTS.md route rules (interface_agent_id) and ensure runtime bindings are regenerated", file=sys.stderr)
    raise SystemExit(1)

print("bindings check passed")
PY
