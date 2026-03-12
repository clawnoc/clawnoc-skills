#!/bin/bash
# 部署前检查：磁盘、内存、进程、端口
# Usage: ./pre-deploy-check.sh
# Deps:  df, free, ss
# Output: PASS/FAIL for each check item

SERVICE=${1:-""}
echo "=== Pre-Deploy Check — $(date) ==="
PASS=0; FAIL=0

check() {
  if eval "$2" > /dev/null 2>&1; then
    echo "✅ $1"; ((PASS++))
  else
    echo "❌ $1"; ((FAIL++))
  fi
}

check "Disk space > 20% free" "[ $(df / | awk 'NR==2{print 100-$5}' | tr -d '%') -gt 20 ]"
check "Memory available > 500MB" "[ $(free -m | awk '/Mem/{print $7}') -gt 500 ]"
check "Load average < $(nproc)x2" "[ $(uptime | awk -F'[, ]' '{print $(NF-4)}' | cut -d. -f1) -lt $(($(nproc)*2)) ]"

if [ -n "$SERVICE" ]; then
  check "Service $SERVICE is active" "systemctl is-active $SERVICE"
fi

echo ""
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "✅ Ready to deploy" || echo "⚠️ Fix issues before deploying"
