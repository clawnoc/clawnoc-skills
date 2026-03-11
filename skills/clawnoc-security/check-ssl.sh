#!/bin/bash
# SSL 证书批量检查
# 用法: ./check-ssl.sh domain1 domain2 ...

DOMAINS=${@:?"Usage: $0 domain1 domain2 ..."}
WARN_DAYS=30
echo "=== SSL Certificate Check ==="
for domain in $DOMAINS; do
  EXPIRY=$(echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | \
    openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
  if [ -z "$EXPIRY" ]; then
    echo "❌ $domain — connection failed"
    continue
  fi
  EXPIRY_TS=$(date -d "$EXPIRY" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$EXPIRY" +%s 2>/dev/null)
  NOW_TS=$(date +%s)
  DAYS_LEFT=$(( (EXPIRY_TS - NOW_TS) / 86400 ))
  if [ "$DAYS_LEFT" -lt "$WARN_DAYS" ]; then
    echo "⚠️  $domain — ${DAYS_LEFT} days left — expires $EXPIRY"
  else
    echo "✅ $domain — ${DAYS_LEFT} days left"
  fi
done
