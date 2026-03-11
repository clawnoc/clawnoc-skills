#!/bin/bash
# 部署后验证
# 用法: ./post-deploy-verify.sh <health_url> [duration_seconds]

URL=${1:?"Usage: $0 <health_url> [duration_seconds]"}
DURATION=${2:-60}
INTERVAL=5
CHECKS=$((DURATION / INTERVAL))
FAILURES=0

echo "=== Post-Deploy Verification ==="
echo "URL: $URL"
echo "Duration: ${DURATION}s (check every ${INTERVAL}s)"
echo ""

for i in $(seq 1 $CHECKS); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$URL")
  TIME=$(curl -s -o /dev/null -w '%{time_total}' --max-time 5 "$URL")
  if [ "$CODE" -ge 200 ] && [ "$CODE" -lt 400 ]; then
    echo "[$(date +%H:%M:%S)] ✅ HTTP $CODE — ${TIME}s"
  else
    echo "[$(date +%H:%M:%S)] ❌ HTTP $CODE — ${TIME}s"
    ((FAILURES++))
  fi
  [ "$i" -lt "$CHECKS" ] && sleep "$INTERVAL"
done

echo ""
echo "=== Summary ==="
echo "Total checks: $CHECKS"
echo "Failures: $FAILURES"
if [ "$FAILURES" -eq 0 ]; then
  echo "✅ Deploy verified — all checks passed"
else
  echo "⚠️ $FAILURES failures detected — consider rollback"
fi
