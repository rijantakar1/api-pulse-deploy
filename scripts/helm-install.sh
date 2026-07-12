#!/usr/bin/env bash
# Install / upgrade API Pulse from Docker Hub images via Helm.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NS="${NAMESPACE:-api-pulse}"
RELEASE="${RELEASE:-api-pulse}"
TAG="${IMAGE_TAG:-latest}"

# Optional private Hub pull:
#   export DOCKERHUB_USERNAME=rajashekhar2390
#   export DOCKERHUB_TOKEN=...
#   export IMAGE_PULL_SECRET=1

EXTRA_ARGS=()
if [[ "${IMAGE_PULL_SECRET:-}" == "1" ]]; then
  : "${DOCKERHUB_USERNAME:?set DOCKERHUB_USERNAME}"
  : "${DOCKERHUB_TOKEN:?set DOCKERHUB_TOKEN}"
  EXTRA_ARGS+=(
    --set imagePullSecrets.enabled=true
    --set dockerHub.username="$DOCKERHUB_USERNAME"
    --set dockerHub.password="$DOCKERHUB_TOKEN"
  )
fi

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# MySQL seed ConfigMap (same as plain manifests path)
kubectl -n "$NS" create configmap mysql-init-sql \
  --from-file=01-init.sql="$ROOT/db/init.sql" \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install "$RELEASE" "$ROOT/charts/api-pulse" \
  --namespace "$NS" \
  --set images.web.tag="$TAG" \
  --set images.auth.tag="$TAG" \
  --set images.analytics.tag="$TAG" \
  --set imagePullPolicy=Always \
  "${EXTRA_ARGS[@]}" \
  "$@"

echo
echo "Deployed ${RELEASE} in ${NS} using Docker Hub tag: ${TAG}"
echo "  rajashekhar2390/api-pulse-web:${TAG}"
echo "  rajashekhar2390/api-pulse-auth-service:${TAG}"
echo "  rajashekhar2390/api-pulse-analytics-service:${TAG}"
echo
echo "Port-forward:  ${ROOT}/scripts/port-forward.sh"
