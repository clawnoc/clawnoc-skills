# Idle Resource Scanner / 闲置资源扫描

Detects underutilized AWS resources to help reduce cloud costs.

扫描 AWS 闲置资源，帮助降低云成本。

## What It Scans / 扫描范围

| Resource | Condition | Estimated Savings |
|----------|-----------|-------------------|
| EC2 | CPU < 5% for 7 days | $30-500/mo per instance |
| RDS | CPU < 5% for 7 days | $50-800/mo per instance |
| EBS | Unattached volumes | $8-100/mo per volume |
| EIP | Unassociated IPs | $3.65/mo per IP |
| NAT Gateway | < 1GB traffic in 7 days | $32+/mo per gateway |

## Environment Variables / 环境变量

| Variable | Description | Default |
|----------|-------------|---------|
| `LOOKBACK_DAYS` | Analysis period | `7` |
| `CPU_THRESHOLD` | CPU % threshold for idle | `5.0` |
| `NAT_BYTES_THRESHOLD` | NAT traffic threshold (bytes) | `1073741824` (1GB) |
| `NOTIFY_TYPE` | `dingtalk` / `feishu` / `slack` | `slack` |
| `WEBHOOK_URL` | Webhook endpoint URL | |

## Deploy / 部署

```bash
sam build && sam deploy --guided
```

## Sample Output / 示例输出

```
💰 Found 4 idle resources:
• EC2 i-0a1b2c3d4e (t3.medium) web-staging — CPU avg 1.2%
• RDS my-test-db (db.r5.large) — CPU avg 0.8%
• EBS vol-0abc123 50GB (gp3) — unattached
• EIP 203.0.113.10 (eipalloc-0abc) — unassociated
Estimated monthly savings: $200+
```

## IAM Permissions / 所需权限

ec2:Describe*, rds:DescribeDBInstances, cloudwatch:GetMetricStatistics

## License

MIT
