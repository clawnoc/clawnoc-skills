# Cost Anomaly Alert / 成本异常告警

Monitors AWS spending and alerts on anomalies. Includes daily checks, weekly reports, and monthly forecasts.

监控 AWS 费用异常，支持每日检查、周报对比、月度预测。

## Features / 功能

- Daily cost with day-over-day comparison / 每日费用环比
- Weekly report: this week vs last week / 周报：本周 vs 上周
- Monthly forecast based on current burn rate / 基于当前消费速度的月度预测
- Cost breakdown by tag (team, env, etc.) / 按标签分组（team、env 等）
- Pluggable notifications / 可插拔通知

## ⚠️ Important / 注意

**Cost Explorer API must be called from `us-east-1`**, regardless of where your resources are. The Lambda is configured to use `us-east-1` for the CE client.

**Cost Explorer API 必须从 `us-east-1` 调用。**

## Environment Variables / 环境变量

| Variable | Description | Default |
|----------|-------------|---------|
| `DAILY_THRESHOLD` | Alert if daily cost exceeds ($) | `100` |
| `GROUP_BY_TAG` | Tag key for cost breakdown | `team` |
| `MODE` | `daily` (includes weekly on Mon) or `weekly` | `daily` |
| `NOTIFY_TYPE` | `dingtalk` / `feishu` / `slack` | `slack` |
| `WEBHOOK_URL` | Webhook endpoint URL | |

## Deploy / 部署

```bash
sam build && sam deploy --guided
```

## Sample Output / 示例输出

```
💸 AWS Cost Alert
Yesterday: $127.34 (+23% vs day before)
Day before: $103.52
Monthly forecast: $3,820

By team:
  backend: $67.20
  data: $42.15
  (untagged): $17.99
```

## License

MIT
