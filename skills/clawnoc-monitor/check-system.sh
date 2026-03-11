#!/bin/bash
# 系统资源综合检查
# 用法: ./check-system.sh

echo "=== System Resource Check — $(date) ==="
echo ""
echo "--- CPU ---"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "Cores: $(nproc)"
echo ""
echo "--- Memory ---"
free -h | head -2
echo ""
echo "--- Disk ---"
df -h | grep -vE 'tmpfs|devtmpfs|overlay'
echo ""
echo "--- Top CPU Processes ---"
ps aux --sort=-%cpu | head -6
echo ""
echo "--- Top Memory Processes ---"
ps aux --sort=-%mem | head -6
