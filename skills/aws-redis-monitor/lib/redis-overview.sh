#!/bin/bash
# redis-overview.sh - Redis 全局巡检（批量查询优化版）
# 用法: redis-overview.sh [profile] [region] [hours]

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_config
check_deps

PROFILE="${1:-$(get_default profile default)}"
REGION="${2:-$(get_default region ap-northeast-1)}"
HOURS="${3:-24}"

check_aws_auth "$PROFILE"

END_TIME=$(date -u +%Y-%m-%dT%H:%M:%S)
START_TIME=$(date -u -v-${HOURS}H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d "${HOURS} hours ago" +%Y-%m-%dT%H:%M:%S)
BASELINE_END=$(date -u -v-7d +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d "7 days ago" +%Y-%m-%dT%H:%M:%S)
BASELINE_START=$(date -u -v-7d -v-${HOURS}H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d "$((7*24+HOURS)) hours ago" +%Y-%m-%dT%H:%M:%S)

PERIOD=$((HOURS * 3600))

echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Redis 每日巡检报告"
echo "$(bj_date)"
echo "最近 ${HOURS} 小时"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CLUSTERS=$(get_all_clusters)
WORKDIR=$(mktemp -d)
trap "rm -rf $WORKDIR" EXIT

# 用 python3 生成查询 JSON、执行查询、分析结果 - 一次性完成
CLUSTER_LIST="$WORKDIR/clusters.txt"
echo "$CLUSTERS" > "$CLUSTER_LIST"

python3 << PYEOF
import json, subprocess, sys, os

workdir = "$WORKDIR"
profile = "$PROFILE"
region = "$REGION"
period = $PERIOD
hours = $HOURS
start_time = "$START_TIME"
end_time = "$END_TIME"
baseline_start = "$BASELINE_START"
baseline_end = "$BASELINE_END"
cpu_warn = $(get_threshold cpu_warn 70)
mem_warn = $(get_threshold memory_warn 80)
spike = $(get_threshold spike_ratio 1.5)
spike_crit = $(get_threshold spike_crit_ratio 2.0)
drop_ratio = $(get_threshold drop_ratio 0.5)

with open(f"{workdir}/clusters.txt") as f:
    clusters = [c.strip() for c in f if c.strip()]

def safe(c):
    return c.replace('-', '_').lower()

def build_queries(clusters, metrics, prefix=""):
    queries = []
    for c in clusters:
        s = safe(c)
        for name, metric, stat in metrics:
            queries.append({
                "Id": f"{prefix}{name}_{s}"[:255],
                "MetricStat": {
                    "Metric": {
                        "Namespace": "AWS/ElastiCache",
                        "MetricName": metric,
                        "Dimensions": [{"Name": "CacheClusterId", "Value": c}]
                    },
                    "Period": period,
                    "Stat": stat
                }
            })
    return queries

def run_query(queries, start, end):
    results = {}
    # 分批 500
    for i in range(0, len(queries), 500):
        batch = queries[i:i+500]
        qfile = f"{workdir}/q_{i}.json"
        with open(qfile, 'w') as f:
            json.dump(batch, f)
        cmd = [
            "aws", "cloudwatch", "get-metric-data",
            "--metric-data-queries", f"file://{qfile}",
            "--start-time", start,
            "--end-time", end,
            "--profile", profile,
            "--region", region,
            "--output", "json"
        ]
        out = subprocess.run(cmd, capture_output=True, text=True)
        if out.returncode == 0:
            j = json.loads(out.stdout)
            for r in j.get("MetricDataResults", []):
                vals = r.get("Values", [])
                if vals:
                    results[r["Id"]] = sum(vals) / len(vals)
    return results

current_metrics = [
    ("cpu", "EngineCPUUtilization", "Average"),
    ("mem", "DatabaseMemoryUsagePercentage", "Average"),
    ("conn", "CurrConnections", "Average"),
    ("hit", "CacheHitRate", "Average"),
    ("evict", "Evictions", "Sum"),
]

baseline_metrics = [
    ("cpub", "EngineCPUUtilization", "Average"),
    ("connb", "CurrConnections", "Average"),
    ("hitb", "CacheHitRate", "Average"),
]

