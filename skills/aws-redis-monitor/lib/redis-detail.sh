#!/bin/bash
# redis-detail.sh - 单集群详细指标
# 用法: redis-detail.sh <cluster-name> [profile] [region] [hours]

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_config
check_deps

CLUSTER="${1:?用法: $0 <cluster-name> [profile] [region] [hours]}"
PROFILE="${2:-$(get_default profile default)}"
REGION="${3:-$(get_default region ap-northeast-1)}"
HOURS="${4:-3}"

check_aws_auth "$PROFILE"

END_TIME=$(date -u +%Y-%m-%dT%H:%M:%S)
START_TIME=$(date -u -v-${HOURS}H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d "${HOURS} hours ago" +%Y-%m-%dT%H:%M:%S)
PERIOD=3600

# 集群信息
NODE_TYPE=$(aws elasticache describe-cache-clusters --cache-cluster-id "$CLUSTER" --profile "$PROFILE" --region "$REGION" --query 'CacheClusters[0].CacheNodeType' --output text 2>/dev/null || echo "unknown")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Redis 详细报告: ${CLUSTER}"
echo "节点类型: ${NODE_TYPE}"
echo "$(bj_now)"
echo "时间范围: 最近 ${HOURS} 小时"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

METRICS=(
    "EngineCPUUtilization:Average:CPU使用率:%"
    "DatabaseMemoryUsagePercentage:Average:内存使用率:%"
    "CurrConnections:Average:连接数:"
    "CacheHitRate:Average:缓存命中率:%"
    "StringBasedCmdsLatency:Average:String命令延迟:us"
)

for METRIC_DEF in "${METRICS[@]}"; do
    IFS=':' read -r METRIC_NAME STAT LABEL UNIT <<< "$METRIC_DEF"

    DATA=$(query_metric "$CLUSTER" "$METRIC_NAME" "$STAT" "$START_TIME" "$END_TIME" "$PERIOD" "$PROFILE" "$REGION")

    echo "-- ${LABEL} (均值/最大/最小)"
    echo "$DATA" | python3 -c "
import json, sys
from datetime import datetime, timezone, timedelta

data = json.load(sys.stdin)
dps = data.get('Datapoints', [])
unit = '${UNIT}'
stat = '${STAT}'
label = '${LABEL}'

if not dps:
    print('(无数据)')
else:
    dps.sort(key=lambda x: x['Timestamp'])
    bjt = timezone(timedelta(hours=8))
    vals = [dp[stat] for dp in dps]
    avg = sum(vals) / len(vals)
    mx = max(vals)
    mn = min(vals)

    def fmt(v):
        if unit == 'bytes':
            if v > 1024**3: return f'{v/1024**3:.1f}GB'
            if v > 1024**2: return f'{v/1024**2:.1f}MB'
            if v > 1024: return f'{v/1024:.1f}KB'
            return f'{v:.0f}B'
        if v > 10000: return f'{v:,.0f}'
        if v > 100: return f'{v:.0f}'
        return f'{v:.1f}'

    u = '' if unit == 'bytes' else unit
    print(f'{fmt(avg)}{u} / {fmt(mx)}{u} / {fmt(mn)}{u}')
    print()
    print(f'| 时间 | {label} | 状态 |')
    print('|---|---|---|')
    for dp in dps:
        ts = datetime.fromisoformat(dp['Timestamp'].replace('Z', '+00:00')).astimezone(bjt)
        v = dp[stat]
        marker = ''
        if avg > 0:
            if v > avg * 2: marker = '!!'
            elif v > avg * 1.5: marker = '!'
            elif v < avg * 0.3: marker = '!!'
            elif v < avg * 0.5: marker = '!'
        print(f'| {ts.strftime(\"%m/%d %H:00\")} | {fmt(v)}{u} | {marker} |')
"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
