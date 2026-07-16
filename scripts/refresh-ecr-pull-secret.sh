#!/usr/bin/env bash
# Create/refresh Kubernetes docker-registry secret for private ECR pulls.
# ECR tokens expire ~12h — re-run before demos or via cron.
#
# Usage:
#   export AWS_REGION=us-west-2
#   export AWS_ACCOUNT_ID=123456789012
#   ./scripts/refresh-ecr-pull-secret.sh [namespace ...]
#
# Defaults namespaces: api-pulse odin
set -euo pipefail

: "${AWS_REGION:?set AWS_REGION}"
: "${AWS_ACCOUNT_ID:?set AWS_ACCOUNT_ID}"

REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
SECRET_NAME="${ECR_PULL_SECRET_NAME:-ecr-pull}"
NAMESPACES=("${@:-api-pulse odin}")

# Expand default if single string with spaces was passed oddly
if [[ $# -eq 0 ]]; then
  NAMESPACES=(api-pulse odin)
fi

PASSWORD="$(aws ecr get-login-password --region "$AWS_REGION")"

for NS in "${NAMESPACES[@]}"; do
  kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"
  kubectl -n "$NS" create secret docker-registry "$SECRET_NAME" \
    --docker-server="$REGISTRY" \
    --docker-username=AWS \
    --docker-password="$PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "Refreshed ${NS}/${SECRET_NAME} for ${REGISTRY}"
done
