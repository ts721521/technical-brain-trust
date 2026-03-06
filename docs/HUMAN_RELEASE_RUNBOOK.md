# Human Release Runbook (v1.6.10)

本手册面向人类维护者，用于执行与排障发布流程。

## 1. 什么时候需要发布

满足任一条件时触发发布：

- 评审/执行脚本有功能改动。
- 部署策略、模型策略、发布策略有变更。
- 公开文档、协议文档有更新，需要同步给其他 AI。

## 2. 一次发布的完整步骤（5步）

1. 在 `main` 完成改动并提交。
2. 先做 dry-run：
   - `./scripts/build_release_branch.sh --version vX.Y.Z --dry-run --allow-dirty`
3. 正式生成 release 分支内容：
   - `./scripts/build_release_branch.sh --version vX.Y.Z`
4. 切到 `release` 运行公开校验：
   - `git switch release`
   - `./scripts/verify_public_release.sh --root . --manifest release/release_manifest.txt --enforce-manifest`
   - `./scripts/check_release_docs_consistency.sh`
5. 推送发布：
   - `git push origin release --tags`

## 3. 常见失败与修复

### 3.1 manifest 缺项

现象：`tracked file not in manifest`。

处理：
- 把必要文件加入 `release/release_manifest.txt`。
- 重跑 dry-run。

### 3.2 路径泄漏

现象：`absolute_user_path` 命中。

处理：
- 清理文档中的个人绝对路径（如 `/Users/<name>/...`）。
- 改为占位符路径（如 `/path/to/...` 或 `~/.openclaw/...`）。

### 3.3 tag 冲突

现象：`tag already exists`。

处理：
- 版本号递增重新发布（推荐）。
- 或先删除错误 tag（见回滚步骤）。

### 3.4 release 分支脏状态

现象：`release` 工作树有未提交改动。

处理：
- 切回 `main`，确认变更来源。
- 清理无关改动后重跑构建脚本。

## 4. 回滚步骤

1. 删除错误本地 tag：
   - `git tag -d release-vX.Y.Z`
2. 删除远端错误 tag：
   - `git push origin :refs/tags/release-vX.Y.Z`
3. 回退 `release` 到上一个稳定 tag：
   - `git switch release`
   - `git reset --hard <last-good-release-commit>`
   - `git push --force-with-lease origin release`

## 5. 验收清单

### 发布前

- [ ] `build_release_branch.sh --dry-run` 通过
- [ ] `verify_public_release.sh` 通过
- [ ] `check_release_docs_consistency.sh` 通过

### 发布后

- [ ] `release` 分支和 tag 推送成功
- [ ] `release_publish_report.json` 已记录在提交说明
- [ ] 发布版本与 `config/deployment_release.yaml.release_version` 一致
