# Team Storage Policy (v1.6.6)

## 目的

统一所有团队业务产物落盘路径，避免混放在仓库盘或临时目录。

## 强制根路径

- 默认：`/Volumes/TB512/3_ClawDocs`
- 可覆盖：`BT_DOCS_ROOT`
- 规则：业务产物禁止写入 `reviews/`、`/tmp`、`*.stderr`（运行临时文件除外）。

## 目录结构（根后最多三级）

业务产物目录必须为：

`<docs_root>/<team>/<artifact>/<yyyymm>/`

- `team`：`team-<kebab>`
- `artifact`：`review|execution|deploy|release|evidence|ops|custom-<kebab>`
- `yyyymm`：例如 `202603`

## 文件命名规范

建议文件名模式：

`^[a-z0-9]+(-[a-z0-9]+)*-[0-9]{8}-[0-9]{6}\.[a-z0-9]+$`

示例：

- `braintrust-summary-20260306-213000.md`
- `rd-acceptance-20260306-214500.json`

## 产物台账

每次产物生成后，必须写入：

`<docs_root>/<team>/ops/<yyyymm>/artifact_index.jsonl`

字段：

- `timestamp`
- `team`
- `artifact`
- `topic`
- `path`
- `producer_script`
- `status`
- `hash_sha256`（可选）

## 错误码与恢复

- `docs_root_unavailable`：外置盘不可用或不可写
- `path_policy_violation`：路径不在 docs_root 或命名不合法
- `depth_exceeded`：根后目录层级不符合要求

恢复命令示例：

```bash
export BT_DOCS_ROOT=/Volumes/TB512/3_ClawDocs
scripts/validate_docs_path_policy.sh \
  --docs-root "$BT_DOCS_ROOT" \
  --out "$BT_DOCS_ROOT/team-brain-trust/review/$(date +%Y%m)"
```

## 团队接入规则

1. 新团队先注册 `team-<kebab>`。
2. 所有业务脚本默认输出到该团队目录。
3. 运行临时文件可在 `/tmp`，但最终业务产物必须回写 docs root。
