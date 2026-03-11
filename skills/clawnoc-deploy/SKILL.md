---
name: clawnoc-deploy
description: 部署检查与回滚 — 部署验证、健康检查、灰度发布、自动回滚
metadata: {"openclaw": {"emoji": "🚀"}}
---

# 部署检查与回滚

部署前检查、部署中监控、部署后验证，支持自动回滚。

## 能力

### 1. 部署前检查
部署前的环境和依赖验证。

```bash
# 检查目标服务器连通性
for host in server1 server2 server3; do
  echo -n "$host: "
  ssh -o ConnectTimeout=3 $host "echo OK" 2>/dev/null || echo "FAIL"
done

# 检查磁盘空间是否足够
df -h /data | awk 'NR==2{if($5+0 > 80) print "WARNING: disk usage "$5; else print "OK: "$5}'

# 检查当前服务状态
systemctl is-active your-service
```

### 2. 健康检查
部署后的服务健康验证。

```bash
# HTTP 健康检查
check_health() {
  local url=$1
  local code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url")
  local time=$(curl -s -o /dev/null -w '%{time_total}' --max-time 5 "$url")
  echo "Status: $code | Response: ${time}s"
}

check_health "http://localhost/health"
check_health "http://localhost/api/status"

# 持续观察（部署后 5 分钟）
for i in $(seq 1 30); do
  echo "$(date +%H:%M:%S): $(curl -s -o /dev/null -w '%{http_code} %{time_total}s' http://localhost/health)"
  sleep 10
done
```

### 3. 灰度发布验证
逐步放量并验证。

```bash
# 灰度发布流程
# 1. 部署到 1 台 → 验证
# 2. 扩展到 10% → 观察 5 分钟
# 3. 扩展到 50% → 观察 10 分钟
# 4. 全量发布

# 关键指标对比
# - 错误率：部署前 vs 部署后
# - 响应时间：P50 / P95 / P99
# - 资源使用：CPU / Memory
```

### 4. 自动回滚
检测到异常时自动回滚。

```bash
# 回滚决策条件
# - HTTP 5xx 错误率 > 1%
# - P95 响应时间 > 基线 * 3
# - 健康检查连续失败 3 次

# 回滚操作
rollback() {
  echo "$(date): Rolling back to previous version..."
  # 切换到上一个版本
  # 重启服务
  # 验证回滚成功
  echo "$(date): Rollback complete, verifying..."
}
```

## 部署清单

### 部署前
- [ ] 代码已通过 CI 测试
- [ ] 配置文件已更新
- [ ] 数据库迁移已准备
- [ ] 回滚方案已确认
- [ ] 相关人员已通知

### 部署后
- [ ] 健康检查通过
- [ ] 核心功能验证通过
- [ ] 错误率无异常
- [ ] 响应时间无异常
- [ ] 监控告警正常
