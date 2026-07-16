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
#
# Token must be able to READ this repo (clone / list refs). Prefer:
#   - Classic PAT with `repo` scope, OR
#   - Fine-grained PAT: Resource owner = cd-demo (or your user if personal),
#     Repository access = Only select → api-pulse-deploy,
#     Permissions → Contents: Read-only (Metadata is not enough)
#
# Username should be your GitHub username (e.g. rijantakar1), NOT "git",
# when using a fine-grained PAT.
#
#   export ARGOCD_REPO_TOKEN='ghp_...'   # or github_pat_...
#   export ARGOCD_REPO_USERNAME='rijantakar1'
#   ./scripts/bootstrap-argocd-app.sh
#
if [[ -n "${ARGOCD_REPO_TOKEN:-}" ]]; then
  : "${ARGOCD_REPO_USERNAME:?Set ARGOCD_REPO_USERNAME to your GitHub username (e.g. rijantakar1)}"
  echo "Creating Argo CD repository secret for ${REPO_URL} (user=${ARGOCD_REPO_USERNAME})"
  kubectl -n "$ARGO_NS" delete secret repo-api-pulse-deploy --ignore-not-found
  kubectl -n "$ARGO_NS" create secret generic repo-api-pulse-deploy \
    --from-literal=type=git \
    --from-literal=url="$REPO_URL" \
    --from-literal=password="$ARGOCD_REPO_TOKEN" \
    --from-literal=username="$ARGOCD_REPO_USERNAME"
  kubectl -n "$ARGO_NS" label secret repo-api-pulse-deploy \
    argocd.argoproj.io/secret-type=repository --overwrite
  # Soft-refresh the app so it picks up the new creds
  kubectl -n "$ARGO_NS" annotate application api-pulse \
    argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null || true
else
  echo "WARN: ARGOCD_REPO_TOKEN not set — Argo cannot clone private api-pulse-deploy."
  echo "      export ARGOCD_REPO_TOKEN=... ARGOCD_REPO_USERNAME=rijantakar1 and re-run."
fi

# Optional: ECR pull secret for private app images (tokens expire ~12h).
#   export AWS_REGION=us-west-2 AWS_ACCOUNT_ID=123456789012
#   ECR_PULL_SECRET=1 ./scripts/bootstrap-argocd-app.sh
if [[ "${ECR_PULL_SECRET:-}" == "1" ]]; then
  "$ROOT/scripts/refresh-ecr-pull-secret.sh" api-pulse odin
fi

kubectl apply -f "$ROOT/argocd/project.yaml"
kubectl apply -f "$ROOT/argocd/application.yaml"
kubectl apply -f "$ROOT/argocd/application-routing.yaml"
# Optional Odin TMS app (charts/odin) — apply when values/images exist
if [[ -f "$ROOT/argocd/application-odin.yaml" ]]; then
  kubectl apply -f "$ROOT/argocd/application-odin.yaml"
fi

echo
echo "Applications applied. Watch sync:"
echo "  kubectl -n argocd get application api-pulse api-pulse-routing -w"
echo
echo "Or UI: kubectl -n argocd port-forward svc/argocd-server 8081:443"
echo
if command -v argocd >/dev/null 2>&1; then
  echo "Optional CLI sync:"
  echo "  argocd login localhost:8081 --insecure"
  echo "  argocd app sync api-pulse"
fi
