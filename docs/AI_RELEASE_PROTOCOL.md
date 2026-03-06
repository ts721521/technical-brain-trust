# AI Release Protocol (v1.6.4)

本文件定义“后续由 AI 提交”时的标准发布协议。

## 1. 角色定义

- 开发AI：在 `main` 分支完成功能迭代与回归。
- 发布AI：负责将 `main` 生成为 `release` 可公开包并推送。
- 审核AI：负责执行发布前安全与一致性检查。

## 2. 强制流程

1. 在 `main` 完成改动并通过回归。
2. 执行 dry-run 构建：
   - `./scripts/build_release_branch.sh --version vX.Y.Z --dry-run --allow-dirty`
3. 执行正式构建：
   - `./scripts/build_release_branch.sh --version vX.Y.Z`
4. 切换到 `release` 并做公开校验：
   - `git switch release`
   - `./scripts/verify_public_release.sh --root . --manifest release/release_manifest.txt --enforce-manifest`
   - `./scripts/check_release_docs_consistency.sh`
5. 推送发布分支与 tag：
   - `git push origin release --tags`

## 3. 阻断条件（任一命中即停止发布）

- `verify_public_release.sh` 失败。
- `check_release_docs_consistency.sh` 失败。
- `release_manifest.txt` 与 release 跟踪文件不一致。
- 出现敏感信息命中（密钥模式、私钥块、个人绝对路径）。

## 4. 固定命令模板

```bash
./scripts/build_release_branch.sh --version vX.Y.Z

git switch release
./scripts/verify_public_release.sh --root . --manifest release/release_manifest.txt --enforce-manifest
./scripts/check_release_docs_consistency.sh

git push origin release --tags
```

## 5. 输出契约

- 必须产出 `release_publish_report.json`。
- 提交说明必须引用：
  - 发布版本（例如 `v1.6.4`）
  - 报告路径：`release_publish_report.json`
  - 校验结果：`verify_public_release` 与 `check_release_docs_consistency`。

## 6. 禁止事项

- 禁止手工直接修改 `release` 分支内容（除紧急修复且有留痕）。
- 禁止绕过公开安全检查直接推送 `release`。
- 禁止把运行态产物（`reviews/`、`tmp/`、`*.stderr`、`*.bak`）放入发布包。
