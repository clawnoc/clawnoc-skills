#!/bin/bash
# common.sh - 通用函数库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.json"

# 加载配置
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "! 配置文件不存在: $CONFIG_FILE"
        echo "  请复制 config.json.example 为 config.json 并修改"
        exit 1
    fi
}

get_default() {
    jq -r ".defaults.$1 // \"$2\"" "$CONFIG_FILE"
}

get_threshold() {
    jq -r ".thresholds.$1 // $2" "$CONFIG_FILE"
}

get_group_clusters() {
    jq -r ".groups[\"$1\"][]? // empty" "$CONFIG_FILE"
}

get_all_clusters() {
    jq -r '.groups | to_entries[] | .value[]' "$CONFIG_FILE" | sort -u
}

# 依赖检查
check_deps() {
    for cmd in aws jq python3; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "! 缺少依赖: $cmd"
            exit 1
        fi
    done
}

# AWS 凭证检查
check_aws_auth() {
    local profile="$1"
    if ! aws sts get-caller-identity --profile "$profile" &> /dev/null 2>&1; then
        echo "! AWS 凭证无效或过期: profile=$profile"
        exit 1
    fi
}

# 查询 CloudWatch 指标
query_metric() {
    local cluster_id="$1"
    local metric_name="$2"
    local stat="$3"
    local start_time="$4"
    local end_time="$5"
    local period="$6"
    local profile="$7"
    local region="$8"

    aws cloudwatch get-metric-statistics \
        --namespace AWS/ElastiCache \
        --metric-name "$metric_name" \
        --dimensions Name=CacheClusterId,Value="$cluster_id" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --period "$period" \
        --statistics "$stat" \
        --profile "$profile" \
        --region "$region" \
        --output json 2>/dev/null
}

# 计算均值
calc_avg() {
    python3 -c "
import json, sys
data = json.load(sys.stdin)
dps = data.get('Datapoints', [])
if not dps:
    print('N/A')
else:
    stat = '$1'
    vals = [dp.get(stat, 0) for dp in dps]
    print(f'{sum(vals)/len(vals):.1f}')
"
}

# 计算最大值
calc_max() {
    python3 -c "
import json, sys
data = json.load(sys.stdin)
dps = data.get('Datapoints', [])
if not dps:
    print('N/A')
else:
    stat = '$1'
    vals = [dp.get(stat, 0) for dp in dps]
    print(f'{max(vals):.1f}')
"
}

# 北京时间显示
bj_now() {
    TZ='Asia/Shanghai' date "+%Y年%m月%d日 %H:%M:%S"
}

bj_date() {
    TZ='Asia/Shanghai' date "+%Y年%m月%d日 %A %H:%M" | sed 's/Monday/星期一/;s/Tuesday/星期二/;s/Wednesday/星期三/;s/Thursday/星期四/;s/Friday/星期五/;s/Saturday/星期六/;s/Sunday/星期日/'
}

# 异常判断标记
anomaly_marker() {
    local current="$1"
    local baseline="$2"
    local spike_ratio=$(get_threshold "spike_ratio" "1.5")
    local spike_crit=$(get_threshold "spike_crit_ratio" "2.0")
    local drop_ratio=$(get_threshold "drop_ratio" "0.5")
    local drop_crit=$(get_threshold "drop_crit_ratio" "0.3")

    python3 -c "
cur, base = $current, $baseline
if base == 0:
    print('')
elif cur > base * $spike_crit:
    print('[!!]')
elif cur > base * $spike_ratio:
    print('[!]')
elif cur < base * $drop_crit:
    print('[!!]')
elif cur < base * $drop_ratio:
    print('[!]')
else:
    print('')
"
}

# 百分比变化
pct_change() {
    python3 -c "
cur, base = $1, $2
if base == 0:
    print('N/A')
elif cur > base:
    print(f'+{((cur-base)/base*100):.0f}%')
else:
    print(f'{((cur-base)/base*100):.0f}%')
"
}
