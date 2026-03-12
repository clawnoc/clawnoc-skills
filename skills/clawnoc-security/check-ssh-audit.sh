#!/bin/bash
# SSH 安全配置审计
# Usage: ./check-ssh-audit.sh
# Deps:  sshd
# Output: PASS/WARN for each SSH config item

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
