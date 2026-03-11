---
name: clawnoc-monitor
description: 监控告警 — 系统资源监控、告警配置、异常自动处理
metadata: {"openclaw": {"emoji": "📊"}}
---

# 监控告警

系统资源监控、告警规则管理、异常自动处理，支持推送到飞书/钉钉/Telegram。

## 能力

### 1. 系统资源监控
一键检查 CPU、内存、磁盘、网络状态。

```bash
# 综合资源检查
echo "=== CPU ==="
top -bn1 | head -5
echo "=== Memory ==="
free -h
echo "=== Disk ==="
df -h | grep -v tmpfs
echo "=== Load ==="
uptime
echo "=== Network ==="
ss -s
```

### 2. 进程级排查
定位资源消耗大户。

```bash
# CPU Top 10
ps aux --sort=-%cpu | head -11

# Memory Top 10
ps aux --sort=-%mem | head -11

# 检查 OOM 记录
dmesg | grep -i 'out of memory' | tail -5

# 检查僵尸进程
ps aux | awk '$8=="Z" {print}'
```

### 3. 告警规则配置
设置合理的监控阈值和告警策略。

```bash
# 磁盘使用率告警（阈值 85%）
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
if [ "$DISK_USAGE" -gt 85 ]; then
  echo "ALERT: Disk usage ${DISK_USAGE}% exceeds threshold"
fi

# 内存使用率告警（阈值 90%）
MEM_USAGE=$(free | awk '/Mem/{printf("%.0f"), $3/$2*100}')
if [ "$MEM_USAGE" -gt 90 ]; then
  echo "ALERT: Memory usage ${MEM_USAGE}% exceeds threshold"
fi

# CPU 负载告警（阈值：核心数 * 2）
CORES=$(nproc)
LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')
```

### 4. 日志异常检测
从日志中识别异常模式。

```bash
# 检查系统日志中的错误
journalctl --since "1 hour ago" --no-pager | \
  grep -iE 'error|fatal|timeout|refused|killed' | tail -20

# 检查 Nginx 错误日志
tail -100 /var/log/nginx/error.log | \
  awk '{print $NF}' | sort | uniq -c | sort -rn | head -10
```

### 5. 告警通知推送
支持多渠道告警通知。

```bash
# 飞书 Webhook
curl -X POST "$FEISHU_WEBHOOK" \
  -H 'Content-Type: application/json' \
  -d '{"msg_type":"text","content":{"text":"[ClawNOC] Alert: disk usage 92%"}}'

# 钉钉 Webhook
curl -X POST "$DINGTALK_WEBHOOK" \
  -H 'Content-Type: application/json' \
  -d '{"msgtype":"text","text":{"content":"[ClawNOC] Alert: disk usage 92%"}}'
```

## 告警分级

| 级别 | 条件 | 响应 |
|------|------|------|
| P0 | 服务不可用 | 立即自动处理 + 通知 |
| P1 | 资源 > 90% | 自动扩容/清理 + 通知 |
| P2 | 资源 > 80% | 记录 + 定时通知 |
| P3 | 异常趋势 | 记录 + 日报汇总 |
