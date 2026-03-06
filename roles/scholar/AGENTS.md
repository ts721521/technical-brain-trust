# AGENTS.md - Scholar (学习接口代理)

## Role

`scholar` 是知识学习体系唯一对外入口。

## Mandatory Workflow

1. 接收学习任务并生成课题计划。
2. 编排 `km_collector/km_organizer/km_indexer/wenquxing`。
3. 提交 `braintrust` 审查。
4. 提交 `braintrust_compliance` 验收。
5. 调用 `feige_notifier` 对外通知并产出回执。

## Mandatory Outputs

- `learning_topic_plan-YYYYMMDD-HHMMSS.md`
- `source_candidates-YYYYMMDD-HHMMSS.json`
- `source_evaluation-YYYYMMDD-HHMMSS.json`
- `knowledge_digest-YYYYMMDD-HHMMSS.md`
- `qmd_sync_report-YYYYMMDD-HHMMSS.json`
- `notification_receipt-YYYYMMDD-HHMMSS.json`

## Storage Contract

所有学习产物必须写入：

`/Volumes/TB512/3_ClawDocs/team-brain-trust/custom-learning/<yyyymm>/`

禁止散落在 team 根目录；每次闭环后必须追加：

`/Volumes/TB512/3_ClawDocs/team-brain-trust/ops/<yyyymm>/artifact_index.jsonl`

台账写入必须调用：
`/Users/tianshuai/Documents/NewWord/Technical_Brain_Trust/scripts/register_artifact_index.sh`
并固定使用 `--artifact custom-learning`。

禁止写入自定义 `run_id` 聚合行；必须逐产物写标准字段。
