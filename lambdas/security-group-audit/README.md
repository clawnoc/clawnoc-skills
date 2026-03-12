# Security Group Audit / 安全组审计

Scans AWS security groups for risky inbound rules, shows associated instances, and provides fix commands.

扫描 AWS 安全组的高危入站规则，显示关联实例，并提供修复命令。

## Features / 功能

- Detect 0.0.0.0/0 on sensitive ports (SSH, RDP, MySQL, Redis...) / 检测敏感端口公网开放
- Whitelist mechanism for known-safe SGs / 白名单机制
- Show associated EC2 instances / 显示关联 EC2 实例
- Provide AWS CLI fix commands / 提供修复命令
- Risk levels: CRITICAL / HIGH / MEDIUM / 风险分级

## Environment Variables / 环境变量

| Variable | Description | Default |
|----------|-------------|---------|
| `WHITELIST_SG_IDS` | Comma-separated SG IDs to skip | `` |
| `NOTIFY_TYPE` | `dingtalk` / `feishu` / `slack` | `slack` |
| `WEBHOOK_URL` | Webhook endpoint URL | |

## Deploy / 部署

```bash
sam build && sam deploy --guided
```

## Sample Output / 示例输出

```
🛡️ Found 3 risky security group rules:

[CRITICAL] sg-0abc123 (default)
  → All traffic open to internet
  → Instances: i-0a1b2c (web-prod), i-0d4e5f (api-prod)
  → Fix: aws ec2 revoke-security-group-ingress --group-id sg-0abc123 --protocol -1 --cidr 0.0.0.0/0

[HIGH] sg-0def456 (db-access)
  → MySQL (port 3306) open to internet
  → Instances: i-0g7h8i (mysql-primary)
  → Fix: aws ec2 revoke-security-group-ingress --group-id sg-0def456 --protocol tcp --port 3306 --cidr 0.0.0.0/0
```

## License

MIT
