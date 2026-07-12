#!/usr/bin/env bash
# Reliable local access on Minikube (Docker Desktop / Mac).
# Opens:
#   UI         → http://localhost:8080
#   Auth       → http://localhost:4001
#   Analytics  → http://localhost:4002
#
# Keep this terminal running while you use the app.

set -euo pipefail

NS=api-pulse

echo "Forwarding services in namespace ${NS}..."
echo "  UI:        http://localhost:8080"
echo "  Auth:      http://localhost:4001"
echo "  Analytics: http://localhost:4002"
echo
echo "Press Ctrl+C to stop."

kubectl -n "$NS" port-forward svc/web 8080:80 &
PID_WEB=$!
kubectl -n "$NS" port-forward svc/auth-service 4001:80 &
PID_AUTH=$!
kubectl -n "$NS" port-forward svc/analytics-service 4002:80 &
PID_ANALYTICS=$!

cleanup() {
  kill "$PID_WEB" "$PID_AUTH" "$PID_ANALYTICS" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

wait
