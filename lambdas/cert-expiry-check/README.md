# SSL Certificate Expiry Checker / SSL 证书到期检查

Automated SSL/TLS certificate expiry monitoring via AWS Lambda. Alerts to DingTalk, Feishu, or Slack when certificates are about to expire.

通过 AWS Lambda 自动监控 SSL/TLS 证书到期时间，支持钉钉、飞书、Slack 告警。

## Features / 功能

- Check multiple domains in one invocation / 一次检查多个域名
- Configurable warning threshold (default 30 days) / 可配置告警阈值（默认 30 天）
- Pluggable notifications: DingTalk, Feishu, Slack / 可插拔通知：钉钉、飞书、Slack
- Scheduled via EventBridge (daily) / 通过 EventBridge 定时触发（每天）

## Environment Variables / 环境变量

| Variable | Description | Example |
|----------|-------------|---------|
| `DOMAINS` | Comma-separated domain list | `example.com,api.example.com` |
| `WARN_DAYS` | Alert if expiry within N days | `30` |
| `NOTIFY_TYPE` | `dingtalk` / `feishu` / `slack` | `slack` |
| `WEBHOOK_URL` | Webhook endpoint URL | `https://hooks.slack.com/...` |

## Deploy / 部署

```bash
# Using SAM CLI
sam build && sam deploy --guided

# Or manually zip and upload
zip -r function.zip lambda_function.py ../shared/notifier.py
aws lambda create-function --function-name cert-expiry-check \
  --runtime python3.12 --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip --role <your-role-arn>
```

## Sample Output / 示例输出

```
⚠️ api.example.com — Expires: 2026-04-02 (21 days)
✅ example.com — Expires: 2026-09-15 (187 days)
```

## License

MIT
