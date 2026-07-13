#!/usr/bin/env bash
# Port-forward Istio ingress gateway for header-based tenant routing.
#
#   UI + APIs → http://localhost:8080
#   Auth path → http://localhost:8080/auth/...
#   Analytics → http://localhost:8080/analytics/...
#
# Set web ConfigMap authUrl/analyticsUrl to http://localhost:8080/auth and
# http://localhost:8080/analytics (see values-istio.yaml / docs/ODIN.md).

set -euo pipefail

echo "Forwarding istio-ingressgateway → http://localhost:8080"
echo "Send X-Tenant-Slug on requests to pin versions (see routing/tenants.yaml)."
echo "Press Ctrl+C to stop."

kubectl -n istio-system port-forward svc/istio-ingressgateway 8080:80
