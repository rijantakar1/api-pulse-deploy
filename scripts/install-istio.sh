#!/usr/bin/env bash
# Install Istio (demo profile) on the current Minikube/Kubernetes cluster.
# Docs: docs/ODIN.md
set -euo pipefail

ISTIO_VERSION="${ISTIO_VERSION:-1.24.2}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKDIR="${TMPDIR:-/tmp}/istio-install-$$"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

mkdir -p "$WORKDIR"
cd "$WORKDIR"

if ! command -v istioctl >/dev/null 2>&1; then
  echo "Downloading Istio ${ISTIO_VERSION}..."
  curl -sL "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-osx.tar.gz" \
    -o istio.tgz || \
  curl -sL "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-osx-arm64.tar.gz" \
    -o istio.tgz
  tar xzf istio.tgz
  ISTIOCTL="$(pwd)/istio-${ISTIO_VERSION}/bin/istioctl"
else
  ISTIOCTL=istioctl
fi

echo "Installing Istio (demo profile) with ${ISTIOCTL}..."
"$ISTIOCTL" install --set profile=demo -y

kubectl get ns api-pulse >/dev/null 2>&1 || kubectl create ns api-pulse
# Gateway-only demo: sidecars not required for VirtualService → Service routing.
# Uncomment to inject sidecars later:
# kubectl label namespace api-pulse istio-injection=enabled --overwrite

echo
echo "Istio installed. Ingress gateway:"
kubectl -n istio-system get svc istio-ingressgateway
echo
echo "Next:"
echo "  1. python3 ${ROOT}/scripts/render-istio-routing.py"
echo "  2. Apply Argo app: kubectl apply -f ${ROOT}/argocd/application-routing.yaml"
echo "  3. ${ROOT}/scripts/port-forward-istio.sh"
