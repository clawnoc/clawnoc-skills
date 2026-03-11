#!/bin/bash
# 开放端口安全检查
# 用法: ./check-ports.sh

echo "=== Open Ports Security Check ==="
DANGEROUS_PORTS="3306 6379 27017 5432 9200 11211"
echo "--- Listening Ports ---"
ss -tlnp 2>/dev/null | grep LISTEN
echo ""
echo "--- Security Warnings ---"
for port in $DANGEROUS_PORTS; do
  if ss -tlnp 2>/dev/null | grep -q ":$port .*0.0.0.0"; then
    case $port in
      3306) svc="MySQL" ;; 6379) svc="Redis" ;; 27017) svc="MongoDB" ;;
      5432) svc="PostgreSQL" ;; 9200) svc="Elasticsearch" ;; 11211) svc="Memcached" ;;
    esac
    echo "⚠️  Port $port ($svc) is exposed to 0.0.0.0 — should bind to 127.0.0.1"
  fi
done
echo "✅ Port scan complete"
