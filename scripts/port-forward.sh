#!/usr/bin/env bash
# Port-forward versioned Services (direct, no Istio).
# Defaults to tag "latest". Override: WEB_TAG=... AUTH_TAG=... ANALYTICS_TAG=...
#
#   UI         → http://localhost:8080
#   Auth       → http://localhost:4001
#   Analytics  → http://localhost:4002

set -euo pipefail

NS=api-pulse
WEB_TAG="${WEB_TAG:-latest}"
AUTH_TAG="${AUTH_TAG:-latest}"
ANALYTICS_TAG="${ANALYTICS_TAG:-latest}"

WEB_SVC="api-pulse-web-${WEB_TAG}"
AUTH_SVC="api-pulse-auth-${AUTH_TAG}"
ANALYTICS_SVC="api-pulse-analytics-${ANALYTICS_TAG}"

echo "Forwarding versioned services in namespace ${NS}..."
echo "  UI:        http://localhost:8080  (${WEB_SVC})"
echo "  Auth:      http://localhost:4001  (${AUTH_SVC})"
echo "  Analytics: http://localhost:4002  (${ANALYTICS_SVC})"
echo
echo "For Istio + X-Tenant-Slug routing, use scripts/port-forward-istio.sh"
echo "Press Ctrl+C to stop."

kubectl -n "$NS" port-forward "svc/${WEB_SVC}" 8080:80 &
PID_WEB=$!
kubectl -n "$NS" port-forward "svc/${AUTH_SVC}" 4001:80 &
PID_AUTH=$!
kubectl -n "$NS" port-forward "svc/${ANALYTICS_SVC}" 4002:80 &
PID_ANALYTICS=$!

cleanup() {
  kill "$PID_WEB" "$PID_AUTH" "$PID_ANALYTICS" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

wait
