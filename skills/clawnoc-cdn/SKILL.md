---
name: clawnoc-cdn
description: CDN 缓存管理与诊断 — 清缓存、查命中率、追踪回源链路
metadata: {"openclaw": {"emoji": "🌐"}}
---

# CDN 缓存管理

管理和诊断 CDN 缓存问题，支持 CloudFront、CloudFlare 等主流 CDN。

## 能力

### 1. 缓存清理
清理指定域名或路径的 CDN 缓存。

```bash
# CloudFront 创建失效
aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*"

# 验证缓存是否已清
curl -sI https://example.com/style.css | grep -E 'x-cache|age|cf-cache'
```

### 2. 缓存命中率分析
检查 CDN 缓存命中率，识别低命中率的资源。

```bash
# 检查单个资源的缓存状态
curl -sI https://example.com/path | grep -iE 'cache|age|x-cache|cf-cache-status'

# 对比源站和 CDN 的内容一致性
diff <(curl -s https://origin.example.com/file | md5sum) \
     <(curl -s https://cdn.example.com/file | md5sum)
```

### 3. 回源链路追踪
当缓存不生效时，追踪请求从 CDN 到源站的完整链路。

```bash
# 追踪请求链路
curl -sI -H "Cache-Control: no-cache" https://example.com/path

# 检查 DNS 解析是否指向正确的 CDN
dig +short example.com
nslookup example.com
```

## 排查流程

遇到 CDN 相关问题时，按以下顺序排查：

1. **确认现象** — 用 curl -I 检查响应头，确认是否命中缓存
2. **检查 DNS** — 确认域名解析到正确的 CDN 节点
3. **对比内容** — 对比源站和 CDN 返回的内容 md5
4. **检查配置** — 确认 Cache-Control、TTL 等缓存策略
5. **清理验证** — 清缓存后等待生效，再次验证

## 注意事项

- 清缓存前确认源站内容已更新
- 页面中可能引用了多个 CDN 的资源，需要逐一排查
- CloudFront 失效通常需要 1-5 分钟生效
- 使用 `x-cache: Hit from cloudfront` 判断是否命中
