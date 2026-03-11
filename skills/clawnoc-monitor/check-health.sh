#!/bin/bash
# HTTP 健康检查
# 用法: ./check-health.sh url1 url2 ...

URLS=${@:?"Usage: $0 url1 url2 ..."}
echo "=== HTTP Health Check ==="
for url in $URLS; do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$url")
  TIME=$(curl -s -o /dev/null -w '%{time_total}' --max-time 10 "$url")
  if [ "$CODE" -ge 200 ] && [ "$CODE" -lt 400 ]; then
    echo "✅ $url — HTTP $CODE — ${TIME}s"
  else
    echo "❌ $url — HTTP $CODE — ${TIME}s"
  fi
done
