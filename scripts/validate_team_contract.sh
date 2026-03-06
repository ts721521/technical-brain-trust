#!/usr/bin/env bash
set -euo pipefail

TEAM_DIR=""

usage() {
  cat <<'EOF'
Usage: validate_team_contract.sh --dir <team_output_dir>

Required files in <team_output_dir>:
  - team_blueprint.md
  - team_agent_contract.json
  - team_model_assignment.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      TEAM_DIR="${2:-}"
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

if [[ -z "${TEAM_DIR}" ]]; then
  echo "--dir is required" >&2
  usage
  exit 1
fi

if [[ ! -d "${TEAM_DIR}" ]]; then
  echo "team directory not found: ${TEAM_DIR}" >&2
  exit 1
fi

BLUEPRINT="${TEAM_DIR}/team_blueprint.md"
CONTRACT="${TEAM_DIR}/team_agent_contract.json"
MODELS="${TEAM_DIR}/team_model_assignment.json"

for f in "${BLUEPRINT}" "${CONTRACT}" "${MODELS}"; do
  if [[ ! -f "${f}" ]]; then
    echo "missing required file: ${f}" >&2
    exit 1
  fi
done

required_sections=(
  "## 目标与边界"
  "## 团队结构图"
  "## 角色职责"
  "## 对外接口 Agent"
  "## 内部协作流程"
  "## 风险与降级"
)
for sec in "${required_sections[@]}"; do
  if ! rg -Fq "${sec}" "${BLUEPRINT}"; then
    echo "team_blueprint.md missing section: ${sec}" >&2
    exit 1
  fi
done

python3 - "${CONTRACT}" "${MODELS}" <<'PY'
import json
import re
import sys
from pathlib import Path

contract_path = Path(sys.argv[1])
model_path = Path(sys.argv[2])

errors = []

def load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"invalid json: {path}: {exc}")
        return {}

contract = load_json(contract_path)
models = load_json(model_path)

def req_str(obj, key, ctx):
    v = obj.get(key)
    if not isinstance(v, str) or not v.strip():
        errors.append(f"{ctx}.{key} must be non-empty string")
        return ""
    return v.strip()

team_id = req_str(contract, "team_id", "team_agent_contract")
interface_agent_id = req_str(contract, "interface_agent_id", "team_agent_contract")

scope = contract.get("interface_scope")
if not isinstance(scope, list) or not scope or not all(isinstance(x, str) and x.strip() for x in scope):
    errors.append("team_agent_contract.interface_scope must be non-empty string array")

internal = contract.get("internal_agents")
if not isinstance(internal, list) or not internal:
    errors.append("team_agent_contract.internal_agents must be non-empty array")
    internal = []

internal_ids = []
for idx, item in enumerate(internal):
    if not isinstance(item, dict):
        errors.append(f"team_agent_contract.internal_agents[{idx}] must be object")
        continue
    aid = req_str(item, "agent_id", f"team_agent_contract.internal_agents[{idx}]")
    req_str(item, "role", f"team_agent_contract.internal_agents[{idx}]")
    for key in ("responsibilities", "handoff_inputs", "handoff_outputs"):
        val = item.get(key)
        if not isinstance(val, list) or not val or not all(isinstance(x, str) and x.strip() for x in val):
            errors.append(f"team_agent_contract.internal_agents[{idx}].{key} must be non-empty string array")
    if aid:
        internal_ids.append(aid)

if interface_agent_id and interface_agent_id not in internal_ids:
    errors.append("interface_agent_id must exist in internal_agents[].agent_id")

if len(internal_ids) != len(set(internal_ids)):
    errors.append("internal_agents[].agent_id must be unique")

rules = contract.get("dispatch_rules")
if not isinstance(rules, list) or not rules:
    errors.append("team_agent_contract.dispatch_rules must be non-empty array")
    rules = []

for idx, rule in enumerate(rules):
    if not isinstance(rule, dict):
        errors.append(f"dispatch_rules[{idx}] must be object")
        continue
    req_str(rule, "intent_class", f"dispatch_rules[{idx}]")
    target = req_str(rule, "target_agent_id", f"dispatch_rules[{idx}]")
    fallback = req_str(rule, "fallback_agent_id", f"dispatch_rules[{idx}]")
    if target and target not in internal_ids:
        errors.append(f"dispatch_rules[{idx}].target_agent_id not found in internal_agents")
    if fallback and fallback not in internal_ids:
        errors.append(f"dispatch_rules[{idx}].fallback_agent_id not found in internal_agents")

model_team_id = req_str(models, "team_id", "team_model_assignment")
if team_id and model_team_id and team_id != model_team_id:
    errors.append("team_id mismatch between team_agent_contract.json and team_model_assignment.json")

generated_by = req_str(models, "generated_by", "team_model_assignment")
if generated_by not in ("architect", "luban"):
    errors.append("team_model_assignment.generated_by must be architect|luban")

generated_at = req_str(models, "generated_at", "team_model_assignment")
if generated_at and not re.match(r"^\d{4}-\d{2}-\d{2}T", generated_at):
    errors.append("team_model_assignment.generated_at must be ISO-8601 timestamp")

g = models.get("global_constraints")
if not isinstance(g, dict):
    errors.append("team_model_assignment.global_constraints must be object")
    g = {}

openai_allowed = g.get("openai_allowed")
if openai_allowed != ["openai-codex/gpt-5.3-codex"]:
    errors.append("global_constraints.openai_allowed must equal ['openai-codex/gpt-5.3-codex']")

if not isinstance(g.get("provider_diversity_required"), bool):
    errors.append("global_constraints.provider_diversity_required must be boolean")

agent_models = models.get("agents")
if not isinstance(agent_models, list) or not agent_models:
    errors.append("team_model_assignment.agents must be non-empty array")
    agent_models = []

model_agent_ids = set()
for idx, item in enumerate(agent_models):
    if not isinstance(item, dict):
        errors.append(f"team_model_assignment.agents[{idx}] must be object")
        continue
    aid = req_str(item, "agent_id", f"team_model_assignment.agents[{idx}]")
    model_agent_ids.add(aid)
    primary = req_str(item, "primary_model", f"team_model_assignment.agents[{idx}]")
    fallback_models = item.get("fallback_models")
    if not isinstance(fallback_models, list) or not fallback_models or not all(isinstance(x, str) and x.strip() for x in fallback_models):
        errors.append(f"team_model_assignment.agents[{idx}].fallback_models must be non-empty string array")
    rationale = req_str(item, "selection_rationale", f"team_model_assignment.agents[{idx}]")
    if rationale and len(rationale) < 8:
        errors.append(f"team_model_assignment.agents[{idx}].selection_rationale is too short")
    workload = req_str(item, "workload_type", f"team_model_assignment.agents[{idx}]")
    if workload not in ("planning", "execution", "review", "ops"):
        errors.append(f"team_model_assignment.agents[{idx}].workload_type invalid")

    model_candidates = [primary] + (fallback_models if isinstance(fallback_models, list) else [])
    for m in model_candidates:
        if isinstance(m, str) and m.startswith("openai-codex/") and m != "openai-codex/gpt-5.3-codex":
            errors.append(f"OpenAI hard constraint violated for {aid}: {m}")

missing_model_agents = [aid for aid in internal_ids if aid not in model_agent_ids]
if missing_model_agents:
    errors.append("model assignment missing agents: " + ", ".join(missing_model_agents))

if errors:
    for e in errors:
        print(e, file=sys.stderr)
    raise SystemExit(1)

print("team contract validation passed.")
PY

