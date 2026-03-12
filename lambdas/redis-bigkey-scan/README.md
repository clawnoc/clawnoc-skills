# Redis Big Key Scanner / Redis 大 Key 扫描

Scans ElastiCache Redis clusters for oversized keys that may cause performance issues.

扫描 ElastiCache Redis 集群中的大 Key，避免性能问题。

## Features / 功能

- Auto-discover ElastiCache endpoints / 自动发现 ElastiCache 端点
- Scan all key types: String, Hash, List, Set, ZSet, Stream / 支持所有类型
- Configurable thresholds for memory size and element count / 可配置阈值
- Pluggable notifications / 可插拔通知

## ⚠️ Network Requirements / 网络要求

**Lambda must be deployed inside a VPC** that can reach your ElastiCache cluster. You need:

1. Lambda in the same VPC as ElastiCache (or peered VPC)
2. Security Group allowing outbound to ElastiCache port (6379)
3. If Lambda needs internet (for webhooks), add a NAT Gateway

**Lambda 必须部署在能访问 ElastiCache 的 VPC 内。**

## Environment Variables / 环境变量

| Variable | Description | Default |
|----------|-------------|---------|
| `CLUSTER_ID` | Specific cluster (empty = scan all) | `` |
| `SIZE_THRESHOLD` | Memory threshold in bytes | `10240` (10KB) |
| `COUNT_THRESHOLD` | Element count threshold | `10000` |
| `SCAN_COUNT` | Keys per SCAN iteration | `1000` |
| `NOTIFY_TYPE` | `dingtalk` / `feishu` / `slack` | `slack` |
| `WEBHOOK_URL` | Webhook endpoint URL | |

## Deploy / 部署

```bash
sam build && sam deploy --guided \
  --parameter-overrides \
    VpcSubnetIds=subnet-abc123,subnet-def456 \
    VpcSecurityGroupIds=sg-abc123
```

## Sample Output / 示例输出

```
🔴 Redis Big Keys: 3 found
🔑 my-cache | user:session:abc123 | hash | 256.3KB
🔑 my-cache | queue:pending | list | 15.7KB
🔑 my-cache | events:stream | stream | 89.2KB
```

## License

MIT
