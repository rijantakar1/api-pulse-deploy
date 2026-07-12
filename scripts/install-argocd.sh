#!/usr/bin/env bash
# Install Argo CD into the current kube-context (Minikube).
set -euo pipefail

ARGO_NS=argocd
# Pin a known release for reproducibility
ARGO_VERSION="${ARGO_VERSION:-v2.14.9}"

echo "Installing Argo CD ${ARGO_VERSION} into namespace ${ARGO_NS}..."
kubectl create namespace "$ARGO_NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n "$ARGO_NS" -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGO_VERSION}/manifests/install.yaml"

echo "Waiting for argocd-server..."
kubectl -n "$ARGO_NS" rollout status deploy/argocd-server --timeout=300s

echo
echo "Initial admin password:"
kubectl -n "$ARGO_NS" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
echo
echo "UI (HTTPS):"
echo "  kubectl -n argocd port-forward svc/argocd-server 8081:443"
echo "  open https://localhost:8081  (user: admin)"
echo
echo "Next: ./scripts/bootstrap-argocd-app.sh"
