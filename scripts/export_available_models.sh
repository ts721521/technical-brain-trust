#!/usr/bin/env bash
set -euo pipefail

out_dir=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") --out <dir>
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      out_dir="${2:-}"
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

if [[ -z "${out_dir}" ]]; then
  echo "--out is required" >&2
  usage
  exit 1
fi

mkdir -p "${out_dir}"

models_raw="${out_dir}/available_models.raw.txt"
openclaw models list >"${models_raw}"

json_out="${out_dir}/available_models.json"
md_out="${out_dir}/available_models.md"

python3 - "${models_raw}" "${json_out}" "${md_out}" <<'PY'
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

raw_path = Path(sys.argv[1])
json_out = Path(sys.argv[2])
md_out = Path(sys.argv[3])

models = []
for line in raw_path.read_text(encoding="utf-8").splitlines():
    s = line.strip()
    if not s or s.startswith("Model "):
        continue
    parts = s.split()
    model = parts[0]
    if "/" not in model:
        continue
    provider = model.split("/", 1)[0]
    models.append({"model": model, "provider": provider, "raw": s})

roles = {}
for role in ("architect", "critic", "innovator"):
    default = subprocess.check_output(
        ["openclaw", "models", "status", "--agent", role, "--plain"], text=True
    ).splitlines()[-1].strip()
    fb_lines = subprocess.check_output(
        ["openclaw", "models", "--agent", role, "fallbacks", "list"], text=True
    ).splitlines()[1:]
    fallbacks = []
    for ln in fb_lines:
        ln = ln.strip()
        if ln.startswith("- "):
            fallbacks.append(ln[2:].strip())
    roles[role] = {"default": default, "fallbacks": fallbacks}

payload = {
    "timestamp": datetime.utcnow().isoformat() + "Z",
    "models": models,
    "roles": roles,
}
json_out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

providers = sorted({m["provider"] for m in models})
md = []
md.append("# 可用模型快照")
md.append("")
md.append(f"- 生成时间（UTC）：`{payload['timestamp']}`")
md.append(f"- 可用模型数：`{len(models)}`")
md.append(f"- 供应商：`{', '.join(providers)}`")
md.append("")
md.append("## 角色当前绑定")
md.append("")
md.append("| 角色 | 主模型 | fallback 列表 |")
md.append("|---|---|---|")
for role in ("architect", "critic", "innovator"):
    info = roles[role]
    md.append(f"| {role} | `{info['default']}` | `{', '.join(info['fallbacks'])}` |")
md.append("")
md.append("## 全量模型（按输出顺序）")
md.append("")
for item in models:
    md.append(f"- `{item['model']}` ({item['provider']})")
md_out.write_text("\n".join(md) + "\n", encoding="utf-8")
PY

echo "Exported model inventory:"
echo "  - ${json_out}"
echo "  - ${md_out}"
