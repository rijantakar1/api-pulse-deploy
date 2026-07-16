#!/usr/bin/env bash
# Write AWS account ID into Helm values (api-pulse + odin).
# Usage: ./scripts/set-ecr-account.sh <12-digit-account-id> [region]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ACCOUNT="${1:?usage: $0 <aws-account-id> [region]}"
REGION="${2:-us-west-2}"

export AWS_ACCOUNT_ID="$ACCOUNT"
export AWS_REGION="$REGION"

python3 "$ROOT/scripts/ensure_ecr_registry.py" \
  "$ROOT/charts/api-pulse/values.yaml" --chart api-pulse
python3 "$ROOT/scripts/ensure_ecr_registry.py" \
  "$ROOT/charts/odin/values.yaml" --chart odin

echo
echo "Next:"
echo "  1. Commit charts/*/values.yaml if you want Argo to use this registry immediately"
echo "  2. ./scripts/refresh-ecr-pull-secret.sh   # needs AWS creds in env"
echo "  3. Re-run app CI (or wait for next push) to populate ECR tags"
