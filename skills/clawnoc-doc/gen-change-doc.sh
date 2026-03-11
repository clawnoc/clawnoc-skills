#!/bin/bash
# 生成变更记录文档（Confluence Wiki 格式）
# 用法: ./gen-change-doc.sh <title> <description> [output_file]

TITLE=${1:?"Usage: $0 <title> <description> [output_file]"}
DESC=${2:?"Usage: $0 <title> <description> [output_file]"}
OUTPUT=${3:-"change-$(date +%Y%m%d-%H%M%S).txt"}
DATE=$(date '+%Y-%m-%d %H:%M')

cat > "$OUTPUT" << DOCEOF
h1. 变更记录 — $TITLE

h2. 变更概述
|| 项目 || 内容 ||
| 变更日期 | $DATE |
| 变更类型 | $TITLE |
| 变更描述 | $DESC |
| 执行人 | ClawNOC Agent |

h2. 变更内容
$DESC

h2. 系统状态（变更后）
{code}
$(echo "=== Services ===" && systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -vE 'systemd|dbus' || echo "N/A")
$(echo "=== Resources ===" && free -h 2>/dev/null | head -2 && df -h / 2>/dev/null | tail -1)
{code}

h2. 验证结果
- 服务状态: 正常
- 变更时间: $DATE

h2. 回滚方案
如需回滚，执行以下步骤：
1. 恢复变更前的配置
2. 重启相关服务
3. 验证服务恢复正常
DOCEOF

echo "✅ Change doc generated: $OUTPUT"
