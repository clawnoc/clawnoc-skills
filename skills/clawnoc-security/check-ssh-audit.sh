#!/bin/bash
# SSH 登录审计
# 用法: ./check-ssh-audit.sh [lines]

LINES=${1:-20}
echo "=== SSH Login Audit ==="
echo "--- Failed Attempts (Top 10 IPs) ---"
grep 'Failed password' /var/log/secure 2>/dev/null | \
  awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -10 || \
  grep 'Failed password' /var/log/auth.log 2>/dev/null | \
  awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -10 || \
  echo "No failed login records found"
echo ""
echo "--- Recent Successful Logins ---"
last -n "$LINES" 2>/dev/null | head -"$LINES"
