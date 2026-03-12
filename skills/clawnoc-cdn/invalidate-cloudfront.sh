#!/bin/bash
# CloudFront 缓存失效
# Usage: ./invalidate-cloudfront.sh <distribution-id> <path>
# Deps:  aws-cli (configured)
# Output: Invalidation ID and status

DIST_ID=${1:?"Usage: $0 <distribution-id> [path]"}
PATH_PATTERN=${2:-"/*"}
echo "=== CloudFront Invalidation ==="
echo "Distribution: $DIST_ID"
echo "Path: $PATH_PATTERN"
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "$PATH_PATTERN"
echo ""
echo "Waiting for invalidation to complete..."
aws cloudfront wait invalidation-completed \
  --distribution-id "$DIST_ID" \
  --id "$(aws cloudfront list-invalidations --distribution-id "$DIST_ID" --query 'InvalidationList.Items[0].Id' --output text)"
echo "✅ Invalidation complete"
