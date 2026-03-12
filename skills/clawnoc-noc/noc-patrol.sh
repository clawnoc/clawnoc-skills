#!/bin/bash
# 全量巡检：系统+磁盘+SSL+端口+健康检查
# Usage: ./noc-patrol.sh
# Deps:  All above scripts
# Output: Full patrol report

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HEALTH_URL=${1:-""}

echo "🦞 ClawNOC Full Patrol — $(date)"
echo "========================================"

echo ""
echo "📊 [1/4] System Resources"
echo "----------------------------------------"
bash "$SCRIPT_DIR/../clawnoc-monitor/check-system.sh" 2>/dev/null || {
  echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
  free -h | head -2
  df -h | grep -vE 'tmpfs|devtmpfs|Filesystem'
}

echo ""
echo "🔒 [2/4] Security Check"
echo "----------------------------------------"
bash "$SCRIPT_DIR/../clawnoc-security/check-ports.sh" 2>/dev/null || {
  echo "Open ports:"
  ss -tlnp 2>/dev/null | grep LISTEN
}

echo ""
echo "🌐 [3/4] SSL Certificates"
echo "----------------------------------------"
if [ -n "$HEALTH_URL" ]; then
  DOMAIN=$(echo "$HEALTH_URL" | awk -F/ '{print $3}')
  bash "$SCRIPT_DIR/../clawnoc-security/check-ssl.sh" "$DOMAIN" 2>/dev/null || {
    echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | \
      openssl x509 -noout -dates -subject 2>/dev/null || echo "N/A"
  }
else
  echo "Skip (no URL provided)"
fi

echo ""
echo "🚀 [4/4] Health Check"
echo "----------------------------------------"
if [ -n "$HEALTH_URL" ]; then
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$HEALTH_URL")
  TIME=$(curl -s -o /dev/null -w '%{time_total}' --max-time 10 "$HEALTH_URL")
  if [ "$CODE" -ge 200 ] && [ "$CODE" -lt 400 ]; then
    echo "✅ $HEALTH_URL — HTTP $CODE — ${TIME}s"
  else
    echo "❌ $HEALTH_URL — HTTP $CODE — ${TIME}s"
  fi
else
  echo "Skip (no URL provided)"
fi

echo ""
echo "========================================"
echo "🦞 Patrol complete — $(date)"
