"""
Redis Big Key Scanner — AWS Lambda

Scans ElastiCache Redis clusters for oversized keys.
Supports: String, Hash, List, Set, ZSet, Stream.
Auto-discovers cluster endpoints via ElastiCache API.
Must run inside VPC to access ElastiCache.
"""
import json
import os

import boto3
import redis

import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "shared"))
import notifier

SIZE_THRESHOLD = int(os.environ.get("SIZE_THRESHOLD", str(10 * 1024)))  # 10KB
COUNT_THRESHOLD = int(os.environ.get("COUNT_THRESHOLD", "10000"))
SCAN_COUNT = int(os.environ.get("SCAN_COUNT", "1000"))
CLUSTER_ID = os.environ.get("CLUSTER_ID", "")  # optional, auto-discover if empty


def discover_endpoints():
    client = boto3.client("elasticache")
    endpoints = []
    if CLUSTER_ID:
        resp = client.describe_cache_clusters(CacheClusterId=CLUSTER_ID, ShowCacheNodeInfo=True)
        clusters = resp["CacheClusters"]
    else:
        clusters = client.describe_cache_clusters(ShowCacheNodeInfo=True)["CacheClusters"]
    for c in clusters:
        if c.get("Engine") != "redis":
            continue
        for node in c.get("CacheNodes", []):
            ep = node.get("Endpoint")
            if ep:
                endpoints.append((f"{c['CacheClusterId']}", ep["Address"], ep["Port"]))
    return endpoints


def scan_cluster(host, port):
    r = redis.Redis(host=host, port=port, socket_timeout=10, decode_responses=True)
    big_keys = []
    cursor = 0
    scanned = 0
    while True:
        cursor, keys = r.scan(cursor=cursor, count=SCAN_COUNT)
        scanned += len(keys)
        pipe = r.pipeline(transaction=False)
        for k in keys:
            pipe.type(k)
            pipe.memory_usage(k)
        results = pipe.execute()
        for i, k in enumerate(keys):
            ktype = results[i * 2]
            mem = results[i * 2 + 1] or 0
            is_big = mem > SIZE_THRESHOLD
            if not is_big and ktype in ("hash", "list", "set", "zset", "stream"):
                length = {"hash": r.hlen, "list": r.llen, "set": r.scard,
                          "zset": r.zcard, "stream": r.xlen}.get(ktype, lambda k: 0)(k)
                is_big = length > COUNT_THRESHOLD
            if is_big:
                big_keys.append({"key": k[:80], "type": ktype, "memory_bytes": mem})
        if cursor == 0:
            break
    return big_keys, scanned


def lambda_handler(event, context):
    endpoints = discover_endpoints()
    all_findings = []
    for cid, host, port in endpoints:
        try:
            big_keys, scanned = scan_cluster(host, port)
            for bk in big_keys:
                bk["cluster"] = cid
            all_findings.extend(big_keys)
        except Exception as e:
            all_findings.append({"cluster": cid, "error": str(e)})

    if all_findings:
        lines = []
        for f in all_findings[:20]:
            if "error" in f:
                lines.append(f"❌ {f['cluster']}: {f['error']}")
            else:
                mem_kb = f['memory_bytes'] / 1024
                lines.append(f"🔑 {f['cluster']} | `{f['key']}` | {f['type']} | {mem_kb:.1f}KB")
        notifier.send(f"🔴 Redis Big Keys: {len(all_findings)} found", "\n".join(lines))

    return {"statusCode": 200, "body": json.dumps({"big_keys": len(all_findings)})}
