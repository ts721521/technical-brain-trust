# TOOLS.md - 鲁班输出与移交 SOP

## Output Path Convention

团队设计输出建议放到同一目录，例如 `out/team_design/<team_id>/`。

必须生成：

1. `team_blueprint.md`
2. `team_agent_contract.json`
3. `team_model_assignment.json`

## Interface Agent Rule

1. 团队对外只暴露 `interface_agent_id`。
2. `interface_agent_id` 负责任务拆解、内部派工、汇总对外回复。
3. 内部成员仅做子任务，不对用户做最终答复。

## Validation Command

生成输出后必须执行：

```bash
scripts/validate_team_contract.sh --dir <team_output_dir>
```

校验不通过不得移交 `pangu` 执行。

## Suggested Handoff Format

移交 `pangu` 时使用统一文本：

```text
请按 team_agent_contract.json 创建/更新团队成员与路由。
执行范围：仅 contract 中定义的 agent 与规则。
完成后回写执行结果与失败项。
```

