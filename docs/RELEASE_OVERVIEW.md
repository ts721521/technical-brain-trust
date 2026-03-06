# Release Overview (v1.6.8)

## 1. 机制总览（文字图）

`main`（内部迭代）
-> `build_release_branch`（白名单构建）
-> `release`（公开可复制包）
-> `verify_public_release + check_release_docs_consistency`（门禁）
-> `push release + tags`（发布完成）

## 2. 文档索引

- AI 协议：[AI_RELEASE_PROTOCOL.md](./AI_RELEASE_PROTOCOL.md)
- 人类手册：[HUMAN_RELEASE_RUNBOOK.md](./HUMAN_RELEASE_RUNBOOK.md)
- 存储规范：[TEAM_STORAGE_POLICY.md](./TEAM_STORAGE_POLICY.md)
- 发布元数据：[../config/deployment_release.yaml](../config/deployment_release.yaml)
- 变更记录：[../DEPLOYMENT_CHANGELOG.md](../DEPLOYMENT_CHANGELOG.md)
- 发布入口：[../DEPLOYMENT_RELEASE.md](../DEPLOYMENT_RELEASE.md)

## 3. Quick Path（最短路径命令）

```bash
# on main
./scripts/build_release_branch.sh --version vX.Y.Z

# on release
git switch release
./scripts/verify_public_release.sh --root . --manifest release/release_manifest.txt --enforce-manifest
./scripts/check_release_docs_consistency.sh

git push origin release --tags
```

## 4. 分工建议

- AI 执行主流程，减少人为遗漏。
- 人类负责版本决策、异常确认和回滚批准。
- 所有发布必须留有 `release_publish_report.json` 证据。
