#!/usr/bin/env bash
# Register deploy repo credentials (if private) and apply Argo CD Application.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARGO_NS=argocd
REPO_URL="https://github.com/cd-demo/api-pulse-deploy.git"

# Ensure api-pulse namespace + mysql init configmap exist (Helm chart expects init CM).
kubectl get ns api-pulse >/dev/null 2>&1 || kubectl create namespace api-pulse
kubectl -n api-pulse create configmap mysql-init-sql \
  --from-file=01-init.sql="$ROOT/db/init.sql" \
  --dry-run=client -o yaml | kubectl apply -f -

# Private GitHub repo: create a repo credential secret for Argo CD.
# Prefer a fine-scoped PAT (repo read) stored as GITHUB_TOKEN / ARGOCD_REPO_TOKEN.
if [[ -n "${ARGOCD_REPO_TOKEN:-}" ]]; then
  echo "Creating Argo CD repository secret for ${REPO_URL}"
  kubectl -n "$ARGO_NS" create secret generic repo-api-pulse-deploy \
    --from-literal=type=git \
    --from-literal=url="$REPO_URL" \
    --from-literal=password="$ARGOCD_REPO_TOKEN" \
    --from-literal=username="${ARGOCD_REPO_USERNAME:-git}" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n "$ARGO_NS" label secret repo-api-pulse-deploy \
    argocd.argoproj.io/secret-type=repository --overwrite
fi

# Optional: private Docker Hub pulls for app images
if [[ "${IMAGE_PULL_SECRET:-}" == "1" ]]; then
  : "${DOCKERHUB_USERNAME:?set DOCKERHUB_USERNAME}"
  : "${DOCKERHUB_TOKEN:?set DOCKERHUB_TOKEN}"
  kubectl -n api-pulse create secret docker-registry dockerhub-cred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username="$DOCKERHUB_USERNAME" \
    --docker-password="$DOCKERHUB_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -
  # Enable pull secret in values via a one-time helm set is handled by editing values
  # or re-running with imagePullSecrets.enabled — Application uses values.yaml in git.
  echo "Created dockerhub-cred. Set imagePullSecrets.enabled=true in values.yaml if images are private."
fi

kubectl apply -f "$ROOT/argocd/project.yaml"
kubectl apply -f "$ROOT/argocd/application.yaml"

echo
echo "Application applied. Watch sync:"
echo "  kubectl -n argocd get application api-pulse -w"
echo
echo "Or UI: kubectl -n argocd port-forward svc/argocd-server 8081:443"
echo
if command -v argocd >/dev/null 2>&1; then
  echo "Optional CLI sync:"
  echo "  argocd login localhost:8081 --insecure"
  echo "  argocd app sync api-pulse"
fi
