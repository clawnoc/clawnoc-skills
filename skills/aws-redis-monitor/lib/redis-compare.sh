#!/bin/bash
# redis-compare.sh - 上线前后指标对比
# 用法: redis-compare.sh <cluster-name> <minutes> [profile] [region]

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_config
check_deps

CLUSTER="${1:?用法: $0 <cluster-name> <minutes> [profile] [region]}"
MINUTES="${2:-30}"
PROFILE="${3:-$(get_default profile default)}"
REGION="${4:-$(get_default region ap-northeast-1)}"

check_aws_auth "$PROFILE"

NOW=$(date -u +%Y-%m-%dT%H:%M:%S)
DEPLOY_TIME=$(date -u -v-${MINUTES}M +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d "${MINUTES} minutes ago" +%Y-%m-%dT%H:%M:%S)
BEFORE_START=$(date -u -v-$((MINUTES * 2))M +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d "$((MINUTES * 2)) minutes ago" +%Y-%m-%dT%H:%M:%S)

PERIOD=$((MINUTES * 60))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Redis 上线对比: ${CLUSTER}"
echo "$(bj_now)"
echo "对比窗口: ${MINUTES} 分钟"
echo "上线前: $(TZ='Asia/Shanghai' date -j -f '%Y-%m-%dT%H:%M:%S' "$BEFORE_START" '+%H:%M' 2>/dev/null || echo $BEFORE_START) ~ $(TZ='Asia/Shanghai' date -j -f '%Y-%m-%dT%H:%M:%S' "$DEPLOY_TIME" '+%H:%M' 2>/dev/null || echo $DEPLOY_TIME)"
echo "上线后: $(TZ='Asia/Shanghai' date -j -f '%Y-%m-%dT%H:%M:%S' "$DEPLOY_TIME" '+%H:%M' 2>/dev/null || echo $DEPLOY_TIME) ~ 现在"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

METRICS=(
    "EngineCPUUtilization:Average:CPU使用率:%"
    "DatabaseMemoryUsagePercentage:Average:内存使用率:%"
    "CurrConnections:Average:连接数:"
    "CacheHitRate:Average:缓存命中率:%"
    "GetTypeCmds:Sum:GET操作数:"
    "SetTypeCmds:Sum:SET操作数:"
    "StringBasedCmdsLatency:Average:String命令延迟:us"
    "Evictions:Sum:淘汰Key数:"
    "NetworkBytesIn:Sum:网络入流量:bytes"
    "NetworkBytesOut:Sum:网络出流量:bytes"
)

printf ""
echo "| 指标 | 上线前 | 上线后 | 变化 | 状态 |"
echo "|---|---|---|---|---|"

for METRIC_DEF in "${METRICS[@]}"; do
    IFS=':' read -r METRIC_NAME STAT LABEL UNIT <<< "$METRIC_DEF"

    BEFORE_JSON=$(query_metric "$CLUSTER" "$METRIC_NAME" "$STAT" "$BEFORE_START" "$DEPLOY_TIME" "$PERIOD" "$PROFILE" "$REGION")
    AFTER_JSON=$(query_metric "$CLUSTER" "$METRIC_NAME" "$STAT" "$DEPLOY_TIME" "$NOW" "$PERIOD" "$PROFILE" "$REGION")

    python3 -c "
import json, sys

before = json.loads('$(echo "$BEFORE_JSON" | tr -d '\n')')
after = json.loads('$(echo "$AFTER_JSON" | tr -d '\n')')
stat = '$STAT'
label = '$LABEL'
unit = '$UNIT'

def get_val(data):
    dps = data.get('Datapoints', [])
    if not dps: return None
    vals = [dp[stat] for dp in dps]
    return sum(vals) / len(vals)

def fmt(v):
    if v is None: return 'N/A'
    if unit == 'bytes':
        if v > 1024**3: return f'{v/1024**3:.1f}GB'
        if v > 1024**2: return f'{v/1024**2:.1f}MB'
        if v > 1024: return f'{v/1024:.1f}KB'
        return f'{v:.0f}B'
    if v > 10000: return f'{v:,.0f}'
    if v > 100: return f'{v:.0f}'
    return f'{v:.1f}'

b = get_val(before)
a = get_val(after)

u = '' if unit == 'bytes' else unit

if b is None or a is None:
    change = 'N/A'
    status = '-'
elif b == 0:
    change = 'N/A'
    status = '-'
else:
    pct = (a - b) / b * 100
    change = f'{pct:+.1f}%'
    if abs(pct) > 100:
        status = '!!'
    elif abs(pct) > 50:
        status = '!'
    elif abs(pct) > 20:
        status = '~'
    else:
        status = 'OK'

b_str = f'{fmt(b)}{u}' if b is not None else 'N/A'
a_str = f'{fmt(a)}{u}' if a is not None else 'N/A'
print(f'| {label} | {b_str} | {a_str} | {change} | {status} |')
"
done

echo ""
echo "状态: OK <20% | ~ 20-50% | ! 50-100% | !! >100%"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
