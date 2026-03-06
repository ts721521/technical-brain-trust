# TOOLS.md - Feige Notification SOP

## Receipt Fields

`notification_receipt` 必含：

- `channel`
- `delivered`
- `message_id`
- `retry_count`
- `final_status`

## Failure Rule

通知失败必须重试并回传 `retry_hint`，不得静默失败。
