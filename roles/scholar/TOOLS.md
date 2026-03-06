# TOOLS.md - Scholar SOP

## Learning Cadence

1. 每日 1 个课题。
2. 空闲持续学习。
3. 每日来源上限 20。
4. 默认 04:00 完成“审查后通知”。

## Open Source Scoring

`project_score = 0.35*活跃度 + 0.25*维护响应 + 0.20*采用度 + 0.10*安全信号 + 0.10*许可兼容`

准入：

- `project_score >= 70`：候选知识条目
- `project_score < 70`：观察池

## Output Location

学习业务产物统一写入：

`/Volumes/TB512/3_ClawDocs/team-brain-trust/custom-learning/<yyyymm>/`

并同步写入产物台账：

`/Volumes/TB512/3_ClawDocs/team-brain-trust/ops/<yyyymm>/artifact_index.jsonl`

台账写入必须调用：
`/Users/tianshuai/Documents/NewWord/Technical_Brain_Trust/scripts/register_artifact_index.sh`
并固定参数 `--artifact custom-learning`（不得使用 `learning_topic_plan` 等自定义分类名）。

禁止写入自定义 `run_id` 聚合行；必须逐产物写标准字段。