current = run_query(build_queries(clusters, current_metrics), start_time, end_time)
baseline = run_query(build_queries(clusters, baseline_metrics), baseline_start, baseline_end)

# 分析
anomalies = []
cpu_top, mem_top, conn_top = [], [], []

def short_name(c):
    return c

def chg(cur, base):
    if base and base > 0:
        pct = (cur - base) / base * 100
        return f"{pct:+.0f}%"
    return ""

for c in clusters:
    s = safe(c)
    cpu = current.get(f"cpu_{s}")
    mem = current.get(f"mem_{s}")
    conn = current.get(f"conn_{s}")
    hit = current.get(f"hit_{s}")
    evict = current.get(f"evict_{s}")
    cpu_b = baseline.get(f"cpub_{s}")
    conn_b = baseline.get(f"connb_{s}")
    hit_b = baseline.get(f"hitb_{s}")

    if cpu is None and mem is None:
        continue

    if cpu is not None: cpu_top.append((cpu, c))
    if mem is not None: mem_top.append((mem, c))
    if conn is not None: conn_top.append((conn, c))

    issues = []

    if cpu is not None:
        if cpu > cpu_warn:
            extra = f", 基线{cpu_b:.1f}%, {chg(cpu, cpu_b)}" if cpu_b else ""
            issues.append(f"    CPU: {cpu:.1f}% (阈值{cpu_warn}%{extra})")
        elif cpu_b and cpu_b > 0:
            if cpu > cpu_b * spike:
                m = "[!!]" if cpu > cpu_b * spike_crit else "[!]"
                issues.append(f"    CPU: {cpu:.1f}% (基线{cpu_b:.1f}%, {chg(cpu, cpu_b)}) {m}")
            elif cpu < cpu_b * drop_ratio:
                issues.append(f"    CPU: {cpu:.1f}% (基线{cpu_b:.1f}%, {chg(cpu, cpu_b)}) [!]")

    if mem is not None and mem > mem_warn:
        issues.append(f"    内存: {mem:.1f}% (阈值{mem_warn}%)")

    if conn is not None and conn_b and conn_b > 0:
        if conn > conn_b * spike:
            m = "[!!]" if conn > conn_b * spike_crit else "[!]"
            issues.append(f"    连接数: {conn:.0f} (基线{conn_b:.0f}, {chg(conn, conn_b)}) {m}")
        elif conn < conn_b * drop_ratio:
            issues.append(f"    连接数: {conn:.0f} (基线{conn_b:.0f}, {chg(conn, conn_b)}) [!]")

    if hit is not None and hit_b is not None and hit_b - hit > 10:
        issues.append(f"    命中率: {hit:.1f}% (基线{hit_b:.1f}%, 下降{hit_b-hit:.1f}pp)")

    if evict is not None and evict > 0:
        issues.append(f"    Evictions: {evict:.0f} (过去{hours}h)")

    if issues:
        anomalies.append((c, issues))

total = max(len(cpu_top), len(mem_top))

if anomalies:
    print(f"! 异常集群: {len(anomalies)}/{total}")
    print()
    print(f"  {'集群':<30s} {'异常项'}")
    for c, issues in anomalies:
        detail = "; ".join(i.strip() for i in issues)
        print(f"  {c:<30s} {detail}")
    print()
else:
    print(f"[OK] 全部 {total} 个集群正常")
    print()

print("-- TOP 5 CPU")
print(f"  {'集群':<30s} {'CPU':>8s}")
for v, c in sorted(cpu_top, reverse=True)[:5]:
    print(f"  {short_name(c):<30s} {v:>7.1f}%")

print()
print("-- TOP 5 内存")
print(f"  {'集群':<30s} {'内存':>8s}")
for v, c in sorted(mem_top, reverse=True)[:5]:
    print(f"  {short_name(c):<30s} {v:>7.1f}%")

print()
print("-- TOP 5 连接数")
print(f"  {'集群':<30s} {'连接数':>8s}")
for v, c in sorted(conn_top, reverse=True)[:5]:
    print(f"  {short_name(c):<30s} {v:>8,.0f}")

print()
print("━━━━━━━━━━━━━━━━━━━━━━━━")
PYEOF
