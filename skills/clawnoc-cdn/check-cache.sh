#!/bin/bash
# CDN 缓存状态检查
# Usage: ./check-cache.sh <url>
# Deps:  curl
# Output: HTTP status, cache headers (X-Cache, Age, Cache-Control)

URL=${1:?"Usage: $0 <url>"}
echo "=== CDN Cache Check: $URL ==="
echo "--- Response Headers ---"
curl -sI "$URL" | grep -iE 'cache|age|x-cache|cf-cache|etag|last-modified|expires'
echo ""
echo "--- Content Hash ---"
echo "MD5: $(curl -s "$URL" | md5sum | awk '{print $1}')"
echo ""
echo "--- DNS Resolution ---"
dig +short "$(echo "$URL" | awk -F/ '{print $3}')" 2>/dev/null || nslookup "$(echo "$URL" | awk -F/ '{print $3}')"
