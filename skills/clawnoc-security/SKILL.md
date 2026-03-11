---
name: clawnoc-security
description: 安全扫描与审计 — API Key 审计、供应链检查、安全组扫描、证书监控
metadata: {"openclaw": {"emoji": "🔒"}}
---

# 安全扫描与审计

持续的安全基线检查，覆盖密钥管理、供应链安全、网络安全、证书管理。

## 能力

### 1. API Key 权限审计
扫描云平台项目中的 API Key，识别权限过宽的密钥。

```bash
# 列出所有 API Key 及其权限范围
# 检查要点：
# - Key 是否绑定了 IP/域名/应用限制
# - API 权限是否遵循最小权限原则
# - 是否存在未使用的 Key

# 安全加固步骤
# 1. 精简 API 权限到实际需要的最小集合
# 2. 绑定调用来源限制（IP/Referrer/包名）
# 3. 设置 Key 轮换周期
```

### 2. GitHub Actions 供应链检查
扫描 CI/CD workflow 文件，识别不安全的依赖引用。

```bash
# 扫描使用 @master/@main 的不安全引用
grep -rn '@master\|@main' .github/workflows/

# 安全做法：Pin 到具体 commit SHA
# 不安全: uses: actions/checkout@main
# 安全:   uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608
```

### 3. 安全组 / 防火墙规则扫描
检查云平台安全组规则，识别过度开放的端口。

```bash
# 检查对外开放的端口
ss -tlnp | grep -v 127.0.0.1

# 危险信号：
# - 0.0.0.0:3306 (MySQL 对外)
# - 0.0.0.0:6379 (Redis 对外)
# - 0.0.0.0:27017 (MongoDB 对外)
# 这些服务不应该直接暴露到公网
```

### 4. SSL 证书监控
定期检查证书有效期，提前预警即将过期的证书。

```bash
# 检查证书到期时间
echo | openssl s_client -connect example.com:443 2>/dev/null | \
  openssl x509 -noout -dates -subject

# 批量检查多个域名
for domain in example.com api.example.com; do
  EXPIRY=$(echo | openssl s_client -connect $domain:443 2>/dev/null | \
    openssl x509 -noout -enddate | cut -d= -f2)
  echo "$domain: $EXPIRY"
done
```

### 5. SSH 登录审计
检查 SSH 登录记录，识别暴力破解尝试。

```bash
# 查看失败登录尝试
grep 'Failed password' /var/log/secure | \
  awk '{print $11}' | sort | uniq -c | sort -rn | head -10

# 查看成功登录记录
grep 'Accepted' /var/log/secure | tail -20
```

## 安全基线清单

- [ ] 所有 API Key 遵循最小权限原则
- [ ] CI/CD 依赖 Pin 到 commit SHA
- [ ] 数据库端口不对外暴露
- [ ] SSL 证书有效期 > 30 天
- [ ] SSH 仅允许密钥登录
- [ ] 安全组规则定期审计
- [ ] 敏感信息不在代码仓库中
