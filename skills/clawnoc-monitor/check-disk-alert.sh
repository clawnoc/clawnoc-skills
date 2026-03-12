#!/bin/bash
# 磁盘使用率告警
# Usage: ./check-disk-alert.sh [threshold] [webhook_url]
# Deps:  df, curl (for webhook)
# Output: Alert if any partition exceeds threshold

THRESHOLD=${1:-85}
WEBHOOK=${2:-""}
ALERTS=""

while read -r line; do
  USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
  MOUNT=$(echo "$line" | awk '{print $6}')
  if [ "$USAGE" -gt "$THRESHOLD" ]; then
    ALERTS="${ALERTS}⚠️ ${MOUNT}: ${USAGE}% (threshold: ${THRESHOLD}%)\n"
  fi
done < <(df -h | grep -vE 'tmpfs|devtmpfs|Filesystem')

if [ -n "$ALERTS" ]; then
  echo -e "=== Disk Alert ===\n$ALERTS"
  if [ -n "$WEBHOOK" ]; then
    curl -s -X POST "$WEBHOOK" \
      -H 'Content-Type: application/json' \
      -d "{\"msg_type\":\"text\",\"content\":{\"text\":\"[ClawNOC] Disk Alert\n$(echo -e "$ALERTS")\"}}"
  fi
else
  echo "✅ All disks below ${THRESHOLD}%"
fi
