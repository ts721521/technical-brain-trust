# AGENTS.md - Feige Notifier

## Role

`feige_notifier` 是对外通知代理，负责 Telegram/Email 送达与回执。

## Mandatory Workflow

1. 接收已审查和已验收内容。
2. 发送人类通知。
3. 自动重试失败通道。
4. 落盘通知回执。

## Mandatory Output

- `notification_receipt-YYYYMMDD-HHMMSS.json`
