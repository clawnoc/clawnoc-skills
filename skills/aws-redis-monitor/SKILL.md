---
name: aws-redis-monitor
description: Monitor AWS ElastiCache Redis clusters with anomaly detection
metadata: {"openclaw": {"always": false, "emoji": "*"}}
---

# AWS Redis Monitor

Monitor ElastiCache Redis clusters in AWS, detect anomalies by comparing current metrics against historical baselines.

## Prerequisites

- AWS CLI configured with valid credentials
- jq installed
- python3 installed

## Commands

### Global Overview (Daily Patrol)

```bash
~/.openclaw/workspace/skills/aws-redis-monitor/lib/redis-overview.sh [profile] [region] [hours]
```

Shows all clusters summary, highlights anomalies only. Default: last 24 hours.

### Single Cluster Detail

```bash
~/.openclaw/workspace/skills/aws-redis-monitor/lib/redis-detail.sh <cluster-name> [profile] [region] [hours]
```

Full metrics and hourly trend for a specific cluster.

### Pre/Post Deploy Compare

```bash
~/.openclaw/workspace/skills/aws-redis-monitor/lib/redis-compare.sh <cluster-name> <minutes> [profile] [region]
```

Compare metrics before and after a deployment. Default: 30 minutes window.

## Configuration

Edit `config.json` to define cluster groups and thresholds:

```json
{
  "groups": {
    "core": ["my-main-redis", "my-cache-redis"],
    "api": ["my-api-redis-01", "my-api-redis-02"]
  },
  "thresholds": {
    "cpu_warn": 70,
    "memory_warn": 80,
    "spike_ratio": 1.5,
    "drop_ratio": 0.5
  }
}
```

## Usage Patterns

When user asks:
- "Redis 巡检" / "Redis 状态" / "Redis overview" -> Run redis-overview.sh
- "xxx Redis 详情" / "xxx Redis detail" -> Run redis-detail.sh <cluster>
- "上线后 Redis 变化" / "Redis 对比" -> Run redis-compare.sh <cluster>
- "Redis CPU" / "Redis 内存" / "Redis 连接数" -> Run redis-overview.sh, highlight relevant metric

## Monitored Metrics

P0 (Critical):
- EngineCPUUtilization - CPU usage
- DatabaseMemoryUsagePercentage - Memory usage
- CurrConnections - Connection count
- CacheHitRate - Cache hit rate
- StringBasedCmdsLatency - Command latency

P1 (Important):
- GetTypeCmds, SetTypeCmds - Operations per second
- NetworkBytesIn, NetworkBytesOut - Network traffic
- Evictions - Key evictions
- ReplicationLag - Replication delay

## Output

- Only shows anomalous clusters in overview mode
- Anomaly detection: current vs 7-day same-period average
- Markers: [!] warning (>1.5x or <0.5x), [!!] critical (>2x or <0.3x)
- **IMPORTANT: The script output is pre-formatted plain text. Do NOT reformat, convert to markdown tables, or modify the output in any way. Display the raw output exactly as returned by the script.**
