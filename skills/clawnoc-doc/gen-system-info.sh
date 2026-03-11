#!/bin/bash
# 生成系统架构文档
# 用法: ./gen-system-info.sh [output_file]

OUTPUT=${1:-"system-info-$(date +%Y%m%d).txt"}

cat > "$OUTPUT" << DOCEOF
h1. 系统架构文档 — $(date +%Y-%m-%d)

h2. 操作系统
{code}
$(cat /etc/os-release 2>/dev/null | head -5 || sw_vers 2>/dev/null || echo "Unknown OS")
$(uname -a)
{code}

h2. 硬件资源
|| 资源 || 详情 ||
| CPU | $(nproc) cores |
| Memory | $(free -h 2>/dev/null | awk '/Mem/{print $2}' || echo "N/A") |
| Disk | $(df -h / | awk 'NR==2{print $2" total, "$3" used, "$4" free"}') |

h2. 运行中的服务
{code}
$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -vE 'systemd|dbus|cron' | head -20 || echo "systemctl not available")
{code}

h2. 监听端口
{code}
$(ss -tlnp 2>/dev/null | grep LISTEN || netstat -tlnp 2>/dev/null | grep LISTEN)
{code}

h2. 定时任务
{code}
$(crontab -l 2>/dev/null || echo "No crontab")
{code}

h2. 网络配置
{code}
$(ip addr show 2>/dev/null | grep 'inet ' || ifconfig 2>/dev/null | grep 'inet ')
{code}
DOCEOF

echo "✅ System info doc generated: $OUTPUT"
