#!/bin/bash
# 通用 Webhook 告警推送（支持飞书/钉钉/Slack）
# 用法: ./alert-webhook.sh <webhook_url> <message>

WEBHOOK=${1:?"Usage: $0 <webhook_url> <message>"}
MESSAGE=${2:?"Usage: $0 <webhook_url> <message>"}

# 自动识别平台
if echo "$WEBHOOK" | grep -q "feishu"; then
  PAYLOAD="{\"msg_type\":\"text\",\"content\":{\"text\":\"$MESSAGE\"}}"
elif echo "$WEBHOOK" | grep -q "dingtalk"; then
  PAYLOAD="{\"msgtype\":\"text\",\"text\":{\"content\":\"$MESSAGE\"}}"
elif echo "$WEBHOOK" | grep -q "slack"; then
  PAYLOAD="{\"text\":\"$MESSAGE\"}"
else
  PAYLOAD="{\"text\":\"$MESSAGE\"}"
fi

RESULT=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$WEBHOOK" \
  -H 'Content-Type: application/json' -d "$PAYLOAD")
if [ "$RESULT" = "200" ]; then
  echo "✅ Alert sent"
else
  echo "❌ Alert failed (HTTP $RESULT)"
fi
