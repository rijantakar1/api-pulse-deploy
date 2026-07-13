#!/usr/bin/env bash
# Demo: render routing, show curl examples for X-Tenant-Slug pinning.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Render Istio manifests from routing/tenants.yaml"
python3 scripts/render-istio-routing.py

echo
echo "==> Current global + tenant pins"
python3 - <<'PY'
import yaml
from pathlib import Path
spec = yaml.safe_load(Path("routing/tenants.yaml").read_text())["spec"]
print("global:", spec["global"])
for slug, pins in (spec.get("tenants") or {}).items():
    print(f"  {slug}: {pins or '(inherit all)'}")
PY

echo
echo "==> Example curls (Istio gateway on :8080)"
echo "  # Global web"
echo "  curl -sI http://localhost:8080/ | head -5"
echo "  # Tenant acme"
echo "  curl -sI -H 'X-Tenant-Slug: acme' http://localhost:8080/ | head -5"
echo "  # Auth via path prefix"
echo "  curl -s http://localhost:8080/auth/health"
echo "  curl -s -H 'X-Tenant-Slug: acme' http://localhost:8080/auth/health"
echo
echo "==> Odin onboard example (API on :4100, after login)"
cat <<'EOF'
  TOKEN=$(curl -s -X POST http://localhost:4100/api/auth/login \
    -H 'Content-Type: application/json' \
    -d '{"username":"odin","password":"odin-admin"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')

  curl -s -X POST http://localhost:4100/api/tenants \
    -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
    -d '{"slug":"initech","name":"Initech","themeColor":"#1D4ED8","adminEmail":"admin@initech.demo","skipDb":true}'

  curl -s -X POST http://localhost:4100/api/tenants/initech/pin \
    -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
    -d '{"web":"YOUR_WEB_TAG_B"}'
EOF

echo
echo "See docs/ODIN.md for full setup (Istio install, Argo apps, retire flow)."
